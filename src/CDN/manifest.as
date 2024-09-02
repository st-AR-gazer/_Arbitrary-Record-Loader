[Setting name="Should download files from CDN if they are already downloaded" category="CDN"]
bool shouldDownloadFilesIfTheyAreAleadyDownloaded = false;

string manifestUrl = "http://maniacdn.net/ar_/Arbitrary-Record-Loader/manifest/manifest.json";
string manifestPreinstalled = "http://maniacdn.net/ar_/Arbitrary-Record-Loader/preinstalled/";

void FetchManifest() {
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
        log("Error fetching manifest: " + req.ResponseCode(), LogLevel::Error, 17, "FetchManifest");
    }
}

void ParseManifest(const string &in reqBody) {
    Json::Value manifest = Json::Parse(reqBody);
    if (manifest.GetType() != Json::Type::Object) {
        log("Failed to parse JSON.", LogLevel::Error, 24, "ParseManifest");
        return;
    }

    bool shouldUpdate = manifest["shouldUpdate"];
    if (!shouldUpdate) return;

    int version = manifest["version"];
    if (version > get_StoredVersion()) {
        log("New version available: " + version, LogLevel::Info, 32, "ParseManifest");
        DownloadFiles(manifest);
    } else {
        log("No new version available.", LogLevel::Info, 35, "ParseManifest");
        SetStoredVersion(version);
    }
}

void DownloadFiles(Json::Value &manifest) {
    Json::Value files = manifest["files"];
    for (uint i = 0; i < files.Length; i++) {
        string filename = files[i]["filename"];
        string url = files[i]["url"];
        string path = files[i]["path"];

        if (shouldDownloadFilesIfTheyAreAleadyDownloaded || !IO::FileExists(path)) {
            log("Downloading: " + filename, LogLevel::Info, 49, "DownloadFiles");
            _Net::DownloadFileToDestination(url, path);
        }
    }
}

int get_StoredVersion() {
    if (!IO::FileExists(IO::FromStorageFolder("version.txt"))) { return -1; }

    string version = _IO::File::ReadFileToEnd(IO::FromStorageFolder("version.txt"));
    return int(version);
}

void SetStoredVersion(int version) {
    _IO::File::WriteFile(IO::FromStorageFolder("version.txt"), "" + version);
}