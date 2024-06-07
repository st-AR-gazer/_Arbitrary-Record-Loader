NadeoApi@ api;

class NadeoApi {
    string liveSvcUrl;

    NadeoApi() {
        NadeoServices::AddAudience("NadeoLiveServices");
        liveSvcUrl = NadeoServices::BaseURLLive();
    }

    void AssertGoodPath(const string &in path) {
        if (path.Length <= 0 || !path.StartsWith("/")) {
            log("API Paths should start with '/'!", LogLevel::Error, 34, "LengthAndOffset");
        }
    }

    const string LengthAndOffset(uint length, uint offset) {
        return "length=" + length + "&offset=" + offset;
    }

    Json::Value CallLiveApiPath(const string &in path) {
        AssertGoodPath(path);
        return FetchLiveEndpoint(liveSvcUrl + path);
    }

    Json::Value GetMapRecords(const string &in seasonUid, const string &in mapUid, bool onlyWorld = true, uint length=5, uint offset=0) {
        string qParams = onlyWorld ? "?onlyWorld=true" : "";
        if (onlyWorld) qParams += "&" + LengthAndOffset(length, offset);
        return CallLiveApiPath("/api/token/leaderboard/group/" + seasonUid + "/map/" + mapUid + "/top" + qParams);
    }
}

Json::Value FetchLiveEndpoint(const string &in route) {
    //log("[FetchLiveEndpoint] Requesting: " + route, LogLevel::Info, 34, "LengthAndOffset");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) { yield(); }
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}
