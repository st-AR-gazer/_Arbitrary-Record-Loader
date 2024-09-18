namespace GhostLoader {
    [Setting hidden]
    bool S_UseGhostLayer = true;

    void LoadGhost(const string &in filePath, const string &in _destonationPath = Server::serverDirectoryAutoMove) {
        if (filePath.ToLower().EndsWith(".gbx")) {
            string fileName = Path::GetFileName(filePath);
            string destinationPath = _destonationPath + fileName;
            log("Moving file from " + filePath + " to " + destinationPath, LogLevel::Info, 9, "LoadGhost");
            _IO::File::CopyFileTo(filePath, destinationPath);
            LoadGhostFromUrl(Server::HTTP_BASE_URL + "get_ghost/" + Net::UrlEncode(fileName));
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
        if (ps is null) { log("PlaygroundScript is null, you might not be in a playground", LogLevel::Error, 24, "LoadGhostFromUrlAsync"); return; }




        Net::HttpRequest req;
        req.Method = Net::HttpMethod::Get;
        req.Url = "http://127.0.0.1:29918/get_ghost/file.ghost.gbx";
        req.Start();

        while (!req.Finished()) {
            yield();
        }
        print(req.ResponseCode());

        print(req.String());
        
        return;

        print(url);


        CGameDataFileManagerScript@ dfm = ps.DataFileMgr;
        CWebServicesTaskResult_GhostScript@ task = dfm.Ghost_Download("", "http://127.0.0.1:29918/get_ghost/file.ghost.gbx");

        while (task.IsProcessing) {
            yield();
        }

        if (task.HasFailed || !task.HasSucceeded) {
            log('Ghost_Download failed: ' + task.ErrorCode + ", " + task.ErrorType + ", " + task.ErrorDescription + " Url used: " + url, LogLevel::Error, 54, "LoadGhostFromUrlAsync");
            return;
        }

        CGameGhostMgrScript@ gm = ps.GhostMgr;
        MwId instId = gm.Ghost_Add(task.Ghost, S_UseGhostLayer);
        log('Instance ID: ' + instId.GetName() + " / " + Text::Format("%08x", instId.Value), LogLevel::Info, 60, "LoadGhostFromUrlAsync");

        dfm.TaskResult_Release(task.Id);
    }
}
