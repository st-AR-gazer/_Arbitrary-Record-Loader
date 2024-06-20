namespace GhostLoader {
    [Setting hidden]
    bool S_UseGhostLayer = true;

    void OpenGhostFileDialogWindow() {
        _IO::FileExplorer::OpenFileExplorer(true, IO::FromUserGameFolder("Replays/"));
    }

    void LoadGhost(const string &in filePath) {
        if (filePath.ToLower().EndsWith(".gbx")) {
            string fileName = GetFileName(filePath);
            string destinationPath = Server::serverDirectory + fileName;
            log("Moving file from " + filePath + " to " + destinationPath, LogLevel::Info, 13, "LoadGhost");
            _IO::SafeMoveFileToNonSource(filePath, destinationPath);
            Server::LogServerFiles();
            LoadGhostFromUrl(Server::serverUrl + fileName);
        } else {
            NotifyError("Unsupported file type.");
        }
    }

    string GetFileName(const string &in filePath) {
        array<string> parts = filePath.Split("/");
        return parts[parts.Length - 1];
    }

    void LoadGhostFromUrl(const string &in url) {
        startnew(LoadGhostFromUrlAsync, url);
    }

    void LoadGhostFromUrlAsync(const string &in url) {
        auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
        auto dfm = ps.DataFileMgr;
        auto gm = ps.GhostMgr;
        auto task = dfm.Ghost_Download(GetFileName(url), url);

        WaitAndClearTaskLater(task, dfm);
        if (task.HasFailed || !task.HasSucceeded) {
            log('Ghost_Download failed: ' + task.ErrorCode + ", " + task.ErrorType + ", " + task.ErrorDescription + " Url used: " + url, LogLevel::Error, 87, "LoadGhostFromUrlAsync");
            return;
        }

        auto instId = gm.Ghost_Add(task.Ghost, S_UseGhostLayer);
    }

    void WaitAndClearTaskLater(CWebServicesTaskResult@ task, CMwNod@ owner) {
        while (task.IsProcessing) yield();
        tasksToClear.InsertLast(ClearTask(task, owner));
    }
}
