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
            if (dataFileMgr is null) { /*log("DataFileMgr is null", LogLevel::Error, 21, "ValidationReplayExists");*/ return false; }

            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) { /*log("Author ghost is empty", LogLevel::Warn, 24, "ValidationReplayExists");*/ return false; }

            return true;
        }

        void ExtractReplay() {
            try {
                CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
                if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 32, "ExtractReplay"); }
                string outputFileName = Server::currentMapRecordsValidationReplay + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";

                CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
                if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 36, "ExtractReplay"); }

                CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, GetApp().RootMap, authorGhost);
                if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 39, "ExtractReplay"); }

                while (taskResult.IsProcessing) { yield(); }
                if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 42, "ExtractReplay"); }

                log("Replay extracted to: " + outputFileName, LogLevel::Info, 44, "ExtractReplay");
            } catch {
                log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 46, "ExtractReplay");
            }
        }

        void AddValidationReplay() {
            if (validationReplayCanBeLoaded) { ExtractReplay(); }
            ReplayLoader::LoadReplayFromPath(GetValidationReplayFilePath());
        }
    }

    namespace GPS {
        bool gpsCanBeLoaded = false;

        bool GPSReplayCanLoadForCurrentMap() {
            if (GPSReplayExists()) { ExtractGPS(); }
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

            auto gps = map.ClipGroupInGame.Clips[0].Tracks[0].Blocks[0];


            return true;
        }

        void ExtractGPS() {
            try {
                

                log("Replay extracted to: " + outputFileName, LogLevel::Info, 44, "ExtractGPS");
            } catch {
                log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 46, "ExtractGPS");
            }
        }
    }
}