namespace Features {
namespace LRFromMapIdentifier {
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
        if (globalMapUid.Length == 0) { log("Map UID not provided.", LogLevel::Error, 405, "Coro_LoadSelectedGhost"); return; }
        if (globalOffset.Length == 0) { log("Offset not provided.", LogLevel::Error, 406, "Coro_LoadSelectedGhost"); return; }

        accountIdFetched = false;
        mapIdFetched = false;

        startnew(Coro_FetchAccountId);
        startnew(Coro_FetchMapId);

        while (!(accountIdFetched && mapIdFetched)) { yield(); }

        if (accountId.Length == 0) { log("Account ID not found.", LogLevel::Error, 416, "Coro_LoadSelectedGhost"); return; }
        if (mapId.Length == 0) { log("Map ID not found.", LogLevel::Error, 417, "Coro_LoadSelectedGhost"); return; }

        SaveReplay(mapId, accountId, globalOffset, specialSaveLocation);
    }

    void Coro_FetchAccountId() {
        // if (accountId.Length > 0) { log("AccountId provided in LoadSelectedRevord", LogLevel::Info, 423, "Coro_FetchAccountId"); accountIdFetched = true; return; }

        accountIdFetched = false;

        string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + globalMapUid + "/top?onlyWorld=true&length=1&offset=" + globalOffset;
        auto req = NadeoServices::Get("NadeoLiveServices", url);

        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) {
            log("Failed to fetch account ID, response code: " + req.ResponseCode(), LogLevel::Error, 435, "Coro_FetchAccountId");
            accountId = "";
        } else {
            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for account ID.", LogLevel::Error, 440, "Coro_FetchAccountId");
                accountId = "";
            } else {
                auto tops = data["tops"];
                if (tops.GetType() != Json::Type::Array || tops.Length == 0) {
                    log("Invalid tops data in response.", LogLevel::Error, 445, "Coro_FetchAccountId");
                    accountId = "";
                } else {
                    auto top = tops[0]["top"];
                    if (top.GetType() != Json::Type::Array || top.Length == 0) {
                        log("Invalid top data in response.", LogLevel::Error, 450, "Coro_FetchAccountId");
                        accountId = "";
                    } else {
                        accountId = top[0]["accountId"];
                        log("Found account ID: " + accountId, LogLevel::Info, 454, "Coro_FetchAccountId");
                    }
                }
            }
        }
        accountIdFetched = true;
    }

    void Coro_FetchMapId() {
        // if (mapId.Length > 0) { log("MapId provided in LoadSelectedRevord", LogLevel::Info, 463, "Coro_FetchMapId"); mapIdFetched = true; return; }

        mapIdFetched = false;
        string url = "https://prod.trackmania.core.nadeo.online/maps/?mapUidList=" + globalMapUid;
        auto req = NadeoServices::Get("NadeoServices", url);

        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) {
            log("Failed to fetch map ID, response code: " + req.ResponseCode(), LogLevel::Error, 474, "Coro_FetchMapId");
            mapId = "";
        } else {
            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for map ID.", LogLevel::Error, 479, "Coro_FetchMapId");
                mapId = "";
            } else {
                if (data.GetType() != Json::Type::Array || data.Length == 0) {
                    log("Invalid map data in response.", LogLevel::Error, 483, "Coro_FetchMapId");
                    mapId = "";
                } else {
                    mapId = data[0]["mapId"];
                    log("Found map ID: " + mapId, LogLevel::Info, 487, "Coro_FetchMapId");
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

        if (req.ResponseCode() != 200) { log("Failed to fetch replay record, response code: " + req.ResponseCode(), LogLevel::Error, 502, "SaveReplay"); return; }

        Json::Value data = Json::Parse(req.String());
        if (data.GetType() == Json::Type::Null) { log("Failed to parse response for replay record.", LogLevel::Error, 505, "SaveReplay"); return; }
        if (data.GetType() != Json::Type::Array || data.Length == 0) { log("Invalid replay data in response.", LogLevel::Error, 506, "SaveReplay"); return; }

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

        if (fileReq.ResponseCode() != 200) { log("Failed to download replay file, response code: " + fileReq.ResponseCode(), LogLevel::Error, 526, "SaveReplay"); return; }

        fileReq.SaveToFile(savePath);

        ProcessSelectedFile(savePath);

        log(savePath.ToLower().EndsWith(".replay.gbx") ? "Replay" : "Ghost" + " file saved to: " + savePath, LogLevel::Info, 532, "SaveReplay");
    }
}
}