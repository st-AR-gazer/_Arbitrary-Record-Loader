namespace OfficialManager {
    namespace Record {
        uint offset;
    }

    string baseUrl = "https://live-services.trackmania.nadeo.live/api/token/campaign/official";
    
    enum Season { Winter, Spring, Summer, Fall }
    enum Year { y2020, y2021, y2022, y2023, y2024 }
    enum MapNumber { mn1, mn2, mn3, mn4, mn5, mn6, mn7, mn8, mn9, mn10, mn11, mn12, mn13, mn14, mn15, mn16, mn17, mn18, mn19, mn20, mn21, mn22, mn23, mn24, mn25 }

    dictionary campaignData;  // Stores the campaign data

    void Initialize() {
        LoadCampaignData();
        CheckForNewCampaigns();
    }

    void LoadCampaignData() {
        // Load existing campaign data from storage
        // Placeholder for loading logic
    }

    void CheckForNewCampaigns() {
        if (ShouldFetchNewCampaigns()) {
            FetchAndStoreCampaigns();
        }
    }

    void FetchAndStoreCampaigns(int length = 1, int offset = 0) {
        Net::HttpRequest req;
        req.Url = baseUrl + "?length=" + length + "&offset=" + offset;
        req.Start();
        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() == 200) {
            Json::Value data = Json::Parse(req.String());
            if (data["campaignList"].Length > 0) {
                SaveCampaignData(data["campaignList"]);
            }
        }
    }

    void SaveCampaignData(const Json::Value &in campaigns) {
        for (uint i = 0; i < campaigns.Length; i++) {
            auto campaign = campaigns[i];
            string key = tostring(campaign["seasonUid"]) + "_" + tostring(campaign["year"]);
            campaignData.Set(key, campaign);
            // Save to storage logic
        }
    }

    bool ShouldFetchNewCampaigns() {
        // Logic to decide whether fetching new campaigns is necessary
        return true; // Placeholder
    }

    string GetMapUID(Season season, Year year, MapNumber mapNumber) {
        string seasonKey = tostring(season) + "_" + tostring(year);
        if (campaignData.Exists(seasonKey)) {
            Json::Value campaign;
            campaignData.Get(seasonKey, campaign);
            if (int(campaign["playlist"].Length) > int(mapNumber)) {
                return campaign["playlist"][int(mapNumber)]["mapUid"];
            }
        }
        return "";
    }
}