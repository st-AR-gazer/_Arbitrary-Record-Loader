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

    void LoadReplayFromPath(const string &in path, bool verbose = true) {
        if (!_Game::IsPlayingMap()) { if (verbose) NotifyWarn("You are currently not playing a map! Please load a map in a playing state first!"); return; }

        auto task = GetApp().Network.ClientManiaAppPlayground.DataFileMgr.Replay_Load(path);
        
        while (task.IsProcessing) { yield(); }

        if (verbose) log(task.ErrorCode, LogLevel::Info, 21, "LoadReplayFromPath");
        if (verbose) log(task.ErrorDescription, LogLevel::Info, 22, "LoadReplayFromPath");
        if (verbose) log(task.ErrorType, LogLevel::Info, 23, "LoadReplayFromPath");
        if (verbose) log(tostring(task.Ghosts.Length), LogLevel::Info, 24, "LoadReplayFromPath");

        auto ghostMgr = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript).GhostMgr;
        for (uint i = 0; i < task.Ghosts.Length; i++) {
            ghostMgr.Ghost_Add(task.Ghosts[i]);
        }

        if (verbose) log("Replay loaded successfully with " + task.Ghosts.Length + " ghosts!", LogLevel::Info, 31, "LoadReplayFromPath");
    }
}
