namespace GhostLoader {
    [Setting hidden]
    bool S_UseGhostLayer = true;

    void LoadGhost(const string &in filePath, const string &in _destonationPath = Server::serverDirectoryAutoMove) {
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

        // string url = "http://127.0.0.1:29907/get_ghost/7fc3d8601cbea5eda5bd56da29db7cb1";
        // string url = "https://trackmania.io/api/download/ghost/78b3aabf-0a2b-4b9f-b98d-9d748f0b2b5a";




        // Net::HttpRequest req;
        // req.Method = Net::HttpMethod::Get;
        // req.Url = url;
        // req.Start();

        // while (!req.Finished()) {
        //     yield();
        // }
        // print(req.ResponseCode());

        // print(req.String());
        
        // return;

        // print(url);


        auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
        CGameDataFileManagerScript@ dfm = ps.DataFileMgr;
        CWebServicesTaskResult_GhostScript@ task = dfm.Ghost_Download("", url);
        // CWebServicesTaskResult_GhostScript@ task = dfm.Ghost_Download("file.ghost.gbx", "http://127.0.0.1:29907/get_ghost/b78c5da5fe566324e9e60729380b9b8a.ghost.gbx");

        while (task.IsProcessing) {
            yield();
        }

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
