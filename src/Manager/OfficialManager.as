dictionary mapUIDMapping;

void LoadCampaignData() {
    string directory = _IO::File::SafeFromStorageFolder("Server/Official/");
    array<string> files = IO::IndexFolder(directory);

    for (uint i = 0; i < files.Length; i++) {
        string fileContent = _IO::File::ReadFileToEnd(files[i]);
        Json::Value json = Json::Parse(fileContent);
        if (json.HasKey("campaignList")) {
            Json::Value campaignList = json["campaignList"];
            for (uint j = 0; j < campaignList.Length; j++) {
                Json::Value campaign = campaignList[j];
                string season = campaign["name"];
                string year = campaign["startTimestamp"];
                Json::Value playlist = campaign["playlist"];
                for (uint k = 0; k < playlist.Length; k++) {
                    Json::Value map = playlist[k];
                    string mapUID = map["mapUid"];
                    string key = season + "_" + year + "_" + k;
                    mapUIDMapping.Set(key, mapUID);
                }
            }
        }
    }
}

string GetMapUID(const string &in season, const string &in year, const string &in mapNumber) {
    string key = season + "_" + year + "_" + mapNumber;
    if (mapUIDMapping.Exists(key)) {
        return string(mapUIDMapping[key]);
    }
    return "";
}

void InitializeMapUIDMapping() {
    mapUIDMapping.DeleteAll();
    LoadCampaignData();
}

const string lastCheckFilePath = _IO::File::SafeFromStorageFolder("Server/Official/") + "last_check_time.txt";

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

        string currentTime = GetApp().OSUTCTime;
        _IO::File::WriteToFile(lastCheckFilePath, currentTime);
        InitializeMapUIDMapping();
    } else {
        NotifyWarn("Failed to fetch campaigns. Response code: " + request.ResponseCode());
    }
}

bool ShouldFetchNewCampaigns() {
    if (!_IO::File::IsFile(lastCheckFilePath)) {
        return true;
    }
    string lastCheckTime = _IO::File::ReadFileToEnd(lastCheckFilePath);
    string currentTime = GetApp().OSUTCTime;

    return currentTime > lastCheckTime;
}