namespace ReplayLoader {
    void LoadReplayFromPath(const string &in path) {
        if (!_Game::IsPlayingMap()) { NotifyWarn("You are currently not playing a map! Please load a map in a playing state first!"); return; }

        if (!path.Contains("Trackmania") || !path.Contains("Trackmania2020")) {
            log("The replay file is located in the Trackmania folder, moving to the replay folder to load it.", LogLevel::Warn, 12, "LoadReplayFromPath");
            NotifyWarn("The replay file is located in the Trackmania folder, moving to the replay folder to load it.");
            _IO::File::CopyFileTo(path, Server::replayARLAutoMove + Path::GetFileName(path));
            if (!IO::FileExists(Server::replayARLAutoMove + Path::GetFileName(path))) {
                NotifyError("Failed to move replay file to the target directory!");
                log("Failed to move replay file to the target directory!", LogLevel::Error, 15, "LoadReplayFromPath");
                return;
            }
        } else {
            log("Moving the replay file to the temp replay folder to load it.", LogLevel::Warn, 16, "LoadReplayFromPath");
            _IO::File::CopyFileTo(path, Server::replayARLAutoMove + Path::GetFileName(path));
        }

        auto task = GetApp().Network.ClientManiaAppPlayground.DataFileMgr.Replay_Load(Server::replayARLAutoMove + Path::GetFileName(path));        

        IO::Delete(Server::replayARLAutoMove + Path::GetFileName(path));

        while (task.IsProcessing) { yield(); }

        if (task.HasFailed || !task.HasSucceeded) {
            NotifyError("Failed to load replay file!");
            log("Failed to load replay file!", LogLevel::Error, 38, "LoadReplayFromPath");
            log(task.ErrorCode, LogLevel::Error, 39, "LoadReplayFromPath");
            log(task.ErrorDescription, LogLevel::Error, 40, "LoadReplayFromPath");
            log(task.ErrorType, LogLevel::Error, 41, "LoadReplayFromPath");
            log(tostring(task.Ghosts.Length), LogLevel::Error, 42, "LoadReplayFromPath");
            return;
        } else {
            log(task.ErrorCode, LogLevel::Info, 45, "LoadReplayFromPath");
            log(task.ErrorDescription, LogLevel::Info, 46, "LoadReplayFromPath");
            log(task.ErrorType, LogLevel::Info, 47, "LoadReplayFromPath");
            log(tostring(task.Ghosts.Length), LogLevel::Info, 48, "LoadReplayFromPath");
        }


        auto ghostMgr = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript).GhostMgr;
        for (uint i = 0; i < task.Ghosts.Length; i++) {
            ghostMgr.Ghost_Add(task.Ghosts[i]);
        }

        if (task.Ghosts.Length == 0) {
            NotifyWarn("No ghosts found in the replay file!");
            log("No ghosts found in the replay file!", LogLevel::Warn, 59, "LoadReplayFromPath");
            return;
        }
    }
}
