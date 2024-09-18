namespace OtherManager {
    array<string> jsonFiles;
    bool IsDownloading = false;
    bool IsCreatingProfile = false;

    class MapEntry {
        string mapName;
        string mapUid;
    }

    array<MapEntry> NewProfileMaps;

    void StartDownload(const string &in downloadPath) {
        startnew(Coro_DownloadAndRefreshJsonFiles, downloadPath);
    }

    void Coro_DownloadAndRefreshJsonFiles(const string &in downloadPath) {
        IsDownloading = true;
        if (Path::GetExtension(downloadPath).ToLower() != "json" && Path::GetExtension(downloadPath).ToLower() != ".json") {
            NotifyWarn("Error | Invalid file extension.");
            IsDownloading = false;
        } else if (downloadPath != "") {
            string destinationPath = Server::specificDownloadedJsonFilesDirectory + Path::GetFileName(downloadPath);
            DownloadFileToDestination(downloadPath, destinationPath);
            jsonFiles = GetAvailableJsonFiles();
            IsDownloading = false;
        } else {
            NotifyWarn("Error | No Json Download provided.");
            IsDownloading = false;
        }
    }

    array<string> GetAvailableJsonFiles() {
        array<string> files;
        if (IO::FolderExists(Server::specificDownloadedJsonFilesDirectory) == false) {
            IO::CreateFolder(Server::specificDownloadedJsonFilesDirectory, true);
        }
        files = IO::IndexFolder(Server::specificDownloadedJsonFilesDirectory, true);
        jsonFiles.Resize(files.Length);
        for (uint i = 0; i < files.Length; i++) {
            jsonFiles[i] = Path::GetFileName(files[i]);
        }
        return jsonFiles;
    }

    string LoadJsonContent(const string &in fileName) {
        string filePath = Server::specificDownloadedJsonFilesDirectory + fileName;
        return _IO::File::ReadFileToEnd(filePath);
    }

    array<Json::Value> GetMapListFromJson(const string &in content) {
        array<Json::Value> mapList;
        if (content != "") {
            Json::Value json = Json::Parse(content);
            if (json.GetType() == Json::Type::Object && json.HasKey("maps")) {
                Json::Value maps = json["maps"];
                for (uint i = 0; i < maps.Length; i++) {
                    mapList.InsertLast(maps[i]);
                }
            }
        }
        return mapList;
    }

    void DownloadFileToDestination(const string &in url, const string &in destinationPath) {
        auto req = Net::HttpGet(url);
        while (!req.Finished()) {
            yield();
        }
        if (req.ResponseCode() == 200) {
            auto content = req.String();
            _IO::File::WriteFile(destinationPath, content);
        } else {
            NotifyWarn("Error | Failed to download file from URL.");
        }
    }

    void SaveNewProfile(const string &in jsonName) {

        Json::Value newProfile = Json::Object();
        
        newProfile["jsonName"] = jsonName;
        newProfile["maps"] = Json::Array();
        
        for (uint i = 0; i < NewProfileMaps.Length; i++) {
            Json::Value newMap = Json::Object();
            newMap["mapName"] = NewProfileMaps[i].mapName;
            newMap["mapUid"] = NewProfileMaps[i].mapUid;
            newProfile["maps"].Add(newMap);
        }

        string filePath = Server::specificDownloadedCreatedProfilesDirectory + jsonName + ".json";
        _IO::File::WriteFile(filePath, Json::Write(newProfile));
        
        NewProfileMaps.RemoveRange(0, NewProfileMaps.Length);
    }

    namespace CDN {

        [Setting name="Should download files from CDN if they are already downloaded" category="CDN"]
        bool shouldDownloadFilesIfTheyAreAleadyDownloaded = false;

        string manifestUrl = "http://maniacdn.net/ar_/Arbitrary-Record-Loader/manifest/manifest.json";
        string manifestPreinstalled = "http://maniacdn.net/ar_/Arbitrary-Record-Loader/preinstalled/";

        void Coro_FetchManifest() {
            Net::HttpRequest req;
            req.Method = Net::HttpMethod::Get;
            req.Url = manifestUrl;
            req.Start();

            while (!req.Finished()) {
                yield();
            }

            if (req.ResponseCode() == 200) {
                ParseManifest(req.String());
            } else {
                log("Error fetching manifest: " + req.ResponseCode(), LogLevel::Error, 119, "Coro_FetchManifest");
            }
        }

        void ParseManifest(const string &in reqBody) {
            Json::Value manifest = Json::Parse(reqBody);
            if (manifest.GetType() != Json::Type::Object) {
                log("Failed to parse JSON.", LogLevel::Error, 126, "ParseManifest");
                return;
            }

            bool shouldUpdate = manifest["shouldUpdate"];
            if (!shouldUpdate) return;

            int version = manifest["version"];
            if (version > get_StoredVersion()) {
                log("New version available: " + version, LogLevel::Info, 135, "ParseManifest");
                DownloadFiles(manifest);
                UpdateBlockedGamemodes(manifest);
                SetStoredVersion(version);
            } else {
                log("No new version available.", LogLevel::Info, 140, "ParseManifest");
            }
        }

        void DownloadFiles(Json::Value &manifest) {
            Json::Value files = manifest["fileNames"];

            array<string> keys = files.GetKeys();

            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                
                string filename = string(files[key]);
                string url = manifestPreinstalled + filename;
                string path = Server::specificDownloadedJsonFilesDirectory + filename;

                if (shouldDownloadFilesIfTheyAreAleadyDownloaded || !IO::FileExists(path)) {
                    log("Downloading: " + filename, LogLevel::Info, 157, "DownloadFiles");

                    _Net::DownloadFileToDestination(url, path, "other", Path::GetFileName(filename));
                }
            }
        }

        void UpdateBlockedGamemodes(Json::Value &manifest) {
            if (manifest.HasKey("blockedGamemodeList")) {
                GameModeBlackList.RemoveRange(0, GameModeBlackList.Length);

                Json::Value blockedList = manifest["blockedGamemodeList"];
                for (uint i = 0; i < blockedList.Length; i++) {
                    GameModeBlackList.InsertLast(blockedList[i]);
                }

                log("Blocked gamemodes updated.", LogLevel::Info, 173, "UpdateBlockedGamemodes");
            } else {
                log("No blocked gamemodes in manifest.", LogLevel::Info, 175, "UpdateBlockedGamemodes");
            }
        }

        int get_StoredVersion() {
            if (!IO::FileExists(IO::FromStorageFolder("version.txt"))) { return -1; }

            string version = _IO::File::ReadFileToEnd(IO::FromStorageFolder("version.txt"));
            return Text::ParseInt(version);
        }

        void SetStoredVersion(int version) {
            _IO::File::WriteFile(IO::FromStorageFolder("version.txt"), "" + version);
        }

        void StartManifestDownload() {
            startnew(Coro_FetchManifest);
        }

        void Init() {
            StartManifestDownload();
        }
    }

}
