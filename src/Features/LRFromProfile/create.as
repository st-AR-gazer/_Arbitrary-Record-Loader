// src/Features/LoadRecordFromProfile/backend.as

namespace Features {
namespace LRFromProfile {
namespace Create {
    array<string> jsonFiles;
    bool isDownloading = false;
    bool isCreatingProfile = false;

    class MapEntry {
        string mapName;
        string mapUid;
    }

    array<MapEntry> newProfileMaps;

    void StartDownload(const string &in downloadPath) {
        startnew(Coro_DownloadAndRefreshJsonFiles, downloadPath);
    }

    void Coro_DownloadAndRefreshJsonFiles(const string &in downloadPath) {
        isDownloading = true;
        if (Path::GetExtension(downloadPath).ToLower() != "json" && Path::GetExtension(downloadPath).ToLower() != ".json") {
            NotifyWarn("Error | Invalid file extension.");
            isDownloading = false;
        } else if (downloadPath != "") {
            string destinationPath = Server::specificDownloadedJsonFilesDirectory + Path::GetFileName(downloadPath);
            DownloadFileToDestination(downloadPath, destinationPath);
            jsonFiles = GetAvailableJsonFiles();
            isDownloading = false;
        } else {
            NotifyWarn("Error | No Json Download provided.");
            isDownloading = false;
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
        
        for (uint i = 0; i < newProfileMaps.Length; i++) {
            Json::Value newMap = Json::Object();
            newMap["mapName"] = newProfileMaps[i].mapName;
            newMap["mapUid"] = newProfileMaps[i].mapUid;
            newProfile["maps"].Add(newMap);
        }

        string filePath = Server::specificDownloadedCreatedProfilesDirectory + jsonName + ".json";
        _IO::File::WriteFile(filePath, Json::Write(newProfile));
        
        newProfileMaps.RemoveRange(0, newProfileMaps.Length);
    }
}
}
}