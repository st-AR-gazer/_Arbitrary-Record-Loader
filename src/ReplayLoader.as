namespace ReplayLoader {
    void CheckReplayLoad() {
        if (_Game::IsMapLoaded() && _IO::FileExplorer::Exports::GetExportPath() != "") {
            string selectedFilePath = _IO::FileExplorer::Exports::GetExportPath();
            string selectedFileExt = _IO::FileExplorer::Exports::GetExportPathFileExt();

            if (selectedFileExt.ToLower() == "replay") {
                LoadReplay(selectedFilePath);
                _IO::FileExplorer::Exports::ClearExportPath();
            }
        }
    }

    void LoadReplay(const string &in path) {
        auto task = GetApp().Network.ClientManiaAppPlayground.DataFileMgr.Replay_Load(path);
        while (!task.IsProcessing) {
            yield();
        }

        log(task.ErrorCode);
        log(task.ErrorDescription);
        log(task.ErrorType);
        log(tostring(task.Ghosts.Length));

        auto ghostMgr = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript).GhostMgr;
        for (uint i = 0; i < task.Ghosts.Length; i++) {
            ghostMgr.Ghost_Add(task.Ghosts[i]);
        }

        log("Replay loaded successfully with " + task.Ghosts.Length + " ghosts!");
    }
}
