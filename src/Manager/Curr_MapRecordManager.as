namespace CurrentMapRecords {
    namespace ValidationReplay {
        bool validationReplayCanBeLoaded = false;

        bool ValidationReplayCanBeLoadedForCurrentMap() {
            if (ValidationReplayExists()) { ExtractReplay(); }
            return true;
        }
        
        string GetValidationReplayFilePath() {
            return Server::currentMapRecordsValidationReplay + "Validation_" + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
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
        class GhostData {
            string name;
            string savePath;
            CGameCtnGhost@ ghost;
            CGameGhostScript@ ghostScript;

            GhostData(const string &in name, const string &in savePath, CGameCtnGhost@ ghost) {
                this.name = name;
                this.savePath = savePath;
                @this.ghost = ghost;
            }

            void ConvertToScript(uint64 CTmRaceResult_VTable_Ptr) {
                ghost.MwAddRef();
                @ghostScript = CGameGhostScript();
                MwId ghostId = MwId();
                Dev::SetOffset(ghostScript, 0x18, ghostId.Value);
                Dev::SetOffset(ghostScript, 0x20, ghost);
                uint64 ghostPtr = Dev::GetOffsetUint64(ghostScript, 0x20);

                auto @tmRaceResultNodPre = CGameGhostScript();
                Dev::SetOffset(tmRaceResultNodPre, 0x0, CTmRaceResult_VTable_Ptr);
                trace('force casting');
                auto tmRaceResultNod = Dev::ForceCast<CTmRaceResultNod@>(tmRaceResultNodPre).Get();
                trace('done force casting');
                @tmRaceResultNodPre = null;
                Dev::SetOffset(tmRaceResultNod, 0x18, ghostPtr + 0x28);
                tmRaceResultNod.MwAddRef();

                Dev::SetOffset(ghostScript, 0x28, tmRaceResultNod);
            }

            void Save(CGameCtnChallenge@ rootMap) {
                if (ghostScript !is null) {
                    CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
                    CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(savePath, rootMap, ghostScript);
                    if (taskResult is null) {
                        log("Replay task returned null for ghost " + name, LogLevel::Error, 40, "SaveReplays");
                    }
                }
            }
        }

        string savePathBase = "";
        CGameCtnChallenge@ rootMap = null;
        array<GhostData@> ghosts;
        string finalSavePath = "";
        uint64 CTmRaceResult_VTable_Ptr = 0;
        int selectedGhostIndex = -1;

        bool gpsReplayCanBeLoaded = false;

        void OnMapLoad() {
            FetchMap();
            
            gpsReplayCanBeLoaded = GPSReplayCanBeLoadedForCurrentMap();
            if (!gpsReplayCanBeLoaded) { return; }

            FetchPath();
            FetchGhosts();
            GetCTmRaceResultVTablePtr();
            ConvertGhosts();
            SaveReplays();
        }

        bool GPSReplayCanBeLoadedForCurrentMap() {
            for (uint i = 0; i < rootMap.ClipGroupInGame.Clips.Length; i++) {
                auto clip = rootMap.ClipGroupInGame.Clips[i];
                for (uint j = 0; j < clip.Tracks.Length; j++) {
                    auto track = clip.Tracks[j];
                    if (track.Name.StartsWith("ghost")) {
                        return true;
                    }
                }
            }
            return false;
        }

        void FetchPath() {
            savePathBase = Server::currentMapRecordsGPS + Text::StripFormatCodes(GetApp().RootMap.MapName) + "_" + GetApp().RootMap.MapInfo.MapUid + "/";
        }

        void FetchMap() {
            @rootMap = GetApp().RootMap;
        }

        void FetchGhosts() {
            for (uint i = 0; i < rootMap.ClipGroupInGame.Clips.Length; i++) {
                auto clip = rootMap.ClipGroupInGame.Clips[i];
                for (uint j = 0; j < clip.Tracks.Length; j++) {
                    auto track = clip.Tracks[j];
                    if (track.Name.StartsWith("ghost: ")) {
                        for (uint k = 0; k < track.Blocks.Length; k++) {
                            auto block = cast<CGameCtnMediaBlockEntity>(track.Blocks[k]);
                            if (block !is null) {
                                auto recordData = cast<CPlugEntRecordData>(Dev::GetOffsetNod(block, 0x58));
                                if (recordData !is null) {
                                    auto newGhost = CGameCtnGhost();
                                    Dev::SetOffset(newGhost, 0x2e0, recordData);
                                    recordData.MwAddRef();
                                    string ghostName = track.Name.SubStr(7);  // Remove "ghost: " prefix
                                    string savePath = savePathBase + ghostName + "_" + Text::Format("%d", i) + ".Replay.Gbx";
                                    ghosts.InsertLast(GhostData(ghostName, savePath, newGhost));
                                }
                            }
                        }
                    }
                }
            }
        }

        void GetCTmRaceResultVTablePtr() {
            auto dummyGhostScript = CGameGhostScript();
            auto dummyResult = dummyGhostScript.Result;
            CTmRaceResult_VTable_Ptr = Dev::GetOffsetUint64(dummyResult, 0x0);
        }

        void ConvertGhosts() {
            for (uint i = 0; i < ghosts.Length; i++) {
                ghosts[i].ConvertToScript(CTmRaceResult_VTable_Ptr);
            }
        }

        void SaveReplays() {
            for (uint i = 0; i < ghosts.Length; i++) {
                ghosts[i].Save(rootMap);
            }
        }

        void LoadReplay() {
            if (selectedGhostIndex >= 0 && selectedGhostIndex < ghosts.Length) {
                ReplayLoader::LoadReplayFromPath(ghosts[selectedGhostIndex].savePath);
            }
        }
    }
}
