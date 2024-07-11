namespace OfficialManager {
    namespace DownloadingFiles {
        int64 endTimestamp = 0;

        void Init() {
            log("Initializing OfficialManager::DownloadingFiles", LogLevel::Info, 6, "Init");
            LoadEndTimestamp();
            CheckForNewCampaignIfNeeded();
        }

        void LoadEndTimestamp() {
            log("Loading end timestamp", LogLevel::Info, 12, "LoadEndTimestamp");

            string endTimestampFilePath = Server::officialInfoFilesDirectory + "/end_timestamp.txt";
            if (IO::FileExists(endTimestampFilePath)) {
                endTimestamp = Text::ParseInt64(_IO::File::ReadFileToEnd(endTimestampFilePath));

                log("Loaded endTimestamp: " + endTimestamp, LogLevel::Info, 18, "LoadEndTimestamp");
            } else {
                endTimestamp = 0;
                log("End timestamp file not found, setting endTimestamp to 0", LogLevel::Warn, 21, "LoadEndTimestamp");
            }
        }

        void SaveEndTimestamp() {
            log("Saving end timestamp", LogLevel::Info, 26, "SaveEndTimestamp");

            string endTimestampFilePath = Server::officialInfoFilesDirectory + "/end_timestamp.txt";
            string endTimestampContent = ("" + endTimestamp);

            IO::File endTimestampFile(endTimestampFilePath, IO::FileMode::Write);
            endTimestampFile.Write(endTimestampContent);
            endTimestampFile.Close();
            log("Saved endTimestamp: " + endTimestamp, LogLevel::Info, 34, "SaveEndTimestamp");
        }

        void CheckForNewCampaignIfNeeded(bool bypassCheck = false) {
            log("Checking if we need to check for new campaign", LogLevel::Info, 38, "CheckForNewCampaignIfNeeded");

            int64 currentTime = Time::Stamp;

            if (bypassCheck) { endTimestamp = 0; }
            if (currentTime >= endTimestamp) {
                log("Current time is greater than end timestamp, starting new campaign check", LogLevel::Info, 44, "CheckForNewCampaignIfNeeded");
                startnew(Coro_CheckForNewCampaign);
            } else {
                log("Current time is less than end timestamp, no need to check for new campaign", LogLevel::Info, 47, "CheckForNewCampaignIfNeeded");
            }
        }

        void Coro_CheckForNewCampaign() {
            CheckForNewCampaign();
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
                    for (uint j = 0; j < data["campaignList"].Length; j++) {
                        Json::Value campaign = data["campaignList"][j];
                        string campaignName = campaign["name"];
                        campaignName = campaignName.Replace(" ", "_");

                        if (localCampaigns.Find(campaignName) == -1) {
                            log("Downloading missing campaign: " + campaignName, LogLevel::Info, 82, "CheckForNewCampaign");
                            SaveCampaignData(campaign);
                        }

                        int64 newEndTimestamp = campaign["endTimestamp"];
                        if (newEndTimestamp > endTimestamp) {
                            endTimestamp = newEndTimestamp;
                        }
                    }
                    offset++;
                } else {
                    log("No more campaigns found at offset: " + tostring(offset), LogLevel::Info, 93, "CheckForNewCampaign");
                    continueChecking = false;
                }
            }

            SaveEndTimestamp();
        }

        void SaveCampaignData(const Json::Value &in campaign) {
            string campaignName = campaign["name"];
            log("Saving campaign data: " + campaignName, LogLevel::Info, 103, "SaveCampaignData");

            string specificSeason = campaign["name"];
            specificSeason = specificSeason.Replace(" ", "_");
            string fullFileName = Server::officialJsonFilesDirectory + "/" + specificSeason + ".json";

            _IO::File::WriteToFile(fullFileName, Json::Write(campaign));
            log("Campaign data saved to: " + fullFileName, LogLevel::Info, 110, "SaveCampaignData");
        }
    }

    namespace UI {
        void Init() {
            log("Initializing OfficialManager::UI", LogLevel::Info, 116, "Init");
            UpdateYears();
            UpdateSeasons();
            UpdateMaps();
        }

        string FetchOfficialMapUID() {
            if (selectedYear == -1 || selectedSeason == -1 || selectedMap == -1) {
                return "";
            }

            string season = seasons[selectedSeason];
            int year = years[selectedYear];
            int mapPosition = selectedMap;

            string filePath = Server::officialJsonFilesDirectory + "/" + season + "_" + tostring(year) + ".json";
            if (!IO::FileExists(filePath)) {
                log("File not found: " + filePath, LogLevel::Error, 363, "FetchOfficialMapUID");
                return "";
            }

            Json::Value root = Json::Parse(_IO::File::ReadFileToEnd(filePath));
            if (root.GetType() == Json::Type::Null) {
                log("Failed to parse JSON file: " + filePath, LogLevel::Error, 369, "FetchOfficialMapUID");
                return "";
            }

            for (uint i = 0; i < root.Length; i++) {
                auto playlist = root["playlist"];
                if (playlist.GetType() != Json::Type::Array) {
                    continue;
                }

                for (uint j = 0; j < playlist.Length; j++) {
                    auto map = playlist[j];
                    if (map["position"] == mapPosition) {
                        string mapUid = map["mapUid"];
                        return mapUid;
                    }
                }
            }

            log("Map UID not found for position: " + tostring(mapPosition), LogLevel::Error, 388, "FetchOfficialMapUID");
            return "";
        }

        void UpdateSeasons() {
            seasons.RemoveRange(0, seasons.Length);
            selectedSeason = -1;
            selectedMap = -1;
            maps.RemoveRange(0, maps.Length);

            seasons = {"Spring", "Summer", "Fall", "Winter"};
            log("Seasons updated: " + seasons.Length + " seasons", LogLevel::Info, 129, "UpdateSeasons");
        }

        void UpdateMaps() {
            maps.RemoveRange(0, maps.Length);
            selectedMap = -1;

            for (int i = 1; i <= 25; i++) {
                maps.InsertLast("Map " + tostring(i));
            }
            log("Maps updated: " + maps.Length + " maps", LogLevel::Info, 139, "UpdateMaps");
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
            log("Years populated: " + years.Length + " years", LogLevel::Info, 156, "UpdateYears");
        }

        void SetSeasonYearToCurrent() {
            int64 currentTime = Time::Stamp;

            string path = Server::officialJsonFilesDirectory;

            array<string>@ jsonFiles = IO::IndexFolder(path, true);

            for (uint i = 0; i < jsonFiles.Length; i++) {
                string filePath = jsonFiles[i];
                IO::File file(filePath, IO::FileMode::Read);
                string jsonContent = file.ReadToEnd();
                file.Close();

                Json::Value root = Json::Parse(jsonContent);

                auto latestSeasons = root["latestSeasons"];
                for (uint j = 0; j < latestSeasons.Length; j++) {
                    auto season = latestSeasons[j];
                    int64 startTimestamp = season["startTimestamp"];
                    int64 endTimestamp = season["endTimestamp"];
                    if (currentTime >= startTimestamp && currentTime <= endTimestamp) {
                        string seasonName = season["name"];
                        ParseSeasonYear(seasonName);
                        return;
                    }
                }
            }
        }

        void ParseSeasonYear(const string &in seasonName) {
            array<string> parts = seasonName.Split(" ");
            if (parts.Length == 2) {
                string season = parts[0];
                int year = Text::ParseInt(parts[1]);

                selectedSeason = season;
                selectedYear = year;
            }
        }

        void SetCurrentMapBasedOnName() {
            auto root = GetApp().RootMap;
            if (root is null) return;

            string mapName = root.MapInfo.Name;
            if (mapName.Length == 0) return;

            string pattern = "\\b([1-9]|1[0-9]|2[0-5])\\b";
            array<string> matches = Regex::Match(mapName, pattern);

            if (matches.Length > 0) {
                string mapNumberStr = matches[0];
                int mapNumber = Text::ParseInt(mapNumberStr);

                selectedMap = mapNumber;
            }
        }
    }
}