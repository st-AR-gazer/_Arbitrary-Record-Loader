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
        if (_IO::File::GetFileExtension(downloadPath).ToLower() != "json" && _IO::File::GetFileExtension(downloadPath).ToLower() != ".json") {
            NotifyWarn("Error | Invalid file extension.");
            IsDownloading = false;
        } else if (downloadPath != "") {
            string destinationPath = Server::specificDownloadedJsonFilesDirectory + _IO::File::GetFileName(downloadPath);
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
            _IO::Folder::RecursiveCreateFolder(Server::specificDownloadedJsonFilesDirectory);
        }
        files = IO::IndexFolder(Server::specificDownloadedJsonFilesDirectory, true);
        jsonFiles.Resize(files.Length);
        for (uint i = 0; i < files.Length; i++) {
            jsonFiles[i] = _IO::File::GetFileName(files[i]);
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
            _IO::File::WriteToFile(destinationPath, content);
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
        _IO::File::WriteToFile(filePath, Json::Write(newProfile));
        
        NewProfileMaps.RemoveRange(0, NewProfileMaps.Length);
    }

    namespace CDN {
        bool IsDownloading = false;
        string manifestUrl = "http://maniacdn.net/ar_/Arbitrary-Record-Loader/manifest/manifest.json";
        string manifestPreinstalled = "http://maniacdn.net/ar_/Arbitrary-Record-Loader/preinstalled/";
        string currentVersion = "v1";

        void StartManifestDownload() {
            startnew(Coro_FetchManifest);
        }

        void Coro_FetchManifest() {
            IsDownloading = true;
            auto req = Net::HttpGet(manifestUrl);
            while (!req.Finished()) {
                yield();
            }

            if (req.ResponseCode() == 200) {
                ParseManifest(req.String());
            } else {
                log("Error fetching manifest: " + req.ResponseCode(), LogLevel::Error, 118, "Coro_FetchManifest");
            }
            IsDownloading = false;
        }

        void ParseManifest(const string &in reqBody) {
            Json::Value manifest = Json::Parse(reqBody);
            if (manifest.GetType() != Json::Type::Object) {
                log("Failed to parse JSON.", LogLevel::Error, 126, "ParseManifest");
                return;
            }

            string manifestVersion = manifest["version"];
            if (currentVersion != manifestVersion) {
                auto files = manifest["files"];
                for (uint i = 0; i < files.Length; i++) {
                    string fileUrl = manifestPreinstalled + string(files[i]);
                    string destinationPath = Server::specificDownloadedJsonFilesDirectory + string(files[i]);
                    DownloadFileToDestination(fileUrl, destinationPath);
                }
                currentVersion = manifestVersion;
                SaveCurrentVersion(manifestVersion);
            }
        }

        void DownloadFileToDestination(const string &in url, const string &in destinationPath) {
            auto req = Net::HttpGet(url);
            while (!req.Finished()) {
                yield();
            }
            if (req.ResponseCode() == 200) {
                auto content = req.String();
                _IO::File::WriteToFile(destinationPath, content);
            } else {
                NotifyWarn("Error | Failed to download file from URL.");
            }
        }

        void SaveCurrentVersion(const string &in version) {
            string versionFilePath = Server::specificDownloaded + "version.txt";
            _IO::File::WriteToFile(versionFilePath, version);
        }

        string LoadCurrentVersion() {
            string versionFilePath = Server::specificDownloaded + "version.txt";
            if (IO::FileExists(versionFilePath)) {
                return _IO::File::ReadFileToEnd(versionFilePath);
            }
            return "";
        }

        void Init() {
            currentVersion = LoadCurrentVersion();
            StartManifestDownload();
        }
    }
}
