namespace Features {
namespace LRBasedOnCurrentMap {

    namespace ValidationReplay {

        void AddValidationReplay() {
            if (ValidationReplayExists()) {
                ReplayLoader::LoadReplayFromPath(GetValidationReplayFilePathForCurrentMap());
            }
        }

        bool ValidationReplayExists() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return false;
            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return false;
            CGameDataFileManagerScript@ dataFileMgr = playground.DataFileMgr;
            if (dataFileMgr is null) { /*log("DataFileMgr is null", LogLevel::Error, 17, "ValidationReplayExists");*/ return false; }
            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) { /*log("Author ghost is empty", LogLevel::Warn, 19, "ValidationReplayExists");*/ return false; }
            return true;
        }

        void OnMapLoad() {
            if (ValidationReplayExists()) {
                ExtractValidationReplay();
            }
        }

        void ExtractValidationReplay() {
            try {
                CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
                if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 32, "ExtractValidationReplay"); }
                string outputFileName = Server::currentMapRecordsValidationReplay + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
                CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
                if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 35, "ExtractValidationReplay"); }
                CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, GetApp().RootMap, authorGhost);
                if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 37, "ExtractValidationReplay"); }
                while (taskResult.IsProcessing) { yield(); }
                if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 39, "ExtractValidationReplay"); }
                log("Replay extracted to: " + outputFileName, LogLevel::Info, 40, "ExtractValidationReplay");
            } catch {
                log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 42, "ExtractValidationReplay");
            }
        }

        int GetValidationReplayTime() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return -1;
            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return -1;
            CGameDataFileManagerScript@ dataFileMgr = playground.DataFileMgr;
            if (dataFileMgr is null) return -1;
            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) return -1;
            return authorGhost.Result.Time;
        }

        string GetValidationReplayFilePathForCurrentMap() {
            if (GetApp().RootMap is null) { log("RootMap is null, no replay can be loaded...", LogLevel::Info, 59, "GetValidationReplayFilePathForCurrentMap"); return ""; }
            string path = Server::currentMapRecordsValidationReplay + "Validation_" + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
            if (!IO::FileExists(path)) { log("Validation replay does not exist at path: " + path + " | This is likely due to the validation replay not yet being extracted.", LogLevel::Info, 61, "GetValidationReplayFilePathForCurrentMap"); return ""; }
            return path;
        }
    }

}
}