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
            log("Moving file from " + filePath + " to " + destinationPath, LogLevel::Info, __LINE__, __FUNCTION__);
            _IO::SafeMoveFileToNonSource(filePath, destinationPath);
            LoadGhostFromUrl(Server::HTTP_BASE_URL + "get_ghost/" + fileName);
        } else {
            NotifyError("Unsupported file type.");
        }
    }

    string GetFileName(const string &in filePath) {
        array<string> parts = filePath.Split("/");
        return parts[parts.Length - 1];
    }

    void LoadGhostFromUrl(const string &in url) {
        log("Loading ghost from URL: " + url, LogLevel::Info, __LINE__, __FUNCTION__);
        startnew(LoadGhostFromUrlAsync, url);
    }

    void LoadGhostFromUrlAsync(const string &in url) {
        auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
        auto dfm = ps.DataFileMgr;
        auto gm = ps.GhostMgr;
        auto task = dfm.Ghost_Download(GetFileName(url), url);

        while (task.IsProcessing) {
            yield();
        }

        if (task.HasFailed || !task.HasSucceeded) {
            log('Ghost_Download failed: ' + task.ErrorCode + ", " + task.ErrorType + ", " + task.ErrorDescription + " Url used: " + url, LogLevel::Error, __LINE__, __FUNCTION__);
            return;
        }

        auto instId = gm.Ghost_Add(task.Ghost, S_UseGhostLayer);
        log('Instance ID: ' + instId.GetName() + " / " + Text::Format("%08x", instId.Value), LogLevel::Info, __LINE__, __FUNCTION__);

        dfm.TaskResult_Release(task.Id);
    }

    void NotifyError(const string &in message) {
        UI::ShowNotification("Error", message, vec4(1, 0, 0, 1), 5000);
    }
}
