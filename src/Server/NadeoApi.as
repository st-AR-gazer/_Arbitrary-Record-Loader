NadeoApi@ api;

class NadeoApi {
    string liveSvcUrl;

    NadeoApi() {
        NadeoServices::AddAudience("NadeoLiveServices");
        liveSvcUrl = NadeoServices::BaseURLLive();
    }

    void AssertGoodPath(const string &in path) {
        if (path.Length <= 0 || !path.StartsWith("/")) {
            log("API Paths should start with '/'!", LogLevel::Error, 30, "AssertGoodPath");
        }
    }

    Json::Value CallLiveApiPath(const string &in path) {
        AssertGoodPath(path);
        return FetchLiveEndpoint(liveSvcUrl + path);
    }

    Json::Value GetMapRecords(const string &in seasonUid = "Personal_Best", const string &in mapUid, bool onlyWorld = true, uint length = 1, uint offset = 0) {
        string qParams = onlyWorld ? "?onlyWorld=true" : "";
        if (onlyWorld) qParams += "&" + "length=" + /*length*/"1" + "&offset=" + offset;
        return CallLiveApiPath("/api/token/leaderboard/group/" + seasonUid + "/map/" + mapUid + "/top" + qParams);
    }
}

Json::Value FetchLiveEndpoint(const string &in route) {
    log("[FetchLiveEndpoint] Requesting: " + route, LogLevel::Info, 30, "AssertGoodPath");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) { yield(); }
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}

void FetchAndStoreCampaigns(int length, int offset) {
    string url = "https://live-services.trackmania.nadeo.live/api/token/campaign/official?length=" + length + "&offset=" + offset;
    Net::HttpRequest@ request = Net::HttpRequest();
    request.Url = url;
    request.Method = Net::HttpMethod::Get;
    request.Start();
    
    while (!request.Finished()) {
        yield();
    }

    if (request.ResponseCode() == 200) {
        string response = request.String();
        string filePath = _IO::File::SafeFromStorageFolder("Server/Official/") + "campaigns_" + length + "_" + offset + ".json";
        _IO::File::WriteToFile(filePath, response);
        NotifyInfo("Campaigns fetched and stored successfully.");
    } else {
        NotifyWarn("Failed to fetch campaigns. Response code: " + request.ResponseCode());
    }
}