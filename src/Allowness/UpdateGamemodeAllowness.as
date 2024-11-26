namespace GamemodeAllowness {
    bool mainRequestFailed;

    string url = "http://allowness.p.xjk.yt/arl/gamemode/allowness";
    string backupUrl = "http://maniacdn.net/ar_/Allowness/allowed_gamemodes.json";

    void FetchAllowedGamemodes() {
        startnew(Coro_FetchAllowedGamemodes);
    }

    void Coro_FetchAllowedGamemodes() {
        mainRequestFailed = false;
        startnew(CoroutineFuncUserdataString(Coro_FetchAllowedGamemodesFromNet), url);
        while (mainRequestFailed) { yield(); }
        if (mainRequestFailed) {
            startnew(CoroutineFuncUserdataString(Coro_FetchAllowedGamemodesFromNet), backupUrl);
        }
    }

    void Coro_FetchAllowedGamemodesFromNet(string url) {

        _Net::GetRequestToEndpoint(url, "gamemodeAllowness");
        while (!_Net::downloadedData.Exists("gamemodeAllowness")) { yield(); }
        string reqBody = string(_Net::downloadedData["gamemodeAllowness"]);
        _Net::downloadedData.Delete("gamemodeAllowness");
        
        if (Json::Parse(reqBody).GetType() != Json::Type::Object) { log("Failed to parse JSON.", LogLevel::Error, 129, "FetchManifest"); mainRequestFailed = true; return; }

        Json::Value manifest = Json::Parse(reqBody);
        if (manifest.HasKey("error") && manifest["code"] != 200) { log("Failed to fetch data", LogLevel::Error, 133, "FetchManifest"); mainRequestFailed = true; return; }

        for (uint i = 0; i < manifest["blockedGamemodeList"].Length; i++) {
            GamemodeAllowness::gameModeBlackList.InsertLast(manifest["blockedGamemodeList"][i]);
        }
    }
}