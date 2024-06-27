namespace OfficialManager {
    namespace DownloadingFiles {
        uint lastCheckedOffset = 0;
        uint checkIntervalDays = 3;
        uint longIntervalDays = 88;
        int64 lastCheckedTimestamp = 0;

        void Init() {
            log("Initializing OfficialManager::DownloadingFiles", LogLevel::Info, 9, "Init");
            LoadLastCheckedData();
            CheckForNewCampaignIfNeeded();
        }

        void LoadLastCheckedData() {
            log("Loading last checked data", LogLevel::Info, 15, "LoadLastCheckedData");

            string offsetFilePath = Server::officialJsonFilesDirectory + "/last_checked_offset.txt";
            if (IO::FileExists(offsetFilePath)) {
                IO::File file(offsetFilePath, IO::FileMode::Read);
                lastCheckedOffset = Text::ParseUInt(file.ReadToEnd());
                file.Close();
                log("Loaded lastCheckedOffset: " + lastCheckedOffset, LogLevel::Info, 22, "LoadLastCheckedData");
            } else {
                lastCheckedOffset = 0;
                log("Offset file not found, setting lastCheckedOffset to 0", LogLevel::Warn, 25, "LoadLastCheckedData");
            }

            string timestampFilePath = Server::officialJsonFilesDirectory + "/last_checked_timestamp.txt";
            if (IO::FileExists(timestampFilePath)) {
                IO::File file(timestampFilePath, IO::FileMode::Read);
                lastCheckedTimestamp = Text::ParseInt64(file.ReadToEnd());
                file.Close();
                log("Loaded lastCheckedTimestamp: " + lastCheckedTimestamp, LogLevel::Info, 33, "LoadLastCheckedData");
            } else {
                lastCheckedTimestamp = Time::Stamp - 3600 * 24 * checkIntervalDays;
                log("Timestamp file not found, setting lastCheckedTimestamp to current time minus interval", LogLevel::Warn, 36, "LoadLastCheckedData");
            }
        }

        void SaveLastCheckedData() {
            log("Saving last checked data", LogLevel::Info, 41, "SaveLastCheckedData");

            string offsetFilePath = Server::officialJsonFilesDirectory + "/last_checked_offset.txt";
            string timestampFilePath = Server::officialJsonFilesDirectory + "/last_checked_timestamp.txt";

            string offsetContent = ("" + lastCheckedOffset);
            string timestampContent = ("" + lastCheckedTimestamp);

            IO::File offsetFile(offsetFilePath, IO::FileMode::Write);
            offsetFile.Write(offsetContent);
            offsetFile.Close();
            log("Saved lastCheckedOffset: " + lastCheckedOffset, LogLevel::Info, 52, "SaveLastCheckedData");

            IO::File timestampFile(timestampFilePath, IO::FileMode::Write);
            timestampFile.Write(timestampContent);
            timestampFile.Close();
            log("Saved lastCheckedTimestamp: " + lastCheckedTimestamp, LogLevel::Info, 57, "SaveLastCheckedData");
        }

        void CheckForNewCampaignIfNeeded() {
            log("Checking if we need to check for new campaign", LogLevel::Info, 61, "CheckForNewCampaignIfNeeded");

            int64 currentTime = Time::Stamp;
            int64 timeSinceLastCheck = currentTime - lastCheckedTimestamp;
            int64 threeDaysInSeconds = 3600 * 24 * 3;
            int64 eightyEightDaysInSeconds = 3600 * 24 * 88;

            startnew(CheckForNewCampaignCoroutine);
            
            if (timeSinceLastCheck >= eightyEightDaysInSeconds || timeSinceLastCheck >= threeDaysInSeconds) {
                log("Time since last check is greater than interval, starting new campaign check", LogLevel::Info, 70, "CheckForNewCampaignIfNeeded");
            } else {
                log("Time since last check is less than interval, no need to check for new campaign", LogLevel::Info, 72, "CheckForNewCampaignIfNeeded");
            }
        }

        void CheckForNewCampaignCoroutine() {
            CheckForNewCampaign();
            lastCheckedTimestamp = Time::Stamp;
        }

        array<string> localCampaigns;
        void IndexLocalFiles() {
            localCampaigns.Resize(0);
            bool recursive = false;
            array<string>@ files = IO::IndexFolder(Server::officialJsonFilesDirectory, recursive);

            for (uint i = 0; i < files.Length; ++i) {
                string fileName = _IO::File::GetFileNameWithoutExtension(files[i]);
                localCampaigns.InsertLast(fileName);
            }
        }

        void CheckForNewCampaign() {
            IndexLocalFiles();

            uint offset = 0;
            bool continueChecking = true;
            while (continueChecking) {
                Json::Value data = api.GetOfficialCampaign(offset);
                if (data.HasKey("campaignList") && data["campaignList"].Length > 0) {
                    continueChecking = false;
                    for (uint j = 0; j < data["campaignList"].Length; j++) {
                        Json::Value campaign = data["campaignList"][j];
                        string campaignName = campaign["name"];
                        campaignName = campaignName.Replace(" ", "_");

                        if (localCampaigns.Find(campaignName) == -1) {
                            log("Downloading missing campaign: " + campaignName, LogLevel::Info, 95, "CheckForNewCampaign");
                            SaveCampaignData(campaign);
                            continueChecking = true;
                        }
                    }
                    offset++;
                } else {
                    log("No more campaigns found at offset: " + tostring(offset), LogLevel::Info, 99, "CheckForNewCampaign");
                    continueChecking = false;
                }
            }

            Json::Value latestCampaignData = api.GetOfficialCampaign(0);
            if (latestCampaignData.HasKey("campaignList") && latestCampaignData["campaignList"].Length > 0) {
                Json::Value newestCampaign = latestCampaignData["campaignList"][0];
                string newestCampaignName = newestCampaign["name"];
                newestCampaignName = newestCampaignName.Replace(" ", "_");
                if (localCampaigns.Find(newestCampaignName) == -1) {
                    log("Downloading the latest campaign: " + newestCampaignName, LogLevel::Info, 103, "CheckForNewCampaign");
                    SaveCampaignData(newestCampaign);
                }
            }
        }

        void SaveCampaignData(const Json::Value &in campaign) {
            string campaignName = campaign["name"];
            log("Saving campaign data: " + campaignName, LogLevel::Info, 109, "SaveCampaignData");

            string specificSeason = campaign["name"];
            specificSeason = specificSeason.Replace(" ", "_");
            string fileName = Server::officialJsonFilesDirectory + "/" + specificSeason + ".json";

            IO::File file(fileName, IO::FileMode::Write);
            file.Write(Json::Write(campaign));
            file.Close();
            log("Campaign data saved to: " + fileName, LogLevel::Info, 118, "SaveCampaignData");
        }
    }

    namespace UI {
        void Init() {
            log("Initializing OfficialManager::UI", LogLevel::Info, 124, "Init");
            UpdateSeasons();
            UpdateMaps();
            PopulateYears();
        }

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
                log("Map UID not found.", LogLevel::Error, 173, "CoroutineLoadSelectedGhost");
                return;
            }

            string offset = selectedOffset;
            if (offset.Length==0) {
                log("Offset not provided.", LogLevel::Error, 179, "CoroutineLoadSelectedGhost");
                return;
            }

            string accountId = FetchAccountId(mapUid, Text::ParseUInt(offset));
            if (accountId.Length==0) {
                log("Account ID not found.", LogLevel::Error, 185, "CoroutineLoadSelectedGhost");
                return;
            }

            string mapId = FetchMapId(mapUid);
            if (mapId.Length==0) {
                log("Map ID not found.", LogLevel::Error, 191, "CoroutineLoadSelectedGhost");
                return;
            }

            FetchAndSaveReplay(mapId, accountId, offset);
        }

        string FetchMapUID() {
            if (selectedYear == -1 || selectedSeason == -1 || selectedMap == -1) {
                // log("Year, season, or map not selected.", LogLevel::Warn, 200, "FetchMapUID");
                return "";
            }

            string season = seasons[selectedSeason];
            int year = years[selectedYear];
            int mapPosition = selectedMap;

            string filePath = Server::officialJsonFilesDirectory + "/" + season + "_" + tostring(year) + ".json";
            if (!IO::FileExists(filePath)) {
                log("File not found: " + filePath, LogLevel::Error, 210, "FetchMapUID");
                return "";
            }

            Json::Value root = Json::Parse(_IO::File::ReadFileToEnd(filePath));
            if (root.GetType() == Json::Type::Null) {
                log("Failed to parse JSON file: " + filePath, LogLevel::Error, 216, "FetchMapUID");
                return "";
            }

            auto campaignList = root["campaignList"];
            if (campaignList.GetType() != Json::Type::Array) {
                log("Invalid campaign list in JSON file: " + filePath, LogLevel::Error, 222, "FetchMapUID");
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
                        log("Found map UID: " + mapUid, LogLevel::Info, 237, "FetchMapUID");
                        return mapUid;
                    }
                }
            }

            log("Map UID not found for position: " + tostring(mapPosition), LogLevel::Error, 243, "FetchMapUID");
            return "";
        }

        string FetchAccountId(const string &in mapUid, uint offset) {
            string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?onlyWorld=true&length=1&offset=" + tostring(offset);
            auto req = Net::HttpGet(url);

            if (req.ResponseCode() != 200) {
                log("Failed to fetch account ID, response code: " + req.ResponseCode(), LogLevel::Error, 252, "FetchAccountId");
                return "";
            }

            Json::Value data = Json::Parse(tostring(req));
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for account ID.", LogLevel::Error, 258, "FetchAccountId");
                return "";
            }

            auto tops = data["tops"];
            if (tops.GetType() != Json::Type::Array || tops.Length == 0) {
                log("Invalid tops data in response.", LogLevel::Error, 264, "FetchAccountId");
                return "";
            }

            auto top = tops[0]["top"];
            if (top.GetType() != Json::Type::Array || top.Length == 0) {
                log("Invalid top data in response.", LogLevel::Error, 270, "FetchAccountId");
                return "";
            }

            string accountId = top[0]["accountId"];
            log("Found account ID: " + accountId, LogLevel::Info, 275, "FetchAccountId");
            return accountId;
        }

        string FetchMapId(const string &in mapUid) {
            string url = "https://prod.trackmania.core.nadeo.online/maps/?mapUidList=" + mapUid;
            auto req = Net::HttpGet(url);

            if (req.ResponseCode() != 200) {
                log("Failed to fetch map ID, response code: " + req.ResponseCode(), LogLevel::Error, 284, "FetchMapId");
                return "";
            }

            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for map ID.", LogLevel::Error, 290, "FetchMapId");
                return "";
            }

            if (data.GetType() != Json::Type::Array || data.Length == 0) {
                log("Invalid map data in response.", LogLevel::Error, 295, "FetchMapId");
                return "";
            }

            string mapId = data[0]["mapId"];
            log("Found map ID: " + mapId, LogLevel::Info, 300, "FetchMapId");
            return mapId;
        }

        void FetchAndSaveReplay(const string &in mapId, const string &in accountId, const string &in offset) {
            string url = "https://prod.trackmania.core.nadeo.online/mapRecords/?accountIdList=" + accountId + "&mapIdList=" + mapId;
            auto req = Net::HttpGet(url);

            if (req.ResponseCode() != 200) {
                log("Failed to fetch replay record, response code: " + req.ResponseCode(), LogLevel::Error, 309, "FetchAndSaveReplay");
                return;
            }

            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for replay record.", LogLevel::Error, 315, "FetchAndSaveReplay");
                return;
            }

            if (data.GetType() != Json::Type::Array || data.Length == 0) {
                log("Invalid replay data in response.", LogLevel::Error, 320, "FetchAndSaveReplay");
                return;
            }

            string fileUrl = data[0]["url"];
            string mapNameNoneSplit = data[0]["filename"];
            string mapName = mapNameNoneSplit.Split("\\")[1].Split("_")[0];
            string savePath = Server::officialJsonFilesDirectory + "/" + mapName + "_" + accountId + "_Position-" + offset + "_" + tostring(Time::Stamp) + ".Ghost.Gbx";

            auto fileReq = Net::HttpGet(fileUrl);
            if (fileReq.ResponseCode() != 200) {
                log("Failed to download replay file, response code: " + fileReq.ResponseCode(), LogLevel::Error, 331, "FetchAndSaveReplay");
                return;
            }

            _IO::File::WriteToFile(savePath, tostring(fileReq.Body));

            ProcessSelectedFile(savePath);

            log("Replay file saved to: " + savePath, LogLevel::Info, 339, "FetchAndSaveReplay");
        }
    }
}
