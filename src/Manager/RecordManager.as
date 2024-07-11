namespace RecordManager {
    array<CGameGhostScript@> ghosts;

    void OpenGhostFileDialogWindow() {
        _IO::FileExplorer::OpenFileExplorer(true, IO::FromUserGameFolder("Replays/"), "", { "replay", "ghost" });
    }

    void RemoveAllRecords() {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_RemoveAll();
        log("All ghosts removed.", LogLevel::Info, 9, "RemoveAllRecords");
    }

    void RemoveInstanceRecord(MwId instanceId) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_Remove(instanceId);
        log("Record with the MwID of: " + instanceId.GetName() + " removed.", LogLevel::Info, 15, "RemoveInstanceRecord");
    }

    void SetRecordDossard(MwId instanceId, const int &in dossard, vec3 color = vec3()) {
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
    }

    string GetGhostNameById(MwId id) {
        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Id == id) {
                return ghosts[i].Nickname;
            }
        }
        return "";
    }

    string GetGhostInfo(MwId id) {
        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Id == id) {
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
