LoadRecord@ loadRecord;

class LoadRecord {
    void LoadRecordFromLocalFile(const string &in filePath) {
        startnew(CoroutineFuncUserdataString(Coro_LoadRecordFromFile), filePath);
    }
    void LoadRecordFromLocalFile(string[] filePaths) {
        for (uint i = 0; i < filePaths.Length; i++) {
            LoadRecordFromLocalFile(filePaths[i]);
        }
    }

    void Coro_LoadRecordFromFile(const string &in filePath) {
        if (!IO::FileExists(filePath)) {
            NotifyError("File does not exist.");
            return;
        }

        string fileExt = Path::GetExtension(filePath).ToLower();

        if (fileExt == ".gbx") {
            string properFileExtension = Path::GetExtension(filePath).ToLower();
            if (properFileExtension == ".gbx") {
                int secondLastDotIndex = _Text::NthLastIndexOf(filePath, ".", 2);
                int lastDotIndex = filePath.LastIndexOf(".");
                if (secondLastDotIndex != -1 && lastDotIndex > secondLastDotIndex) {
                    properFileExtension = filePath.SubStr(secondLastDotIndex + 1, lastDotIndex - secondLastDotIndex - 1);
                }
            }
            fileExt = properFileExtension.ToLower();
        }

        AllowCheck::InitializeAllowCheckWithTimeout(500);
        if (AllowCheck::ConditionCheckMet()) {

            // 

            if (fileExt == "replay") {
                ReplayLoader::LoadReplayFromPath(filePath);
            } else if (fileExt == "ghost") {
                GhostLoader::LoadGhostFromLocalFile(filePath);
            } else {
                log("Unsupported file type: " + fileExt + " " + "Full path: " + filePath, LogLevel::Error, 350, "Coro_ProcessSelectedFile");
                NotifyWarn("Error | Unsupported file type.");
            }

            // 

        }
    }

    //////////////////////////////////////////////////////////////////////////

    void LoadRecordFromUrl(const string &in url) {
        startnew(CoroutineFuncUserdataString(Coro_LoadRecordFromUrl), url);
    }

    void Coro_LoadRecordFromUrl(const string &in url) {
        if (url.StartsWith("https://") || url.StartsWith("http://") || url.Contains("trackmania.io") || url.Contains("trackmania.exchange") || url.Contains("www.")) {
            _Net::DownloadFileToDestination(url, Server::linksFilesDirectory + Path::GetFileName(url), "Link");
            startnew(CoroutineFuncUserdataString(ProcessDownloadedFile), "Link");
            
            LoadRecordFromLocalFile(Server::linksFilesDirectory + Path::GetFileName(url));
        } else {
            log("Invalid URL.", LogLevel::Error, 370, "Coro_LoadRecordFromUrl");
        }
    }

    void ProcessDownloadedFile(const string &in key) {
        while (!_Net::downloadedFilePaths.Exists(key)) { yield(); }

        string finalFilePath = string(_Net::downloadedFilePaths[key]);
        _Net::downloadedFilePaths.Delete(key);
        while (!IO::FileExists(finalFilePath)) { yield(); }
    }

    //////////////////////////////////////////////////////////////////////////

    void LoadRecordFromMapUid(const string &in mapUid, const string &in offset, const string &in _specialSaveLocation, const string &in _accountId = "", const string &in _mapId = "") {
        Features::LRFromMapIdentifier::LoadSelectedRecord(mapUid, offset, _specialSaveLocation, _accountId, _mapId);
    }
}