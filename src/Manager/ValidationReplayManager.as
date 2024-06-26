namespace ValidationReplay {
    string GetValidationReplayFilePath() {
        return Server::validationFilesDirectory + StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
    }

    bool ValidationReplayExists() {
        CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
        if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 8, "ValidationReplayExists"); return false; }
        CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
        if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 10, "ValidationReplayExists"); return false; }
        return true;
    }

    void ExtractReplay() {
        try {
            CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
            string outputFileName = Server::validationFilesDirectory + StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 19, "ExtractReplay"); }

            CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, GetApp().RootMap, authorGhost);
            if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 22, "ExtractReplay"); }

            while (taskResult.IsProcessing) { yield(); }
            if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 25, "ExtractReplay"); }

            log("Replay extracted to: " + outputFileName, LogLevel::Info, 27, "ExtractReplay");
        } catch {
            log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 29, "ExtractReplay");
        }
    }

    void AddValidationReplay() {
        if (!ValidationReplayExists()) {
            ExtractReplay();
        }
        ReplayLoader::LoadReplay(GetValidationReplayFilePath());
    }
}