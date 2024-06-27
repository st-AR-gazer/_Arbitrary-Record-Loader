namespace OfficialManager {
    namespace DownloadingFiles {
        uint lastCheckedOffset = 0;
        uint checkIntervalDays = 3;
        uint longIntervalDays = 88;
        int64 lastCheckedTimestamp = 0;

        const string BASE_URL = "https://live-services.trackmania.nadeo.live/api/token/campaign/official";

        void Init() {
            log("Initializing OfficialManager::DownloadingFiles", LogLevel::Info, 11, "Init");
            LoadLastCheckedData();
            CheckForNewCampaignIfNeeded();
        }

        void LoadLastCheckedData() {
            log("Loading last checked data", LogLevel::Info, 17, "LoadLastCheckedData");

            string offsetFilePath = Server::officialJsonFilesDirectory + "/last_checked_offset.txt";
            if (IO::FileExists(offsetFilePath)) {
                IO::File file(offsetFilePath, IO::FileMode::Read);
                lastCheckedOffset = Text::ParseUInt(file.ReadToEnd());
                file.Close();
                log("Loaded lastCheckedOffset: " + lastCheckedOffset, LogLevel::Info, 24, "LoadLastCheckedData");
            } else {
                lastCheckedOffset = 0;
                log("Offset file not found, setting lastCheckedOffset to 0", LogLevel::Warn, 27, "LoadLastCheckedData");
            }

            string timestampFilePath = Server::officialJsonFilesDirectory + "/last_checked_timestamp.txt";
            if (IO::FileExists(timestampFilePath)) {
                IO::File file(timestampFilePath, IO::FileMode::Read);
                lastCheckedTimestamp = Text::ParseInt64(file.ReadToEnd());
                file.Close();
                log("Loaded lastCheckedTimestamp: " + lastCheckedTimestamp, LogLevel::Info, 35, "LoadLastCheckedData");
            } else {
                lastCheckedTimestamp = Time::Stamp - 3600 * 24 * checkIntervalDays;
                log("Timestamp file not found, setting lastCheckedTimestamp to current time minus interval", LogLevel::Warn, 38, "LoadLastCheckedData");
            }
        }

        void SaveLastCheckedData() {
            log("Saving last checked data", LogLevel::Info, 43, "SaveLastCheckedData");

            string offsetFilePath = Server::officialJsonFilesDirectory + "/last_checked_offset.txt";
            string timestampFilePath = Server::officialJsonFilesDirectory + "/last_checked_timestamp.txt";

            string offsetContent = ("" + lastCheckedOffset);
            string timestampContent = ("" + lastCheckedTimestamp);

            IO::File offsetFile(offsetFilePath, IO::FileMode::Write);
            offsetFile.Write(offsetContent);
            offsetFile.Close();
            log("Saved lastCheckedOffset: " + lastCheckedOffset, LogLevel::Info, 54, "SaveLastCheckedData");

            IO::File timestampFile(timestampFilePath, IO::FileMode::Write);
            timestampFile.Write(timestampContent);
            timestampFile.Close();
            log("Saved lastCheckedTimestamp: " + lastCheckedTimestamp, LogLevel::Info, 59, "SaveLastCheckedData");
        }

        void CheckForNewCampaignIfNeeded() {
            log("Checking if we need to check for new campaign", LogLevel::Info, 63, "CheckForNewCampaignIfNeeded");

            int64 currentTime = Time::Stamp;
            int64 timeSinceLastCheck = currentTime - lastCheckedTimestamp;
            int64 threeDaysInSeconds = 3600 * 24 * 3;
            int64 eightyEightDaysInSeconds = 3600 * 24 * 88;

            if (timeSinceLastCheck >= eightyEightDaysInSeconds || timeSinceLastCheck >= threeDaysInSeconds) {
                log("Time since last check is greater than interval, starting new campaign check", LogLevel::Info, 71, "CheckForNewCampaignIfNeeded");
                startnew(CheckForNewCampaignCoroutine);
            } else {
                log("Time since last check is less than interval, no need to check for new campaign", LogLevel::Info, 74, "CheckForNewCampaignIfNeeded");
            }
        }

        void CheckForNewCampaignCoroutine() {
            CheckForNewCampaign();
            lastCheckedTimestamp = Time::Stamp;
            SaveLastCheckedData();
        }

        void CheckForNewCampaign() {
            log("Checking for new campaign", LogLevel::Info, 85, "CheckForNewCampaign");

            uint offset = lastCheckedOffset + 1;
            auto req = Net::HttpGet(BASE_URL + "?offset=" + offset + "&length=1");

            if (req.ResponseCode() == 200) {
                Json::Value data = Json::Parse(req.String());
                if (data.HasKey("campaignList") && data["campaignList"].Length > 0) {
                    Json::Value campaign = data["campaignList"][0];
                    log("New campaign found: " + campaign["name"], LogLevel::Info, 94, "CheckForNewCampaign");
                    SaveCampaignData(campaign);
                    lastCheckedOffset = offset;
                    SaveLastCheckedData();
                    checkIntervalDays = longIntervalDays;
                } else {
                    log("No new campaigns found", LogLevel::Info, 100, "CheckForNewCampaign");
                    checkIntervalDays = 3;
                }
            } else {
                log("Failed to fetch campaign data, response code: " + req.ResponseCode(), LogLevel::Error, 104, "CheckForNewCampaign");
            }
        }

        void SaveCampaignData(const Json::Value &in campaign) {
            log("Saving campaign data: " + campaign["name"], LogLevel::Info, 109, "SaveCampaignData");

            string year = campaign["year"];
            string season = campaign["name"];
            string fileName = Server::officialJsonFilesDirectory + "/" + year + "_" + season + ".json";

            IO::File file(fileName, IO::FileMode::Write);
            file.Write(Json::Write(campaign));
            file.Close();
            log("Campaign data saved to: " + fileName, LogLevel::Info, 118, "SaveCampaignData");
        }
    }

    namespace UI {
        void UpdateSeasons() {
            seasons.RemoveRange(0, seasons.Length);
            selectedSeason = -1;
            selectedMap = -1;
            maps.RemoveRange(0, maps.Length);

            seasons = {"Spring", "Summer", "Fall", "Winter"};
        }

        void UpdateMaps() {
            maps.RemoveRange(0, maps.Length);
            selectedMap = -1;

            for (int i = 1; i <= 25; i++) {
                maps.InsertLast("Map " + tostring(i));
            }
        }

        void PopulateYears() {
            years.RemoveRange(0, years.Length);
            selectedYear = -1;
            selectedSeason = -1;
            selectedMap = -1;
            maps.RemoveRange(0, maps.Length);
            seasons.RemoveRange(0, seasons.Length);

            Time::Info info;
            int currentYear = info.Year;

            for (int y = 2020; y <= currentYear; y++) {
                years.InsertLast(y);
            }
        }
    }

    namespace HandlingUserInput {
        void LoadSelectedRecord() {
            startnew(CoroutineLoadSelectedGhost);
        }

        void CoroutineLoadSelectedGhost() {
            string mapUid = FetchMapUID();
            if (mapUid.Length==0) {
                log("Map UID not found.", LogLevel::Error, 166, "CoroutineLoadSelectedGhost");
                return;
            }

            string offset = selectedOffset;
            if (offset.Length==0) {
                log("Offset not provided.", LogLevel::Error, 172, "CoroutineLoadSelectedGhost");
                return;
            }

            string accountId = FetchAccountId(mapUid, Text::ParseUInt(offset));
            if (accountId.Length==0) {
                log("Account ID not found.", LogLevel::Error, 178, "CoroutineLoadSelectedGhost");
                return;
            }

            string mapId = FetchMapId(mapUid);
            if (mapId.Length==0) {
                log("Map ID not found.", LogLevel::Error, 184, "CoroutineLoadSelectedGhost");
                return;
            }

            FetchAndSaveReplay(mapId, accountId, offset);
        }

        string FetchMapUID() {
            if (selectedYear == -1 || selectedSeason == -1 || selectedMap == -1) {
                log("Year, season, or map not selected.", LogLevel::Warn, 193, "FetchMapUID");
                return "";
            }

            string season = seasons[selectedSeason];
            int year = years[selectedYear];
            int mapPosition = selectedMap;

            string filePath = Server::officialJsonFilesDirectory + "/" + season + "_" + tostring(year) + ".json";
            if (!IO::FileExists(filePath)) {
                log("File not found: " + filePath, LogLevel::Error, 203, "FetchMapUID");
                return "";
            }

            Json::Value root = Json::Parse(_IO::File::ReadFileToEnd(filePath));
            if (root.GetType() == Json::Type::Null) {
                log("Failed to parse JSON file: " + filePath, LogLevel::Error, 209, "FetchMapUID");
                return "";
            }

            auto campaignList = root["campaignList"];
            if (campaignList.GetType() != Json::Type::Array) {
                log("Invalid campaign list in JSON file: " + filePath, LogLevel::Error, 215, "FetchMapUID");
                return "";
            }

            for (uint i = 0; i < campaignList.Length; i++) {
                auto campaign = campaignList[i];
                auto playlist = campaign["playlist"];
                if (playlist.GetType() != Json::Type::Array) {
                    continue;
                }

                for (uint j = 0; j < playlist.Length; j++) {
                    auto map = playlist[j];
                    if (map["position"] == mapPosition) {
                        string mapUid = map["mapUid"];
                        log("Found map UID: " + mapUid, LogLevel::Info, 230, "FetchMapUID");
                        return mapUid;
                    }
                }
            }

            log("Map UID not found for position: " + tostring(mapPosition), LogLevel::Error, 236, "FetchMapUID");
            return "";
        }

        string FetchAccountId(const string &in mapUid, uint offset) {
            string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?onlyWorld=true&length=1&offset=" + tostring(offset);
            auto req = Net::HttpGet(url);

            if (req.ResponseCode() != 200) {
                log("Failed to fetch account ID, response code: " + req.ResponseCode(), LogLevel::Error, 245, "FetchAccountId");
                return "";
            }

            Json::Value data = Json::Parse(req);
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for account ID.", LogLevel::Error, 251, "FetchAccountId");
                return "";
            }

            auto tops = data["tops"];
            if (tops.GetType() != Json::Type::Array || tops.Length == 0) {
                log("Invalid tops data in response.", LogLevel::Error, 257, "FetchAccountId");
                return "";
            }

            auto top = tops[0]["top"];
            if (top.GetType() != Json::Type::Array || top.Length == 0) {
                log("Invalid top data in response.", LogLevel::Error, 263, "FetchAccountId");
                return "";
            }

            string accountId = top[0]["accountId"];
            log("Found account ID: " + accountId, LogLevel::Info, 268, "FetchAccountId");
            return accountId;
        }

        string FetchMapId(const string &in mapUid) {
            string url = "https://prod.trackmania.core.nadeo.online/maps/?mapUidList=" + mapUid;
            auto req = Net::HttpGet(url);

            if (req.ResponseCode() != 200) {
                log("Failed to fetch map ID, response code: " + req.ResponseCode(), LogLevel::Error, 277, "FetchMapId");
                return "";
            }

            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for map ID.", LogLevel::Error, 283, "FetchMapId");
                return "";
            }

            if (data.GetType() != Json::Type::Array || data.Length == 0) {
                log("Invalid map data in response.", LogLevel::Error, 288, "FetchMapId");
                return "";
            }

            string mapId = data[0]["mapId"];
            log("Found map ID: " + mapId, LogLevel::Info, 293, "FetchMapId");
            return mapId;
        }

        void FetchAndSaveReplay(const string &in mapId, const string &in accountId, const string &in offset) {
            string url = "https://prod.trackmania.core.nadeo.online/mapRecords/?accountIdList=" + accountId + "&mapIdList=" + mapId;
            auto req = Net::HttpGet(url);

            if (req.ResponseCode() != 200) {
                log("Failed to fetch replay record, response code: " + req.ResponseCode(), LogLevel::Error, 302, "FetchAndSaveReplay");
                return;
            }

            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for replay record.", LogLevel::Error, 308, "FetchAndSaveReplay");
                return;
            }

            if (data.GetType() != Json::Type::Array || data.Length == 0) {
                log("Invalid replay data in response.", LogLevel::Error, 313, "FetchAndSaveReplay");
                return;
            }

            string fileUrl = data[0]["url"];
            string mapNameNoneSplit = data[0]["filename"];
            string mapName = mapNameNoneSplit.Split("\\")[1].Split("_")[0];
            string savePath = Server::officialJsonFilesDirectory + "/" + mapName + "_" + accountId + "_Position-" + offset + "_" + tostring(Time::Stamp) + ".Ghost.Gbx";

            auto fileReq = Net::HttpGet(fileUrl);
            if (fileReq.ResponseCode() != 200) {
                log("Failed to download replay file, response code: " + fileReq.ResponseCode(), LogLevel::Error, 323, "FetchAndSaveReplay");
                return;
            }

            _IO::File::WriteToFile(savePath, fileReq.Buffer());

            ProcessSelectedFile(savePath);

            log("Replay file saved to: " + savePath, LogLevel::Info, 331, "FetchAndSaveReplay");
        }
    }
}
