namespace GhostLoader {
    [Setting hidden]
    bool S_UseGhostLayer = true;

    void LoadGhostFromLocalFile(const string &in filePath, const string &in _destonationPath = Server::serverDirectoryAutoMove) {
        if (filePath.ToLower().EndsWith(".gbx")) {
            string fileName = Path::GetFileName(filePath);
            string destinationPath = _destonationPath + fileName;
            log("Moving file from " + filePath + " to " + destinationPath, LogLevel::Info, 9, "LoadGhost");
            _IO::File::CopyFileTo(filePath, destinationPath);
            LoadGhostFromUrl(Server::HTTP_BASE_URL + "get_ghost/" + fileName);
        } else {
            NotifyError("Unsupported file type.");
        }
    }

    void LoadGhostFromUrl(const string &in url) {
        log("Loading ghost from URL: " + url, LogLevel::Info, 18, "LoadGhostFromUrl");
        startnew(LoadGhostFromUrlAsync, url);
    }

    void LoadGhostFromUrlAsync(const string &in url) {
        auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
        CGameDataFileManagerScript@ dfm = ps.DataFileMgr;
        CWebServicesTaskResult_GhostScript@ task = dfm.Ghost_Download("", url);

        while (task.IsProcessing) { yield(); }

        if (task.HasFailed || !task.HasSucceeded) {
            log('Ghost_Download failed: ' + task.ErrorCode + ", " + task.ErrorType + ", " + task.ErrorDescription + " Url used: " + url, LogLevel::Error, 62, "LoadGhostFromUrlAsync");
            return;
        }

        CGameGhostMgrScript@ gm = ps.GhostMgr;
        MwId instId = gm.Ghost_Add(task.Ghost, S_UseGhostLayer);
        log('Instance ID: ' + instId.GetName() + " / " + Text::Format("%08x", instId.Value), LogLevel::Info, 68, "LoadGhostFromUrlAsync");

        dfm.TaskResult_Release(task.Id);
    }
}
