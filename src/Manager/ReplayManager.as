namespace ReplayLoader {
    void CheckReplayLoad() {
        if (_Game::IsMapLoaded() && _IO::FileExplorer::Exports::GetExportPath() != "") {
            string selectedFilePath = _IO::FileExplorer::Exports::GetExportPath();
            string selectedFileExt = _IO::FileExplorer::Exports::GetExportPathFileExt();

            if (selectedFileExt.ToLower() == "replay") {
                startnew(LoadReplay, selectedFilePath);  // Start a new coroutine to handle loading
                _IO::FileExplorer::Exports::ClearExportPath();
            }
        }
    }

    void LoadReplay(const string &in path) {
        if (!_Game::IsPlayingMap()) { NotifyWarn("You are currently not playing a map! Please load a map in a playing state first!"); return; }

        auto task = GetApp().Network.ClientManiaAppPlayground.DataFileMgr.Replay_Load(path);
        
        // Wait for the task to complete
        while (task.IsProcessing) {
            yield();
        }

        log(task.ErrorCode, LogLevel::Info, 27, "LoadReplay");
        log(task.ErrorDescription, LogLevel::Info, 28, "LoadReplay");
        log(task.ErrorType, LogLevel::Info, 29, "LoadReplay");
        log(tostring(task.Ghosts.Length), LogLevel::Info, 30, "LoadReplay");

        auto ghostMgr = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript).GhostMgr;
        for (uint i = 0; i < task.Ghosts.Length; i++) {
            ghostMgr.Ghost_Add(task.Ghosts[i]);
        }

        log("Replay loaded successfully with " + task.Ghosts.Length + " ghosts!", LogLevel::Info, 37, "LoadReplay");
    }
}
