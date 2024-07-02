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
        bool gpsReplayCanBeLoaded = false;
        array<string> recordNames;
        array<CMwNod@> ghostAddresses;
        int selectedGhostIndex = 0;

        bool GPSReplayCanBeLoadedForCurrentMap() {
            if (GPSReplayExists()) { ExtractGPSReplay(); }
            return true;
        }

        string GetGPSReplayFilePath() {
            return Server::currentMapRecordsValidationReplay + "GPS_" + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
        }

        bool GPSReplayExists() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return false;

            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return false;

            CGameCtnChallenge@ map = GetApp().RootMap;
            if (map is null) return false;

            CGameCtnMediaClipGroup@ clipGroupInGame = map.ClipGroupInGame;
            if (clipGroupInGame is null) return false;

            return true;
        }

        void ExtractGPSReplay() {
            try {
                CTrackMania@ app = cast<CTrackMania>(GetApp());
                if (app is null) return;

                CGameCtnChallenge@ map = GetApp().RootMap;
                if (map is null) return;

                CGameCtnMediaClipGroup@ clipGroupInGame = map.ClipGroupInGame;
                if (clipGroupInGame is null) return;

                string outputFileName = Server::currentMapRecordsValidationReplay + Text::StripFormatCodes(GetApp().RootMap.MapName) + "_GPS.Replay.Gbx";
                array<CGameCtnGhost@> gpsGhosts = GetGPSGhosts();
                if (gpsGhosts.Length == 0) { log("No GPS ghosts found", LogLevel::Warn, 15, "ExtractGPSReplay"); return; }

                CGameDataFileManagerScript@ dataFileMgr = cast<CGameDataFileManagerScript>(app.PlaygroundScript.DataFileMgr);
                if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 20, "ExtractGPSReplay"); return; }

                for (uint i = 0; i < gpsGhosts.Length; i++) {
                    CGameCtnGhost@ ghost = gpsGhosts[i];

                    CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, map, ghost);
                    if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 25, "ExtractGPSReplay"); return; }

                    while (taskResult.IsProcessing) { yield(); }
                    if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 28, "ExtractGPSReplay"); return; }

                    log("GPS ghost extracted to: " + outputFileName, LogLevel::Info, 30, "ExtractGPSReplay");
                }
            } catch {
                log("Error occurred when trying to extract GPS ghosts: " + getExceptionInfo(), LogLevel::Info, 33, "ExtractGPSReplay");
            }
        }

        array<CGameCtnGhost@> GetGPSGhosts() {
            array<CGameCtnGhost@> ghosts;
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return ghosts;

            CGameCtnChallenge@ map = GetApp().RootMap;
            if (map is null) return ghosts;

            CGameCtnMediaClipGroup@ clipGroupInGame = map.ClipGroupInGame;
            if (clipGroupInGame is null) return ghosts;

            for (uint i = 0; i < clipGroupInGame.Clips.Length; i++) {
                CGameCtnMediaClip@ clip = clipGroupInGame.Clips[i];
                if (clip is null) continue;

                for (uint j = 0; j < clip.Tracks.Length; j++) {
                    CGameCtnMediaTrack@ track = clip.Tracks[j];
                    if (track is null) continue;

                    for (uint k = 0; k < track.Blocks.Length; k++) {
                        CGameCtnMediaBlockEntity@ block = cast<CGameCtnMediaBlockEntity>(track.Blocks[k]);
                        if (block is null) continue;

                        // Access CPlugEntRecordData at +0x58
                        CPlugEntRecordData@ recordData = cast<CPlugEntRecordData>(Dev::GetOffsetNod(block, 0x58));
                        if (recordData is null) continue;

                        CGameCtnGhost@ ghost = CreateGhostFromRecordData(recordData);
                        if (ghost is null) continue;

                        ghosts.InsertLast(ghost);
                    }
                }
            }

            return ghosts;
        }

        CGameCtnGhost@ CreateGhostFromRecordData(CPlugEntRecordData@ recordData) {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return null;

            CGameCtnPlayground@ playground = cast<CGameCtnPlayground>(app.CurrentPlayground);
            if (playground is null) return null;

            CGameCtnGhost@ ghost = playground.PlayerRecordedGhost;
            if (ghost is null) return null;

            Dev::SetOffset(ghost, 0x2E0, recordData);
            recordData.MwAddRef();

            return ghost;
        }
    }
}
