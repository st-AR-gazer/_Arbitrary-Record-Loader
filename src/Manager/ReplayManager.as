namespace ReplayLoader {
    void LoadReplayAfterFileExplorer() {
        if (_Game::IsMapLoaded() && _IO::FileExplorer::Exports::GetExportPath() != "") {
            string selectedFilePath = _IO::FileExplorer::Exports::GetExportPath();
            string selectedFileExt = _IO::FileExplorer::Exports::GetExportPathFileExt();

            if (selectedFileExt.ToLower() == "replay") {
                startnew(LoadReplayFromPath, selectedFilePath);
                _IO::FileExplorer::Exports::ClearExportPath();
            }
        }
    }

    void LoadReplayFromPath(const string &in path) {
        if (!_Game::IsPlayingMap()) { NotifyWarn("You are currently not playing a map! Please load a map in a playing state first!"); return; }

        if (!path.Contains("Trackmania") && !path.Contains("Trackmania2020")) {
            log("The replay file is not located in the Trackmania folder! Please move the replay file to the Trackmania folder and try again!", LogLevel::Warn, 18, "LoadReplayFromPath");
            NotifyWarn("The replay file is not located in the Trackmania folder! Please move the replay file to the Trackmania folder and try again!");

            _IO::File::CopyMoveFile(path, Server::replayARLAutoMove + _IO::File::GetFileName(path));
            if (!IO::FileExists(Server::replayARLAutoMove + _IO::File::GetFileName(path))) {
                NotifyError("Failed to move replay file to the target directory!");
                log("Failed to move replay file to the target directory!", LogLevel::Error, 24, "LoadReplayFromPath");
                return;
            }
        }

        auto task = GetApp().Network.ClientManiaAppPlayground.DataFileMgr.Replay_Load(path);
        
        while (task.IsProcessing) { yield(); }

        if (task.HasFailed || !task.HasSucceeded) {
            NotifyError("Failed to load replay file!");
            log("Failed to load replay file!", LogLevel::Error, 35, "LoadReplayFromPath");
            log(task.ErrorCode, LogLevel::Error, 36, "LoadReplayFromPath");
            log(task.ErrorDescription, LogLevel::Error, 37, "LoadReplayFromPath");
            log(task.ErrorType, LogLevel::Error, 38, "LoadReplayFromPath");
            log(tostring(task.Ghosts.Length), LogLevel::Error, 39, "LoadReplayFromPath");
            return;
        } else {
            log(task.ErrorCode, LogLevel::Info, 42, "LoadReplayFromPath");
            log(task.ErrorDescription, LogLevel::Info, 43, "LoadReplayFromPath");
            log(task.ErrorType, LogLevel::Info, 44, "LoadReplayFromPath");
            log(tostring(task.Ghosts.Length), LogLevel::Info, 45, "LoadReplayFromPath");
        }


        auto ghostMgr = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript).GhostMgr;
        for (uint i = 0; i < task.Ghosts.Length; i++) {
            ghostMgr.Ghost_Add(task.Ghosts[i]);
        }

        if (task.Ghosts.Length == 0) {
            NotifyWarn("No ghosts found in the replay file!");
            log("No ghosts found in the replay file!", LogLevel::Warn, 56, "LoadReplayFromPath");
            return;
        }
        log("Replay loaded successfully with " + task.Ghosts.Length + " ghosts!", LogLevel::Info, 59, "LoadReplayFromPath");
    }
}
