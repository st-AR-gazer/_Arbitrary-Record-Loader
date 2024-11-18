namespace RecordManager {
    array<CGameGhostScript@> ghosts;

    void RemoveAllRecords() {
        // Does technically remove all the ghosts, but the instance isn't cleared...
        // if (GetApp().PlaygroundScript is null) return;
        // auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        // gm.Ghost_RemoveAll();
        // log("All ghosts removed.", LogLevel::Info, 10, "RemoveAllRecords");
        // GhostTracker::ClearTrackedGhosts();

        // This removes the ghosts from the list, as well as the instance.

        if (GetApp().PlaygroundScript is null) return;

        auto dataFileMgr = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        auto newGhosts = dataFileMgr.Ghosts;

        for (uint i = 0; i < newGhosts.Length; i++) {
            CGameGhostScript@ ghost = cast<CGameGhostScript>(newGhosts[i]);
            RemoveInstanceRecord(ghost.Id);
        }
        GhostTracker().ClearTrackedGhosts();
    }

    void RemoveInstanceRecord(MwId instanceId) {
        if (GetApp().PlaygroundScript is null) return;

        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_Remove(instanceId);
        log("Record with the MwID of: " + instanceId.GetName() + " removed.", LogLevel::Info, 32, "RemoveInstanceRecord");
        GhostTracker().RemoveTrackedGhost(instanceId);
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
        log("Record dossard set.", LogLevel::Info, 54, "RemovePBRecord");
    }

    bool IsRecordVisible(MwId instanceId) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        bool isVisible = gm.Ghost_IsVisible(instanceId);
        return isVisible;
    }

    bool IsRecordOver(MwId instanceId) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        bool isOver = gm.Ghost_IsReplayOver(instanceId);
        return isOver;
    }

    void AddRecordWithOffset(CGameGhostScript@ ghost, const int &in offset) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_Add(ghost, true, offset);
        log("Ghost added with offset.", LogLevel::Info, 72, "AddGhostWithOffset");
        GhostTracker().AddTrackedGhost(ghost);
    }

    string GetRecordNameFromId(MwId id) {
        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Id.Value == id.Value) {
                return ghosts[i].Nickname;
            }
        }
        return "";
    }

    MwId[] GetRecordIdFromName(const string &in name) {
        array<MwId> ids;
        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Nickname == name) {
                ids.InsertLast(ghosts[i].Id);
            }
        }
        return ids;
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

    class GhostTracker {
        array<CGameGhostScript@> trackedGhosts;
        array<MwId> removedGhosts;

        void Init() {
            log("Initializing GhostTracker", LogLevel::Info, 105, "Init");
            UpdateGhosts();
        }

        void UpdateGhosts() {
            auto app = GetApp();
            if (app is null || app.Network is null || app.Network.ClientManiaAppPlayground is null) { log("App or network components not ready", LogLevel::Warn, 112, "UpdateGhosts"); return; }

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

            log("Ghosts updated, count: " + ghosts.Length + " Normal Ghosts: " + ghostsWithoutNickname + " VTable Ghosts: " + ghostsWithNickname, LogLevel::Info, 140, "UpdateGhosts");
        }

        void AddTrackedGhost(CGameGhostScript@ ghost) {
            if (!IsGhostTracked(ghost.Id)) {
                trackedGhosts.InsertLast(ghost);

                if (ghost.Nickname == "cfa844b7-6b53-4663-ac0d-9bdd3ad1af22") return;
                log("Tracked ghost added: " + ghost.Nickname, LogLevel::Info, 148, "AddTrackedGhost");
            }
        }

        void RemoveTrackedGhost(MwId instanceId) {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                if (trackedGhosts[i].Id.Value == instanceId.Value) {
                    log("Tracked ghost removed: " + trackedGhosts[i].Nickname, LogLevel::Info, 155, "RemoveTrackedGhost");
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
            log("Cleared all tracked ghosts.", LogLevel::Info, 168, "ClearTrackedGhosts");
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

            log("Saving ghost to file: " + replayFilePath, LogLevel::Info, 234, "SaveRecord");

            auto app = GetApp();
            if (app is null || app.Network is null || app.Network.ClientManiaAppPlayground is null) { NotifyError("App or network components not ready."); return; }
            auto rootMap = cast<CGameCtnChallenge@>(app.RootMap);
            if (rootMap is null) { NotifyError("RootMap is not a valid CGameCtnChallenge."); return; }

            CWebServicesTaskResult@ saveResult = app.Network.ClientManiaAppPlayground.DataFileMgr.Replay_Save(tmpFilePath, rootMap, ghost);
            if (saveResult.HasSucceeded && !saveResult.HasFailed) {
                log("Replay save successful", LogLevel::Info, 243, "SaveRecord");

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
                log("Replay save failed: " + saveResult.ErrorDescription, LogLevel::Error, 268, "SaveRecord");
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
            for (uint i = 0; i < GhostTracker().trackedGhosts.Length; i++) {
                if (GhostTracker().trackedGhosts[i].Id.Value == id.Value) {
                    return GhostTracker().trackedGhosts[i];
                }
            }
            return null;
        }

        void SaveRecordByPath(const string &in overwritePath) {
            

        }
    }
}

class LoadRecord {
    void LoadRecordFromLocalFile(const string &in filePath) {
        startnew(CoroutineFuncUserdataString(Coro_LoadRecordFromFile), filePath);
    }

    void Coro_LoadRecordFromFile(const string &in filePath) {
        if (!IO::FileExists(filePath)) {
            NotifyError("File does not exist.");
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

        AllowCheck::InitializeAllowCheckWithTimeout(500);
        if (AllowCheck::ConditionCheckMet()) {

            // 

            if (fileExt == "replay") {
                ReplayLoader::LoadReplayFromPath(filePath);
            } else if (fileExt == "ghost") {
                GhostLoader::LoadGhostFromLocalFile(filePath);
            } else {
                log("Unsupported file type: " + fileExt + " " + "Full path: " + filePath, LogLevel::Error, 350, "Coro_ProcessSelectedFile");
                NotifyWarn("Error | Unsupported file type.");
            }

            // 

        }
    }

    void LoadRecordFromUrl(const string &in url) {
        startnew(CoroutineFuncUserdataString(Coro_LoadRecordFromUrl), url);
    }

    void Coro_LoadRecordFromUrl(const string &in url) {
        if (url.StartsWith("https://") || url.StartsWith("http://") || url.Contains("trackmania.io") || url.Contains("trackmania.exchange") || url.Contains("www.")) {
            _Net::DownloadFileToDestination(url, Server::linksFilesDirectory + Path::GetFileName(url), "Link");
            startnew(CoroutineFuncUserdataString(ProcessDownloadedFile), "Link");
            
            LoadRecordFromLocalFile(url);
        } else {
            log("Invalid URL.", LogLevel::Error, 370, "Coro_LoadRecordFromUrl");
        }
    }

    void ProcessDownloadedFile(const string &in key) {
        while (!_Net::downloadedFilePaths.Exists(key)) { yield(); }

        string finalFilePath = string(_Net::downloadedFilePaths[key]);
        _Net::downloadedFilePaths.Delete(key);
        while (!IO::FileExists(finalFilePath)) { yield(); }
    }

    void LoadRecordFromMapUid(const string &in mapUid, const string &in offset, const string &in _specialSaveLocation, const string &in _accountId = "", const string &in _mapId = "") {
        Features::LRFromMapIdentifier::LoadSelectedRecord(mapUid, offset, _specialSaveLocation, _accountId, _mapId);
    }
}