class NadeoApi {
    string liveSvcUrl;

    NadeoApi() {
        NadeoServices::AddAudience("NadeoLiveServices");
        liveSvcUrl = NadeoServices::BaseURLLive();
    }

    void Init() {
        NadeoServices::AddAudience(audience);
        liveSvcUrl = NadeoServices::BaseURLLive();
    }

    void AssertGoodPath(const string &in path) {
        if (path.Length <= 0 || !path.StartsWith("/")) {
            throw("API Paths should start with '/'!");
        }
    }

    const string LengthAndOffset(uint length, uint offset) {
        return "length=" + length + "&offset=" + offset;
    }

    Json::Value CallLiveApiPath(const string &in path) {
        AssertGoodPath(path);
        return FetchLiveEndpoint(liveSvcUrl + path);
    }

    Json::Value GetMapRecords(const string &in accountIdList, const string &in mapIdList, const string &in seasonId = "") {
        string url = "/mapRecords/?accountIdList=" + accountIdList + "&mapIdList=" + mapIdList;
        if (seasonId != "") url += "&seasonId=" + seasonId;
        return CallLiveApiPath(url);
    }

    Json::Value GetMapRecordById(const string &in mapRecordId) {
        return CallLiveApiPath("/mapRecords/" + mapRecordId);
    }
}

Json::Value FetchLiveEndpoint(const string &in route) {
    //log("[FetchLiveEndpoint] Requesting: " + route, LogLevel::Info, 41, "LengthAndOffset");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) { yield(); }
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}
