namespace ValidationReplay {
    string GetValidationReplayFilePath() {
        return Server::validationDirectory + StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
    }

    bool ValidationReplayExists() {
        CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
        if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 3, "ValidationReplayExists"); return false; }
        CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
        if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 9, "ExtractReplay"); return false; }
        return true;
    }

    void ExtractReplay() {
        try {
            CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
            string outputFileName = Server::validationDirectory + StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 9, "ExtractReplay"); }

            CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, GetApp().RootMap, authorGhost);
            if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 15, "ExtractReplay"); }

            while (taskResult.IsProcessing) { yield(); }
            if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 21, "ExtractReplay"); }

            log("Replay extracted to: " + outputFileName);
        } catch {
            log("Error occurred when trying to extract replay: " + getExceptionInfo());
        }
    }

    void AddValidationReplay() {
        if (!ValidationReplayExists()) {
            ExtractReplay();
        }
        ReplayLoader::LoadReplay(GetValidationReplayFilePath());
    }
}