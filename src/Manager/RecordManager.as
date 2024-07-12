namespace RecordManager {
    array<CGameGhostScript@> ghosts;

    void OpenGhostFileDialogWindow() {
        _IO::FileExplorer::OpenFileExplorer(true, IO::FromUserGameFolder("Replays/"), "", { "replay", "ghost" });
    }

    void RemoveAllRecords() {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_RemoveAll();
        log("All ghosts removed.", LogLevel::Info, 9, "RemoveAllRecords");
        GhostTracker::ClearTrackedGhosts();
    }

    void RemoveInstanceRecord(MwId instanceId) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_Remove(instanceId);
        log("Record with the MwID of: " + instanceId.GetName() + " removed.", LogLevel::Info, 15, "RemoveInstanceRecord");
        GhostTracker::RemoveTrackedGhost(instanceId);
    }

    void SetRecordDossard(MwId instanceId, const string &in dossard, vec3 color = vec3()) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_SetDossard(instanceId, dossard, color);
        log("Record dossard set.", LogLevel::Info, 21, "SetRecordDossard");
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
        log("Ghost added with offset.", LogLevel::Info, 21, "AddGhostWithOffset");
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

        void Init() {
            log("Initializing GhostTracker", LogLevel::Info);
            UpdateGhosts();
        }

        void UpdateGhosts() {
            auto app = GetApp();
            if (app is null || app.Network is null || app.Network.ClientManiaAppPlayground is null) {
                log("App or network components not ready", LogLevel::Info);
                return;
            }

            auto dataFileMgr = app.Network.ClientManiaAppPlayground.DataFileMgr;
            auto newGhosts = dataFileMgr.Ghosts;
            ghosts.RemoveRange(0, ghosts.Length);

            for (uint i = 0; i < newGhosts.Length; i++) {
                CGameGhostScript@ ghost = cast<CGameGhostScript>(newGhosts[i]);
                ghosts.InsertLast(ghost);
                AddTrackedGhost(ghost);
            }
            log("Ghosts updated, count: " + ghosts.Length, LogLevel::Info);
        }

        void AddTrackedGhost(CGameGhostScript@ ghost) {
            trackedGhosts.InsertLast(ghost);
            log("Tracked ghost added: " + ghost.Nickname, LogLevel::Info);
        }

        void RemoveTrackedGhost(MwId instanceId) {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                if (trackedGhosts[i].Id.Value == instanceId.Value) {
                    log("Tracked ghost removed: " + trackedGhosts[i].Nickname, LogLevel::Info);
                    trackedGhosts.RemoveAt(i);
                    return;
                }
            }
        }

        void ClearTrackedGhosts() {
            trackedGhosts.RemoveRange(0, trackedGhosts.Length);
            log("Cleared all tracked ghosts.", LogLevel::Info);
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
    }

    namespace Save {
        void SaveRecord() {
            if (selectedRecordID.Value == MwId().Value) { NotifyError("No ghost selected to save."); return; }

            CGameGhostScript@ ghost = GetTrackedGhostById(selectedRecordID);
            if (ghost is null) { NotifyError("Selected ghost not found."); return; }

            string timeStamp = Time::FormatString("yyyyMMdd_HHmmss", Time::Stamp);
            string fileName = ghost.Id.Value + "_" + ghost.Nickname + "_" + ghost.Result.Time + "_" + timeStamp;
            fileName = fileName.Replace(" ", "-").Replace(":", "_");

            string replayFilePath = Server::savedFilesDirectory + fileName + ".Replay.Gbx";
            string jsonFilePath = Server::savedJsonDirectory + fileName + ".json";

            log("Saving ghost to file: " + replayFilePath, LogLevel::Info, 11, "SaveRecordPath");

            auto app = GetApp();
            if (app is null || app.Network is null || app.Network.ClientManiaAppPlayground is null) { NotifyError("App or network components not ready."); return; }
            auto playground = cast<CGameCtnChallenge@>(app.RootMap);
            if (playground is null) { NotifyError("RootMap is not a valid CGameCtnChallenge."); return; }

            CWebServicesTaskResult@ saveResult = app.Network.ClientManiaAppPlayground.DataFileMgr.Replay_Save(wstring(replayFilePath), playground, ghost);
            if (saveResult.HasSucceeded && !saveResult.HasFailed) {
                log("Replay save successful", LogLevel::Info);

                int ID = Math::Rand(0, 999999999);
                Json::Value json = Json::Object();
                json["content"] = Json::Object();
                json["content"]["ID"] = ID;
                json["content"]["FileName"] = fileName;
                json["content"]["FromLocalFile"] = true;
                json["content"]["ReplayFilePath"] = replayFilePath;
                json["content"]["Nickname"] = ghost.Nickname;
                json["content"]["Trigram"] = ghost.Trigram;
                json["content"]["CountryPath"] = ghost.CountryPath;
                json["content"]["Time"] = ghost.Result.Time;
                json["content"]["StuntScore"] = ghost.Result.Score;
                json["content"]["MwId"] = ghost.Id.Value;

                _IO::File::WriteJsonToFile(jsonFilePath, json);

                NotifyInfo("Ghost saved successfully.");
            } else {
                log("Replay save failed: " + saveResult.ErrorDescription, LogLevel::Error);
                NotifyError("Failed to save ghost replay.");
            }
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
    if (filePath.StartsWith("https://") || filePath.StartsWith("http://")) {
        _Net::DownloadFileToDestination(filePath, Server::specificDownloadedFilesDirectory + _IO::File::GetFileName(filePath));
        return;
    }

    string fileExt = _IO::File::GetFileExtension(filePath).ToLower();

    if (fileExt == "gbx") {
        string properFileExtension = _IO::File::GetFileExtension(filePath).ToLower();
        if (properFileExtension == "gbx") {
            int secondLastDotIndex = _Text::NthLastIndexOf(filePath, ".", 2);
            int lastDotIndex = _Text::LastIndexOf(filePath, ".");
            if (secondLastDotIndex != -1 && lastDotIndex > secondLastDotIndex) {
                properFileExtension = filePath.SubStr(secondLastDotIndex + 1, lastDotIndex - secondLastDotIndex - 1);
            }
        }
        fileExt = properFileExtension.ToLower();
    }

    if (fileExt == "replay") {
        ReplayLoader::LoadReplayFromPath(filePath);
    } else if (fileExt == "ghost") {
        GhostLoader::LoadGhost(filePath);
    } else {
        log("Unsupported file type: " + fileExt + " " + "Full path: " + filePath, LogLevel::Error, 44, "ProcessSelectedFile");
        NotifyWarn("Error | Unsupported file type.");
    }
}





namespace LoadRecordFromArbitraryMap {
    string accountId;
    string mapId;

    string globalMapUid;
    string globalOffset;

    bool mapIdFetched = false;
    bool accountIdFetched = false;

    void LoadSelectedRecord(const string &in mapUid, const string &in offset, const string &in _accountId = "", const string &in _mapId = "") {
        // if (_accountId.Length != 0) { accountId = _accountId; }
        // if (_mapId.Length != 0) { mapId = _mapId; }
        
        globalMapUid = mapUid;
        globalOffset = offset;
        startnew(Coro_LoadSelectedGhost);
    }

    void Coro_LoadSelectedGhost() {
        if (globalMapUid.Length == 0) { log("Map UID not provided.", LogLevel::Error, 69, "Coro_LoadSelectedGhost"); return; }
        if (globalOffset.Length == 0) { log("Offset not provided.", LogLevel::Error, 70, "Coro_LoadSelectedGhost"); return; }

        accountIdFetched = false;
        mapIdFetched = false;

        startnew(Coro_FetchAccountId);
        startnew(Coro_FetchMapId);

        while (!(accountIdFetched && mapIdFetched)) { yield(); }

        if (accountId.Length == 0) { log("Account ID not found.", LogLevel::Error, 80, "Coro_LoadSelectedGhost"); return; }
        if (mapId.Length == 0) { log("Map ID not found.", LogLevel::Error, 81, "Coro_LoadSelectedGhost"); return; }

        SaveReplay(mapId, accountId, globalOffset);
    }

    void Coro_FetchAccountId() {
        // if (accountId.Length > 0) { log("AccountId provided in LoadSelectedRevord", LogLevel::Info, 87, "Coro_FetchAccountId"); accountIdFetched = true; return; }

        accountIdFetched = false;

        string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + globalMapUid + "/top?onlyWorld=true&length=1&offset=" + globalOffset;
        auto req = NadeoServices::Get("NadeoLiveServices", url);

        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) {
            log("Failed to fetch account ID, response code: " + req.ResponseCode(), LogLevel::Error, 99, "Coro_FetchAccountId");
            accountId = "";
        } else {
            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for account ID.", LogLevel::Error, 104, "Coro_FetchAccountId");
                accountId = "";
            } else {
                auto tops = data["tops"];
                if (tops.GetType() != Json::Type::Array || tops.Length == 0) {
                    log("Invalid tops data in response.", LogLevel::Error, 109, "Coro_FetchAccountId");
                    accountId = "";
                } else {
                    auto top = tops[0]["top"];
                    if (top.GetType() != Json::Type::Array || top.Length == 0) {
                        log("Invalid top data in response.", LogLevel::Error, 114, "Coro_FetchAccountId");
                        accountId = "";
                    } else {
                        accountId = top[0]["accountId"];
                        log("Found account ID: " + accountId, LogLevel::Info, 118, "Coro_FetchAccountId");
                    }
                }
            }
        }
        accountIdFetched = true;
    }

    void Coro_FetchMapId() {
        // if (mapId.Length > 0) { log("MapId provided in LoadSelectedRevord", LogLevel::Info, 127, "Coro_FetchMapId"); mapIdFetched = true; return; }

        mapIdFetched = false;
        string url = "https://prod.trackmania.core.nadeo.online/maps/?mapUidList=" + globalMapUid;
        auto req = NadeoServices::Get("NadeoServices", url);

        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) {
            log("Failed to fetch map ID, response code: " + req.ResponseCode(), LogLevel::Error, 138, "Coro_FetchMapId");
            mapId = "";
        } else {
            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for map ID.", LogLevel::Error, 143, "Coro_FetchMapId");
                mapId = "";
            } else {
                if (data.GetType() != Json::Type::Array || data.Length == 0) {
                    log("Invalid map data in response.", LogLevel::Error, 147, "Coro_FetchMapId");
                    mapId = "";
                } else {
                    mapId = data[0]["mapId"];
                    log("Found map ID: " + mapId, LogLevel::Info, 151, "Coro_FetchMapId");
                }
            }
        }
        mapIdFetched = true;
    }

    void SaveReplay(const string &in mapId, const string &in accountId, const string &in offset) {
        string url = "https://prod.trackmania.core.nadeo.online/v2/mapRecords/?accountIdList=" + accountId + "&mapId=" + mapId;
        auto req = NadeoServices::Get("NadeoServices", url);

        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) { log("Failed to fetch replay record, response code: " + req.ResponseCode(), LogLevel::Error, 166, "SaveReplay"); return; }

        Json::Value data = Json::Parse(req.String());
        if (data.GetType() == Json::Type::Null) { log("Failed to parse response for replay record.", LogLevel::Error, 169, "SaveReplay"); return; }
        if (data.GetType() != Json::Type::Array || data.Length == 0) { log("Invalid replay data in response.", LogLevel::Error, 170, "SaveReplay"); return; }

        string fileUrl = data[0]["url"];
        string savePath = Server::officialFilesDirectory + "/" + "Official_" + globalMapUid + "_Position" + offset + "_" + accountId + "_" + tostring(Time::Stamp) + ".Ghost.Gbx";

        auto fileReq = NadeoServices::Get("NadeoServices", fileUrl);

        fileReq.Start();

        while (!fileReq.Finished()) {
            yield();
        }

        if (fileReq.ResponseCode() != 200) {
            log("Failed to download replay file, response code: " + fileReq.ResponseCode(), LogLevel::Error, 184, "SaveReplay");
            return;
        }

        fileReq.SaveToFile(savePath);

        ProcessSelectedFile(savePath);

        log("Replay file saved to: " + savePath, LogLevel::Info, 192, "SaveReplay");
    }
}
