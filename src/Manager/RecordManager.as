namespace RecordManager {
    array<CGameGhostScript@> ghosts;

    void RemoveAllRecords() {
        if (GetApp().PlaygroundScript is null) return;
        
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_RemoveAll();
        log("All ghosts removed.", LogLevel::Info, 13, "RemoveAllRecords");
        GhostTracker::ClearTrackedGhosts();
    }

    void RemoveInstanceRecord(MwId instanceId) {
        if (GetApp().PlaygroundScript is null) return;

        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_Remove(instanceId);
        log("Record with the MwID of: " + instanceId.GetName() + " removed.", LogLevel::Info, 22, "RemoveInstanceRecord");
        GhostTracker::RemoveTrackedGhost(instanceId);
    }

    void RemovePBRecord() {
        if (GetApp().PlaygroundScript is null) return;

        auto dataFileMgr = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        auto newGhosts = dataFileMgr.Ghosts;

        for (uint i = 0; i < newGhosts.Length; i++) {
            CGameGhostScript@ ghost = cast<CGameGhostScript>(newGhosts[i]);
            if (ghost.Nickname == "PB") {
                RemoveInstanceRecord(ghost.Id);
                return;
            }
        }
    }

    void SetRecordDossard(MwId instanceId, const string &in dossard, vec3 color = vec3()) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_SetDossard(instanceId, dossard, color);
        log("Record dossard set.", LogLevel::Info, 44, "RemovePBRecord");
    }

    bool IsReplayVisible(MwId instanceId) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        bool isVisible = gm.Ghost_IsVisible(instanceId);
        return isVisible;
    }

    bool IsReplayOver(MwId instanceId) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        bool isOver = gm.Ghost_IsReplayOver(instanceId);
        return isOver;
    }

    void AddGhostWithOffset(CGameGhostScript@ ghost, const int &in offset) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_Add(ghost, true, offset);
        log("Ghost added with offset.", LogLevel::Info, 62, "AddGhostWithOffset");
        GhostTracker::AddTrackedGhost(ghost);
    }

    string GetGhostNameById(MwId id) {
        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Id.Value == id.Value) {
                return ghosts[i].Nickname;
            }
        }
        return "";
    }

    string GetGhostInfo(MwId id) {
        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Id.Value == id.Value) {
                auto ghost = ghosts[i];
                return "Nickname: " + ghost.Nickname + "\n"
                       + "Trigram: " + ghost.Trigram + "\n"
                       + "Country Path: " + ghost.CountryPath + "\n"
                       + "Time: " + ghost.Result.Time + "\n"
                       + "Stunt Score: " + ghost.Result.Score + "\n"
                       + "MwId: " + ghost.Id.Value + "\n";
            }
        }
        return "No ghost selected.";
    }

    namespace GhostTracker {
        array<CGameGhostScript@> trackedGhosts;
        array<MwId> removedGhosts;

        void Init() {
            log("Initializing GhostTracker", LogLevel::Info, 95, "Init");
            UpdateGhosts();
        }

        void UpdateGhosts() {
            auto app = GetApp();
            if (app is null || app.Network is null || app.Network.ClientManiaAppPlayground is null) {
                log("App or network components not ready", LogLevel::Warn, 102, "UpdateGhosts");
                return;
            }

            auto dataFileMgr = app.Network.ClientManiaAppPlayground.DataFileMgr;
            auto newGhosts = dataFileMgr.Ghosts;
            ghosts.RemoveRange(0, ghosts.Length);

            for (uint i = 0; i < newGhosts.Length; i++) {
                CGameGhostScript@ ghost = cast<CGameGhostScript>(newGhosts[i]);
                if (!IsGhostRemoved(ghost.Id) && !IsGhostTracked(ghost.Id)) {
                    ghosts.InsertLast(ghost);
                    AddTrackedGhost(ghost);
                }
            }

            int totalGhosts = ghosts.Length;
            int ghostsWithNickname = 0;
            int ghostsWithoutNickname = 0;

            for (uint i = 0; i < ghosts.Length; i++) {
                if (ghosts[i].Nickname == "cfa844b7-6b53-4663-ac0d-9bdd3ad1af22") {
                    ghostsWithNickname++;
                } else {
                    ghostsWithoutNickname++;
                }
            }

            log("Ghosts updated, count: " + ghosts.Length + " Normal Ghosts: " + ghostsWithoutNickname + " VTable Ghosts: " + ghostsWithNickname, LogLevel::Info, 130, "UpdateGhosts");
        }

        void AddTrackedGhost(CGameGhostScript@ ghost) {
            if (!IsGhostTracked(ghost.Id)) {
                trackedGhosts.InsertLast(ghost);

                if (ghost.Nickname == "cfa844b7-6b53-4663-ac0d-9bdd3ad1af22") return;
                log("Tracked ghost added: " + ghost.Nickname, LogLevel::Info, 138, "AddTrackedGhost");
            }
        }

        void RemoveTrackedGhost(MwId instanceId) {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                if (trackedGhosts[i].Id.Value == instanceId.Value) {
                    log("Tracked ghost removed: " + trackedGhosts[i].Nickname, LogLevel::Info, 145, "RemoveTrackedGhost");
                    trackedGhosts.RemoveAt(i);
                    removedGhosts.InsertLast(instanceId);
                    return;
                }
            }
        }

        void ClearTrackedGhosts() {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                
            }
            trackedGhosts.RemoveRange(0, trackedGhosts.Length);
            log("Cleared all tracked ghosts.", LogLevel::Info, 158, "ClearTrackedGhosts");
        }

        bool IsGhostRemoved(MwId id) {
            for (uint i = 0; i < removedGhosts.Length; i++) {
                if (removedGhosts[i].Value == id.Value) {
                    return true;
                }
            }
            return false;
        }

        bool IsGhostTracked(MwId id) {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                if (trackedGhosts[i].Id.Value == id.Value) {
                    return true;
                }
            }
            return false;
        }

        string GetTrackedGhostNameById(MwId id) {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                if (trackedGhosts[i].Id.Value == id.Value) {
                    return trackedGhosts[i].Nickname;
                }
            }
            return "";
        }

        string GetTrackedGhostInfo(MwId id) {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                if (trackedGhosts[i].Id.Value == id.Value) {
                    auto ghost = trackedGhosts[i];
                    return "Nickname: " + ghost.Nickname + "\n"
                           + "Trigram: " + ghost.Trigram + "\n"
                           + "Country Path: " + ghost.CountryPath + "\n"
                           + "Time: " + ghost.Result.Time + "\n"
                           + "Stunt Score: " + ghost.Result.Score + "\n"
                           + "MwId: " + ghost.Id.Value + "\n";
                }
            }
            return "No ghost selected.";
        }

        void RefreshTrackedGhosts() {
            trackedGhosts.RemoveRange(0, trackedGhosts.Length);
            UpdateGhosts();
        }
    }

    namespace Save {
        void SaveRecord() {
            if (selectedRecordID.Value == MwId().Value) { NotifyError("No ghost selected to save."); return; }

            CGameGhostScript@ ghost = GetTrackedGhostById(selectedRecordID);
            if (ghost is null) { NotifyError("Selected ghost not found."); return; }

            string timeStamp = Time::FormatString("%Y-%m-%d-%H-%M-%S", Time::Stamp);
            string fileName = ghost.Id.Value + "_" + ghost.Nickname + "_" + ghost.Result.Time + "_" + timeStamp;
            fileName = fileName.Replace(" ", "-").Replace(":", "-");
            string tmpFilePath = Server::replayARLTmp + fileName + ".Replay.Gbx";

            string replayFilePath = Server::savedFilesDirectory;
            string jsonFilePath = Server::savedJsonDirectory + fileName + ".json";

            log("Saving ghost to file: " + replayFilePath, LogLevel::Info, 224, "SaveRecord");

            auto app = GetApp();
            if (app is null || app.Network is null || app.Network.ClientManiaAppPlayground is null) { NotifyError("App or network components not ready."); return; }
            auto rootMap = cast<CGameCtnChallenge@>(app.RootMap);
            if (rootMap is null) { NotifyError("RootMap is not a valid CGameCtnChallenge."); return; }

            CWebServicesTaskResult@ saveResult = app.Network.ClientManiaAppPlayground.DataFileMgr.Replay_Save(tmpFilePath, rootMap, ghost);
            if (saveResult.HasSucceeded && !saveResult.HasFailed) {
                log("Replay save successful", LogLevel::Info, 233, "SaveRecord");

                string _uuid = CreateRandomUuid();
                Json::Value json = Json::Object();
                json["content"] = Json::Object();
                json["content"]["ID"] = _uuid;
                json["content"]["FileName"] = fileName;
                json["content"]["FullFilePath"] = replayFilePath + fileName + ".Replay.Gbx";
                json["content"]["FromLocalFile"] = true;
                json["content"]["ReplayFilePath"] = replayFilePath;
                json["content"]["Nickname"] = ghost.Nickname;
                json["content"]["Trigram"] = ghost.Trigram;
                json["content"]["CountryPath"] = ghost.CountryPath;
                json["content"]["Time"] = ghost.Result.Time;
                json["content"]["StuntScore"] = ghost.Result.Score;
                json["content"]["MwId Value"] = ghost.Id.Value;

                _IO::File::WriteFile(jsonFilePath, Json::Write(json, true));

                string replayFileData = _IO::File::ReadFileToEnd(tmpFilePath);
                _IO::File::WriteFile(Server::savedFilesDirectory + fileName + ".Replay.Gbx", replayFileData);
                IO::Delete(tmpFilePath);

                NotifyInfo("Ghost saved successfully.");
            } else {
                log("Replay save failed: " + saveResult.ErrorDescription, LogLevel::Error, 258, "SaveRecord");
                NotifyError("Failed to save ghost replay.");
            }
        }

        string CreateRandomUuid() {
            string uuid = "";
            for (int i = 0; i < 32; i++) {
                uuid += tostring(Math::Rand(0, 9) % 10);
            }
            return uuid;
        }

        CGameGhostScript@ GetTrackedGhostById(MwId id) {
            for (uint i = 0; i < GhostTracker::trackedGhosts.Length; i++) {
                if (GhostTracker::trackedGhosts[i].Id.Value == id.Value) {
                    return GhostTracker::trackedGhosts[i];
                }
            }
            return null;
        }

        void SaveRecordByPath(const string &in overwritePath) {
            

        }
    }
}

















void ProcessSelectedFile(const string &in filePath) {
    startnew(CoroutineFuncUserdataString(Coro_ProcessSelectedFile), filePath);
}

void Coro_ProcessSelectedFile(const string &in filePath) {
    if (filePath.StartsWith("https://") || filePath.StartsWith("http://") || filePath.Contains("trackmania.io") || filePath.Contains("trackmania.exchange") || filePath.Contains("www.")) {
        _Net::DownloadFileToDestination(filePath, Server::linksFilesDirectory + Path::GetFileName(filePath), "Link");
        startnew(CoroutineFuncUserdataString(ProcessDownloadedFile), "Link");
        return;
    }

    string fileExt = Path::GetExtension(filePath).ToLower();

    if (fileExt == ".gbx") {
        string properFileExtension = Path::GetExtension(filePath).ToLower();
        if (properFileExtension == ".gbx") {
            int secondLastDotIndex = _Text::NthLastIndexOf(filePath, ".", 2);
            int lastDotIndex = filePath.LastIndexOf(".");
            if (secondLastDotIndex != -1 && lastDotIndex > secondLastDotIndex) {
                properFileExtension = filePath.SubStr(secondLastDotIndex + 1, lastDotIndex - secondLastDotIndex - 1);
            }
        }
        fileExt = properFileExtension.ToLower();
    }

    while (!AllowCheck::ConditionCheckMet()) { yield(); }

    if (!AllowCheck::AllowdToLoadRecords()) {
        NotifyWarn("Error | Not allowed to load records due to either map comment, or current game mode.");
        return;
    }

    if (fileExt == "replay") {
        ReplayLoader::LoadReplayFromPath(filePath);
    } else if (fileExt == "ghost") {
        GhostLoader::LoadGhost(filePath);
    } else {
        log("Unsupported file type: " + fileExt + " " + "Full path: " + filePath, LogLevel::Error, 340, "Coro_ProcessSelectedFile");
        NotifyWarn("Error | Unsupported file type.");
    }
}

void ProcessDownloadedFile(const string &in key) {
    while (!_Net::downloadedFilePaths.Exists(key)) { yield(); }

    string finalFilePath = string(_Net::downloadedFilePaths[key]);
    _Net::downloadedFilePaths.Delete(key);
    while (!IO::FileExists(finalFilePath)) { yield(); }

    ProcessSelectedFile(finalFilePath);
}

















namespace LoadRecordFromArbitraryMap {
    string accountId;
    string mapId;

    string globalMapUid;
    string globalOffset;
    string globalSaveLocation = Server::serverDirectoryAutoMove;

    string specialSaveLocation = "";

    bool mapIdFetched = false;
    bool accountIdFetched = false;

    void LoadSelectedRecord(const string &in mapUid, const string &in offset, const string &in _specialSaveLocation, const string &in _accountId = "", const string &in _mapId = "") {
        // if (_accountId.Length != 0) { accountId = _accountId; }
        // if (_mapId.Length != 0) { mapId = _mapId; }
        
        globalMapUid = mapUid;
        globalOffset = offset;
        specialSaveLocation = _specialSaveLocation;
        startnew(Coro_LoadSelectedGhost);
    }

    void Coro_LoadSelectedGhost() {
        if (globalMapUid.Length == 0) { log("Map UID not provided.", LogLevel::Error, 395, "Coro_LoadSelectedGhost"); return; }
        if (globalOffset.Length == 0) { log("Offset not provided.", LogLevel::Error, 396, "Coro_LoadSelectedGhost"); return; }

        accountIdFetched = false;
        mapIdFetched = false;

        startnew(Coro_FetchAccountId);
        startnew(Coro_FetchMapId);

        while (!(accountIdFetched && mapIdFetched)) { yield(); }

        if (accountId.Length == 0) { log("Account ID not found.", LogLevel::Error, 406, "Coro_LoadSelectedGhost"); return; }
        if (mapId.Length == 0) { log("Map ID not found.", LogLevel::Error, 407, "Coro_LoadSelectedGhost"); return; }

        SaveReplay(mapId, accountId, globalOffset, specialSaveLocation);
    }

    void Coro_FetchAccountId() {
        // if (accountId.Length > 0) { log("AccountId provided in LoadSelectedRevord", LogLevel::Info, 413, "Coro_FetchAccountId"); accountIdFetched = true; return; }

        accountIdFetched = false;

        string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + globalMapUid + "/top?onlyWorld=true&length=1&offset=" + globalOffset;
        auto req = NadeoServices::Get("NadeoLiveServices", url);

        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) {
            log("Failed to fetch account ID, response code: " + req.ResponseCode(), LogLevel::Error, 425, "Coro_FetchAccountId");
            accountId = "";
        } else {
            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for account ID.", LogLevel::Error, 430, "Coro_FetchAccountId");
                accountId = "";
            } else {
                auto tops = data["tops"];
                if (tops.GetType() != Json::Type::Array || tops.Length == 0) {
                    log("Invalid tops data in response.", LogLevel::Error, 435, "Coro_FetchAccountId");
                    accountId = "";
                } else {
                    auto top = tops[0]["top"];
                    if (top.GetType() != Json::Type::Array || top.Length == 0) {
                        log("Invalid top data in response.", LogLevel::Error, 440, "Coro_FetchAccountId");
                        accountId = "";
                    } else {
                        accountId = top[0]["accountId"];
                        log("Found account ID: " + accountId, LogLevel::Info, 444, "Coro_FetchAccountId");
                    }
                }
            }
        }
        accountIdFetched = true;
    }

    void Coro_FetchMapId() {
        // if (mapId.Length > 0) { log("MapId provided in LoadSelectedRevord", LogLevel::Info, 453, "Coro_FetchMapId"); mapIdFetched = true; return; }

        mapIdFetched = false;
        string url = "https://prod.trackmania.core.nadeo.online/maps/?mapUidList=" + globalMapUid;
        auto req = NadeoServices::Get("NadeoServices", url);

        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) {
            log("Failed to fetch map ID, response code: " + req.ResponseCode(), LogLevel::Error, 464, "Coro_FetchMapId");
            mapId = "";
        } else {
            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for map ID.", LogLevel::Error, 469, "Coro_FetchMapId");
                mapId = "";
            } else {
                if (data.GetType() != Json::Type::Array || data.Length == 0) {
                    log("Invalid map data in response.", LogLevel::Error, 473, "Coro_FetchMapId");
                    mapId = "";
                } else {
                    mapId = data[0]["mapId"];
                    log("Found map ID: " + mapId, LogLevel::Info, 477, "Coro_FetchMapId");
                }
            }
        }
        mapIdFetched = true;
    }

    void SaveReplay(const string &in mapId, const string &in accountId, const string &in offset, const string &in saveLocation = "") {
        string url = "https://prod.trackmania.core.nadeo.online/v2/mapRecords/?accountIdList=" + accountId + "&mapId=" + mapId;
        auto req = NadeoServices::Get("NadeoServices", url);

        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) { log("Failed to fetch replay record, response code: " + req.ResponseCode(), LogLevel::Error, 492, "SaveReplay"); return; }

        Json::Value data = Json::Parse(req.String());
        if (data.GetType() == Json::Type::Null) { log("Failed to parse response for replay record.", LogLevel::Error, 495, "SaveReplay"); return; }
        if (data.GetType() != Json::Type::Array || data.Length == 0) { log("Invalid replay data in response.", LogLevel::Error, 496, "SaveReplay"); return; }

        string fileUrl = data[0]["url"];

        string savePath = "";

               if (saveLocation == "Official") {  savePath = Server::officialFilesDirectory +           "Official_" +  globalMapUid + "_Position" + offset + "_" + accountId + "_" + tostring(Time::Stamp) + ".Ghost.Gbx";
        } else if (saveLocation == "GPS") {       savePath = Server::currentMapRecordsGPS +             "GPS_" +       globalMapUid + "_Position" + offset + "_" + accountId + "_" + tostring(Time::Stamp) + ".Replay.Gbx";
        } else if (saveLocation == "AnyMap") {    savePath = Server::serverDirectoryAutoMove +          "AnyMap_" +    globalMapUid + "_Position" + offset + "_" + accountId + "_" + tostring(Time::Stamp) + ".Ghost.Gbx";
        } else if (saveLocation == "OtherMaps") { savePath = Server::specificDownloadedFilesDirectory + "OtherMaps_" + globalMapUid + "_Position" + offset + "_" + accountId + "_" + tostring(Time::Stamp) + ".Ghost.Gbx";
        } else if (saveLocation == "Medal") {     savePath = Server::serverDirectoryMedal +             "Medal_" +     globalMapUid + "_Position" + offset + "_" + accountId + "_" + tostring(Time::Stamp) + ".Ghost.Gbx";
        } else if (saveLocation == "") {          savePath = Server::savedFilesDirectory +              "AutoMove_" +  globalMapUid + "_Position" + offset + "_" + accountId + "_" + tostring(Time::Stamp) + ".Replay.Gbx";
        }

        auto fileReq = NadeoServices::Get("NadeoServices", fileUrl);

        fileReq.Start();

        while (!fileReq.Finished()) { yield(); }

        if (fileReq.ResponseCode() != 200) { log("Failed to download replay file, response code: " + fileReq.ResponseCode(), LogLevel::Error, 516, "SaveReplay"); return; }

        fileReq.SaveToFile(savePath);

        ProcessSelectedFile(savePath);

        log(savePath.ToLower().EndsWith(".replay.gbx") ? "Replay" : "Ghost" + " file saved to: " + savePath, LogLevel::Info, 522, "SaveReplay");
    }
}
