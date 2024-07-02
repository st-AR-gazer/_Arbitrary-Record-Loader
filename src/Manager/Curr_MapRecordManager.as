namespace CurrentMapRecords {
    namespace ValidationReplay {
        bool validationReplayCanBeLoaded = false;

        bool ValidationReplayCanBeLoadedForCurrentMap() {
            if (ValidationReplayExists()) { ExtractReplay(); }
            return true;
        }
        
        string GetValidationReplayFilePath() {
            return Server::currentMapRecordsValidationReplay + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
        }

        bool ValidationReplayExists() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return false;

            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return false;

            CGameDataFileManagerScript@ dataFileMgr = playground.DataFileMgr;
            if (dataFileMgr is null) { /*log("DataFileMgr is null", LogLevel::Error, 22, "ValidationReplayExists");*/ return false; }

            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) { /*log("Author ghost is empty", LogLevel::Warn, 25, "ValidationReplayExists");*/ return false; }

            return true;
        }

        void ExtractReplay() {
            try {
                CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
                if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 33, "ExtractReplay"); }
                string outputFileName = Server::currentMapRecordsValidationReplay + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";

                CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
                if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 37, "ExtractReplay"); }

                CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, GetApp().RootMap, authorGhost);
                if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 40, "ExtractReplay"); }

                while (taskResult.IsProcessing) { yield(); }
                if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 43, "ExtractReplay"); }

                log("Replay extracted to: " + outputFileName, LogLevel::Info, 45, "ExtractReplay");
            } catch {
                log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 47, "ExtractReplay");
            }
        }

        void AddValidationReplay() {
            if (validationReplayCanBeLoaded) { ExtractReplay(); }
            ReplayLoader::LoadReplayFromPath(GetValidationReplayFilePath());
        }
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    namespace GPS {
        bool gpsCanBeLoaded = false;
        int selectedGhostIndex = 0;

        enum RecordType {
            None,
            Ghost
        }

        array<string> recordNames;
        array<RecordType> recordTypes;
        array<uint64> ghostAddresses;

        bool GPSReplayCanLoadForCurrentMap() {
            if (GPSReplayExists()) {
                ExtractGPS();
            }
            return true;
        }

        string GetGPSReplayFilePath() {
            return Server::currentMapRecordsGPS + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
        }

        bool GPSReplayExists() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return false;

            auto map = cast<CGameCtnChallenge>(app.RootMap);
            if (map is null) return false;

            auto InGame = cast<CGameCtnMediaClipGroup>(map.ClipGroupInGame);
            if (InGame is null) return false;

            for (uint i = 0; i < InGame.Clips.Length; i++) {
                auto clip = cast<CGameCtnMediaTrack>(InGame.Clips[i]);
                if (clip is null) continue;

                RecordType recordType = IdentifyRecordType(clip);
                if (recordType == RecordType::Ghost) {
                    recordNames.InsertLast(clip.Name);
                    recordTypes.InsertLast(recordType);
                    ghostAddresses.InsertLast(Dev::GetOffsetUint64(clip, 0x58));
                }

                auto typeInfo = Reflection::TypeOf(clip);
                if (typeInfo !is null) {
                    ExploreProperties(typeInfo);
                }
            }

            return ghostAddresses.Length > 0;
        }

        RecordType IdentifyRecordType(CGameCtnMediaTrack@ track) {
            if (track.Name.Contains("Ghost")) {
                return RecordType::Ghost;
            }
            return RecordType::None;
        }

        void ExploreProperties(const Reflection::MwClassInfo@ classInfo, int depth = 0) {
            if (depth > 3) return;

            for (uint i = 0; i < classInfo.Members.Length; i++) {
                auto member = classInfo.Members[i];
                print("Member: " + member.Name + ", Offset: " + member.Offset);
            }
        }

        uint GetClassSize(const string &in className) {
            auto classInfo = Reflection::GetType(className);
            if (classInfo is null) return 0;

            uint maxOffset = 0;
            for (uint i = 0; i < classInfo.Members.Length; i++) {
                auto member = classInfo.Members[i];
                uint memberSize = GetMemberSize(member.Name);
                uint memberEnd = member.Offset + memberSize;
                if (memberEnd > maxOffset) {
                    maxOffset = memberEnd;
                }
            }

            return maxOffset + 16;
        }

        uint GetMemberSize(const string &in memberName) {
            if (memberName.Contains("string") || memberName.Contains("wstring")) {
                return 8;
            }
            return 4;
        }

        void ExtractGPS() {
            try {
                string outputFileName = GetGPSReplayFilePath();

                CTrackMania@ app = cast<CTrackMania>(GetApp());
                auto map = cast<CGameCtnChallenge>(app.RootMap);
                auto InGame = cast<CGameCtnMediaClipGroup>(map.ClipGroupInGame);

                for (uint i = 0; i < ghostAddresses.Length; i++) {
                    uint64 clipAddress = ghostAddresses[i];
                    auto blockEntity = cast<CGameCtnMediaBlockEntity>(Dev::GetOffsetNod(clipAddress, 0x2E0));
                    if (blockEntity is null) continue;

                    // Access CPlugEntRecordData pointer at +0x2E0
                    uint64 recordDataPtr = Dev::GetOffsetUint64(blockEntity, 0x2E0);

                    // Determine the size of the CGameCtnGhost class
                    uint ghostSize = GetClassSize("CGameCtnGhost");
                    if (ghostSize == 0) {
                        log("Failed to determine the size of CGameCtnGhost", LogLevel::Error, 89, "ExtractGPS");
                        return;
                    }

                    uint64 ghostAddress = Dev::Allocate(ghostSize);

                    Dev::SetOffset(ghostAddress, 0x2E0, recordDataPtr);

                    // Preload the nod
                    CMwNod@ ghostNod = Fids::Preload(Fids::GetFake(outputFileName));
                    if (ghostNod is null) {
                        log("Failed to preload ghost nod", LogLevel::Error, 87, "ExtractGPS");
                        return;
                    }

                    auto ghost = cast<CGameCtnGhost>(ghostNod);
                    if (ghost is null) {
                        log("Failed to cast to CGameCtnGhost", LogLevel::Error, 88, "ExtractGPS");
                        return;
                    }

                    SaveGhostToFile(ghostNod, outputFileName);

                    log("Replay extracted to: " + outputFileName, LogLevel::Info, 86, "ExtractGPS");
                }
            } catch {
                log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 88, "ExtractGPS");
            }
        }

        void SaveGhostToFile(CMwNod@ ghostNod, const string &in outputFileName) {
            CSystemFidFile@ file = Fids::GetUser(outputFileName);
            if (file is null) {
                log("Failed to get file handle: " + outputFileName, LogLevel::Error, 87, "SaveGhostToFile");
                return;
            }

            if (!Fids::Extract(file)) {
                log("Failed to extract ghost data to: " + outputFileName, LogLevel::Error, 88, "SaveGhostToFile");
            } else {
                log("Ghost data saved to: " + outputFileName, LogLevel::Info, 89, "SaveGhostToFile");
            }
        }
    }
}

