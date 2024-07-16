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

    
    _IO::File::WriteToFile(Server::specificDownloadedJsonFilesDirectory + "");
}