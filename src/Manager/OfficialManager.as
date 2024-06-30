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

            
            startnew(Coro_CheckForNewCampaign); // IMPORTANT: Temporarily moved outside of the check for testing, move back on release
            if (timeSinceLastCheck >= eightyEightDaysInSeconds || timeSinceLastCheck >= threeDaysInSeconds) {
                log("Time since last check is greater than interval, starting new campaign check", LogLevel::Info, 71, "CheckForNewCampaignIfNeeded");
            } else {
                log("Time since last check is less than interval, no need to check for new campaign", LogLevel::Info, 73, "CheckForNewCampaignIfNeeded");
            }
        }

        void Coro_CheckForNewCampaign() {
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
                            log("Downloading missing campaign: " + campaignName, LogLevel::Info, 109, "CheckForNewCampaign");
                            SaveCampaignData(campaign);
                            continueChecking = true;
                        }
                    }
                    offset++;
                } else {
                    log("No more campaigns found at offset: " + tostring(offset), LogLevel::Info, 116, "CheckForNewCampaign");
                    continueChecking = false;
                }
            }

            Json::Value latestCampaignData = api.GetOfficialCampaign(0);
            if (latestCampaignData.HasKey("campaignList") && latestCampaignData["campaignList"].Length > 0) {
                Json::Value newestCampaign = latestCampaignData["campaignList"][0];
                string newestCampaignName = newestCampaign["name"];
                newestCampaignName = newestCampaignName.Replace(" ", "_");
                if (localCampaigns.Find(newestCampaignName) == -1) {
                    log("Downloading the latest campaign: " + newestCampaignName, LogLevel::Info, 127, "CheckForNewCampaign");
                    SaveCampaignData(newestCampaign);
                }
            }
        }

        void SaveCampaignData(const Json::Value &in campaign) {
            string campaignName = campaign["name"];
            log("Saving campaign data: " + campaignName, LogLevel::Info, 135, "SaveCampaignData");

            string specificSeason = campaign["name"];
            specificSeason = specificSeason.Replace(" ", "_");
            string fileName = Server::officialJsonFilesDirectory + "/" + specificSeason + ".json";

            IO::File file(fileName, IO::FileMode::Write);
            file.Write(Json::Write(campaign));
            file.Close();
            log("Campaign data saved to: " + fileName, LogLevel::Info, 144, "SaveCampaignData");
        }
    }

    namespace UI {
        void Init() {
            log("Initializing OfficialManager::UI", LogLevel::Info, 150, "Init");
            UpdateYears();
            UpdateSeasons();
            UpdateMaps();
        }

        void UpdateSeasons() {
            seasons.RemoveRange(0, seasons.Length);
            selectedSeason = -1;
            selectedMap = -1;
            maps.RemoveRange(0, maps.Length);

            seasons = {"Spring", "Summer", "Fall", "Winter"};
            log("Seasons updated: " + seasons.Length + " seasons", LogLevel::Info, 163, "UpdateSeasons");
        }

        void UpdateMaps() {
            maps.RemoveRange(0, maps.Length);
            selectedMap = -1;

            for (int i = 1; i <= 25; i++) {
                maps.InsertLast("Map " + tostring(i));
            }
            log("Maps updated: " + maps.Length + " maps", LogLevel::Info, 173, "UpdateMaps");
        }

        void UpdateYears() {
            years.RemoveRange(0, years.Length);
            selectedYear = -1;
            selectedSeason = -1;
            selectedMap = -1;
            maps.RemoveRange(0, maps.Length);
            seasons.RemoveRange(0, seasons.Length);

            Time::Info info = Time::Parse();
            int currentYear = info.Year;

            for (int y = 2020; y <= currentYear; y++) {
                years.InsertLast(y);
            }
            log("Years populated: " + years.Length + " years", LogLevel::Info, 190, "UpdateYears");
        }
    }
 
    namespace HandlingUserInput {
        string mapUid;
        string accountId;
        string mapId;
        string offset;

        bool mapIdFetched = false;
        bool accountIdFetched = false;

        void LoadSelectedRecord() {
            startnew(Coro_LoadSelectedGhost);
        }

        void Coro_LoadSelectedGhost() {
            offset = selectedOffset;
            if (offset.Length == 0) {
                log("Offset not provided.", LogLevel::Error, 211, "Coro_LoadSelectedGhost");
                return;
            }

            mapUid = FetchMapUID();
            
            startnew(Async_FetchAccountId);
            startnew(Async_FetchMapId);

            while (!(accountIdFetched && mapIdFetched)) { yield(); }

            if (mapUid.Length == 0) {
                log("Map UID not found.", LogLevel::Error, 227, "Coro_LoadSelectedGhost");
                return;
            }
            if (accountId.Length == 0) {
                log("Account ID not found.", LogLevel::Error, 231, "Coro_LoadSelectedGhost");
                return;
            }
            if (mapId.Length == 0) {
                log("Map ID not found.", LogLevel::Error, 235, "Coro_LoadSelectedGhost");
                return;
            }

            SaveReplay(mapId, accountId, offset);
        }

        string FetchMapUID() {
            if (selectedYear == -1 || selectedSeason == -1 || selectedMap == -1) {
                // log("Year, season, or map not selected.", LogLevel::Warn, 244, "FetchMapUID");
                return "";
            }

            string season = seasons[selectedSeason];
            int year = years[selectedYear];
            int mapPosition = selectedMap;

            string filePath = Server::officialJsonFilesDirectory + "/" + season + "_" + tostring(year) + ".json";
            if (!IO::FileExists(filePath)) { log("File not found: " + filePath, LogLevel::Error, 253, "FetchMapUID"); return ""; }

            Json::Value root = Json::Parse(_IO::File::ReadFileToEnd(filePath));
            if (root.GetType() == Json::Type::Null) { log("Failed to parse JSON file: " + filePath, LogLevel::Error, 256, "FetchMapUID"); return ""; }


            for (uint i = 0; i < root.Length; i++) {
                auto playlist = root["playlist"];
                if (playlist.GetType() != Json::Type::Array) {
                    continue;
                }

                for (uint j = 0; j < playlist.Length; j++) {
                    auto map = playlist[j];
                    if (map["position"] == mapPosition) {
                        string mapUid = map["mapUid"];
                        // log("Found map UID: " + mapUid, LogLevel::Info, 269, "FetchMapUID");
                        return mapUid;
                    }
                }
            }

            log("Map UID not found for position: " + tostring(mapPosition), LogLevel::Error, 275, "FetchMapUID");
            return "";
        }

        void Async_FetchAccountId() {
            accountIdFetched = false;
            startnew(Coro_FetchAccountId);
        }

        void Coro_FetchAccountId() {
            mapUID = FetchMapUID();

            string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?onlyWorld=true&length=1&offset=" + offset;
            auto req = NadeoServices::Get("NadeoLiveServices", url);

            req.Start();

            while (!req.Finished()) { yield(); }

            if (req.ResponseCode() != 200) {
                log("Failed to fetch account ID, response code: " + req.ResponseCode(), LogLevel::Error, 297, "Coro_FetchAccountId");
                accountId = "";
            } else {
                string jsonStr = Json::Write(req.Json());

                Json::Value data = Json::Parse(jsonStr);
                if (data.GetType() == Json::Type::Null) {
                    log("Failed to parse response for account ID.", LogLevel::Error, 304, "Coro_FetchAccountId");
                    accountId = "";
                } else {
                    auto tops = data["tops"];
                    if (tops.GetType() != Json::Type::Array || tops.Length == 0) {
                        log("Invalid tops data in response.", LogLevel::Error, 309, "Coro_FetchAccountId");
                        accountId = "";
                    } else {
                        auto top = tops[0]["top"];
                        if (top.GetType() != Json::Type::Array || top.Length == 0) {
                            log("Invalid top data in response.", LogLevel::Error, 314, "Coro_FetchAccountId");
                            accountId = "";
                        } else {
                            accountId = top[0]["accountId"];
                            log("Found account ID: " + accountId, LogLevel::Info, 318, "Coro_FetchAccountId");
                        }
                    }
                }
            }
            accountIdFetched = true;
        }

        void Async_FetchMapId() {
            mapIdFetched = false;
            startnew(Coro_FetchMapId);
        }

        void Coro_FetchMapId() {
            string url = "https://prod.trackmania.core.nadeo.online/maps/?mapUidList=" + mapUid;
            auto req = NadeoServices::Get("NadeoServices", url);

            req.Start();

            while (!req.Finished()) { yield(); }

            if (req.ResponseCode() != 200) {
                log("Failed to fetch map ID, response code: " + req.ResponseCode(), LogLevel::Error, 342, "Coro_FetchMapId");
                mapId = "";
            } else {
                Json::Value data = Json::Parse(req.String());
                if (data.GetType() == Json::Type::Null) {
                    log("Failed to parse response for map ID.", LogLevel::Error, 347, "Coro_FetchMapId");
                    mapId = "";
                } else {
                    if (data.GetType() != Json::Type::Array || data.Length == 0) {
                        log("Invalid map data in response.", LogLevel::Error, 351, "Coro_FetchMapId");
                        mapId = "";
                    } else {
                        mapId = data[0]["mapId"];
                        log("Found map ID: " + mapId, LogLevel::Info, 355, "Coro_FetchMapId");
                    }
                }
            }
            mapIdFetched = true;
        }

        string FetchAccountId(const string &in mapUid, uint offset) {
            string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?onlyWorld=true&length=1&offset=" + tostring(offset);
            auto req = NadeoServices::Get("NadeoLiveServices", url);

            req.Start();

            while (!req.Finished()) { yield(); }

            if (req.ResponseCode() != 200) { log("Failed to fetch account ID, response code: " + req.ResponseCode(), LogLevel::Error, 373, "FetchAccountId"); return ""; }

            Json::Value data = Json::Parse(tostring(req));
            if (data.GetType() == Json::Type::Null) { log("Failed to parse response for account ID.", LogLevel::Error, 379, "FetchAccountId"); return ""; }
            
            auto tops = data["tops"];
            if (tops.GetType() != Json::Type::Array || tops.Length == 0) { log("Invalid tops data in response.", LogLevel::Error, 385, "FetchAccountId"); return ""; }
            
            auto top = tops[0]["top"];
            if (top.GetType() != Json::Type::Array || top.Length == 0) { log("Invalid top data in response.", LogLevel::Error, 391, "FetchAccountId"); return ""; }

            string accountId = top[0]["accountId"];
            log("Found account ID: " + accountId, LogLevel::Info, 396, "FetchAccountId");
            return accountId;
        }

        string FetchMapId(const string &in mapUid) {
            string url = "https://prod.trackmania.core.nadeo.online/maps/?mapUidList=" + mapUid;
            auto req = NadeoServices::Get("NadeoLiveServices", url);

            req.Start();
            
            while (!req.Finished()) { yield(); }

            if (req.ResponseCode() != 200) { log("Failed to fetch map ID, response code: " + req.ResponseCode(), LogLevel::Error, 411, "FetchMapId"); return ""; }

            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) { log("Failed to parse response for map ID.", LogLevel::Error, 417, "FetchMapId"); return ""; }

            if (data.GetType() != Json::Type::Array || data.Length == 0) { log("Invalid map data in response.", LogLevel::Error, 422, "FetchMapId"); return ""; }

            string mapId = data[0]["mapId"];
            log("Found map ID: " + mapId, LogLevel::Info, 427, "FetchMapId");
            return mapId;
        }

        void SaveReplay(const string &in mapId, const string &in accountId, const string &in offset) {
            string url = "https://prod.trackmania.core.nadeo.online/mapRecords/?accountIdList=" + accountId + "&mapIdList=" + mapId;
            auto req = NadeoServices::Get("NadeoServices", url);

            req.Start();
            
            while (!req.Finished()) { yield(); }

            if (req.ResponseCode() != 200) { log("Failed to fetch replay record, response code: " + req.ResponseCode(), LogLevel::Error, 442, "SaveReplay"); return; }

            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for replay record.", LogLevel::Error, 450, "SaveReplay");
                return;
            }

            if (data.GetType() != Json::Type::Array || data.Length == 0) {
                log("Invalid replay data in response.", LogLevel::Error, 455, "SaveReplay");
                return;
            }

            string fileUrl = data[0]["url"];
            string mapName = years[selectedYear] + "-" + seasons[selectedSeason] + "-" + maps[selectedMap].Replace(" ", "");
            string savePath = Server::officialFilesDirectory + "/" + "Official_" + mapName + "_Position" + offset + "_" + accountId + "_" + tostring(Time::Stamp) + ".Ghost.Gbx";

            auto fileReq = NadeoServices::Get("NadeoServices", fileUrl);

            fileReq.Start();
            
            while (!fileReq.Finished()) { yield(); }

            
            if (fileReq.ResponseCode() != 200) {
                log("Failed to download replay file, response code: " + fileReq.ResponseCode(), LogLevel::Error, 475, "SaveReplay");
                return;
            }

            fileReq.SaveToFile(savePath);

            ProcessSelectedFile(savePath);

            log("Replay file saved to: " + savePath, LogLevel::Info, 483, "SaveReplay");
        }

    }
}

// xdd, saving a set of maps that is automagically updated by the API whilst still fetching records etc proved to be a bit more challenging than I thought it would be :D