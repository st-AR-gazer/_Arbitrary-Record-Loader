string g_leaderboard = "Personal_Best";
string g_MLHookCustomEvent = "TMGame_Record_ToggleGhost";
string g_MLHookCustomSpecEvent = "TMGame_Record_SpectateGhost";

string manifestUrl = "http://maniacdn.net/ar_/Load-Arbirary-Ghosts/manifest/manifest.json";

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
        log("Error fetching manifest: " + req.ResponseCode(), LogLevel::Error, 20, "FetchManifest");
    }
}

void ParseManifest(const string &in reqBody) {
    Json::Value manifest = Json::Parse(reqBody);
    if (manifest.GetType() != Json::Type::Object) {
        log("Failed to parse JSON.", LogLevel::Error, 27, "ParseManifest");
        return;
    }

    bool shouldUpdate = manifest["shouldUpdate"];
    if (!shouldUpdate) return;

    g_leaderboard = manifest["GetMapRecords"];
    g_MLHookCustomEvent = manifest["MLHook::Queue_SH_SendCustomEvent_ToggleGhost"];
    g_MLHookCustomSpecEvent = manifest["MLHook::Queue_SH_SendCustomEvent_SpectateGhost"];
}