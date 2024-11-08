namespace CurrentMapRecords {
namespace PB {
#if DEPENDENCY_ARCHIVIST
    string archivist_base_folder = IO::FromUserGameFolder("Replays/Archivist");

    void IndexAndSaveToArchivist() {
        pbRecords.RemoveRange(0, pbRecords.Length);

        string currentMapName = GetCurrentMapName();
        if (currentMapName == "") { return; }

        string map_folder = archivist_base_folder + "/" + currentMapName;

        if (!IO::FolderExists(map_folder)) { return; }

        array<string> subfolders = { "Complete", "Segmented", "Partial" };

        dictionary bestPBPerMap;

        for (uint i = 0; i < subfolders.Length; i++) {
            string subfolder_path = map_folder + "/" + subfolders[i];
            
            if (!IO::FolderExists(subfolder_path)) {
                log("PBManager: Subfolder does not exist: " + subfolder_path, LogLevel::Warn, 30, "IndexAndSaveToArchivist");
                continue;
            }

            array<string>@ ghostFiles = IO::IndexFolder(subfolder_path, false);

                        for (uint j = 0; j < ghostFiles.Length; j++) {
                string filePath = ghostFiles[j];
                string fileName = Path::GetFileName(filePath);
            
                // Expected format: "YYYY-MM-DD HH-MM-SS xxxxms name.Ghost.Gbx"
                // Example: "2024-06-29 14-45-32 7840ms AR.Ghost.Gbx"
                array<string> parts = fileName.Split(" ");
                if (parts.Length < 4) { continue; }
            
                string msStr = parts[2];
                if (!msStr.EndsWith("ms")) { continue; }
            
                string msNumberStr = msStr.SubStr(0, msStr.Length - 2);
                int ms = 0;
                if (Text::ParseInt(msNumberStr) > 0) { continue; }
            
                string mapUid = GetCurrentMapUID();
                if (mapUid == "") { return; }
            
                if (bestPBPerMap.Exists(mapUid)) {
                    int existingMs = int(bestPBPerMap[mapUid + "_ms"]);
                    if (ms < existingMs) {
                        bestPBPerMap[mapUid] = filePath;
                        bestPBPerMap[mapUid + "_ms"] = ms;
                    }
                } else {
                    bestPBPerMap[mapUid] = filePath;
                    bestPBPerMap[mapUid + "_ms"] = ms;
                }
            }}
            
            string[]@ keys = bestPBPerMap.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                
                if (key.EndsWith("_ms")) { continue; }
            
                string mapUid = key;
                string filePath = string(bestPBPerMap[mapUid]);
                string fileName = Path::GetFileName(filePath);
            
                PBRecord@ pbRecord = PBRecord(mapUid, fileName, filePath);
                pbRecords.InsertLast(pbRecord);
            }


        SavePBRecordsToFile();
        log("PBManager: Successfully indexed Archivist folder for map: " + currentMapName, LogLevel::Info, 80, "IndexAndSaveToArchivist");
    }

    string GetCurrentMapName() {
        auto app = GetApp();
        if (app is null || app.RootMap is null || app.RootMap.MapInfo is null) {
            return "";
        }
        return app.RootMap.MapInfo.Name;
    }

    string GetCurrentMapUID() {
        auto app = GetApp();
        if (app is null || app.RootMap is null || app.RootMap.MapInfo is null) {
            return "";
        }
        return app.RootMap.MapInfo.MapUid;
    }

    void IndexAndSaveToFile() {
        #if DEPENDENCY_ARCHIVIST
            IndexAndSaveToArchivist();
        #else
            pbRecords.RemoveRange(0, pbRecords.Length);

            for (uint i = 0; i < GetApp().ReplayRecordInfos.Length; i++) {
                auto record = GetApp().ReplayRecordInfos[i];
                string path = record.Path;

                if (path.StartsWith("Autosaves\\")) {
                    string mapUid = record.MapUid;
                    string fileName = record.FileName;

                    string relativePath = "Replays/" + fileName;
                    string fullFilePath = IO::FromUserGameFolder(relativePath);

                    PBRecord@ pbRecord = PBRecord(mapUid, fileName, fullFilePath);
                    pbRecords.InsertLast(pbRecord);
                }
            }

            SavePBRecordsToFile();
        #endif
    }

    namespace PBManager {
        void LoadCompletePB() {
            LoadPBFromSubfolder("Complete");
        }

        void LoadSegmentedPB() {
            LoadPBFromSubfolder("Segmented");
        }

        void LoadPartialPB() {
            LoadPBFromSubfolder("Partial");
        }

        void LoadPBFromSubfolder(const string &in subfolder) {
            auto ghostMgr = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;

            for (uint i = 0; i < pbRecords.Length; i++) {
                string filePath = pbRecords[i].FullFilePath;
                string fileName = Path::GetFileName(filePath);

                if (filePath.Contains("/" + subfolder + "/")) {
                    if (IO::FileExists(filePath)) {
                        auto task = GetApp().Network.ClientManiaAppPlayground.DataFileMgr.Replay_Load(filePath);
                        while (task.IsProcessing) { yield(); }

                        if (task.HasFailed || !task.HasSucceeded) {
                            log("Failed to load replay file from " + filePath, LogLevel::Error, 89, "LoadPBFromSubfolder");
                            continue;
                        }

                        for (uint j = 0; j < task.Ghosts.Length; j++) {
                            auto ghost = task.Ghosts[j];
                            ghost.IdName = "Personal best";
                            ghost.Nickname = "$5d8" + "Personal best";
                            ghost.Trigram = "PB";
                            ghostMgr.Ghost_Add(ghost);
                        }
                        
                        log("Loaded " + subfolder + " PB ghost from " + filePath, LogLevel::Info, 101, "LoadPBFromSubfolder");
                    }
                }
            }
        }

        void SavePBRecordsToFile() {
            string savePath = Server::serverPB;
            Json::Value jsonData = Json::Array();

            for (uint i = 0; i < pbRecords.Length; i++) {
                Json::Value@ record = Json::Object();
                record["MapUid"] = pbRecords[i].MapUid;
                record["FileName"] = pbRecords[i].FileName;
                record["FullFilePath"] = pbRecords[i].FullFilePath;
                jsonData.Add(record);
            }

            string saveData = Json::Write(jsonData, true);
            _IO::File::WriteFile(savePath, saveData, true); // Save to Server::serverPBList
        }
    }

#endif








































    // Non-Archivist functionality remains unchanged
    // Code is mostly copied from "Auto Enable PB Ghost"

    /* ************************************************************************************************** */

    // src/Index.as
    array<PBRecord@> pbRecords;
    string autosaves_index = Server::serverPB + "autosaves_index.json";

    // void IndexAndSaveToFile() { } // moved to the PB section

    void SavePBRecordsToFile() {
        string savePath = autosaves_index;
        Json::Value jsonData = Json::Array();

        for (uint i = 0; i < pbRecords.Length; i++) {
            Json::Value@ record = Json::Object();
            record["MapUid"] = pbRecords[i].MapUid;
            record["FileName"] = pbRecords[i].FileName;
            record["FullFilePath"] = pbRecords[i].FullFilePath;
            jsonData.Add(record);
        }

        string saveData = Json::Write(jsonData, true);

        _IO::File::WriteFile(savePath, saveData, true);
    }

    void LoadPBRecordsFromFile() {
        string loadPath = autosaves_index;
        if (!IO::FileExists(loadPath)) {
            log("PBManager: Autosaves index file does not exist. Indexing will be performed on map load.", LogLevel::Info, 46, "LoadPBRecordsFromFile");
            return;
        }

        // change this so that it just reads from the file instead of parsing every time?
        string str_jsonData = _IO::File::ReadFileToEnd(loadPath);
        Json::Value jsonData = Json::Parse(str_jsonData);

        pbRecords.RemoveRange(0, pbRecords.Length);

        for (uint i = 0; i < jsonData.Length; i++) {
            auto j = jsonData[i];
            string mapUid = j["MapUid"];
            string fileName = j["FileName"];
            string fullFilePath = j["FullFilePath"];
            PBRecord@ pbRecord = PBRecord(mapUid, fileName, fullFilePath);
            pbRecords.InsertLast(pbRecord);
        }

        log("PBManager: Successfully loaded autosaves index from " + loadPath, LogLevel::Info, 65, "LoadPBRecordsFromFile");
    }

    // src/Main.as
    void main() {
        PBVisibilityHook::InitializeHook();
        if (!IO::FileExists(autosaves_index)) {
            IndexAndSaveToFile();
        }
        startnew(MapTracker::MapMonitor);

        PBManager::Initialize(GetApp());
        PBManager::LoadPB();
    }

    void OnDisabled() {
        PBVisibilityHook::UninitializeHook();
        PBManager::UnloadAllPBs();
    }

    void OnDestroyed() {
        OnDisabled();
    }

    // MapManager.as (this file was not ported as it is not relevant)

    // pbGhostVisibliityHook.as
    namespace PBVisibilityHook {
        bool pbToggleReceived = false;

        class PBVisibilityUpdateHook : MLHook::HookMLEventsByType {
            PBVisibilityUpdateHook(const string &in typeToHook) {
                super(typeToHook);
            }

            void OnEvent(MLHook::PendingEvent@ event) override {
                if (this.type == "TMGame_Record_TogglePB") {
                    pbToggleReceived = true;
                }
                else if (this.type == "TMGame_Record_UpdatePBGhostVisibility") {
                    if (!pbToggleReceived) {
                        return;
                    }

                    pbToggleReceived = false;

                    bool shouldShow = tostring(event.data[0]).ToLower().Contains("true");

                    if (shouldShow) {
                        startnew(PBManager::LoadPB);
                    } else {
                        startnew(PBManager::UnloadAllPBs);
                    }
                }
            }
        }

        PBVisibilityUpdateHook@ togglePBHook;
        PBVisibilityUpdateHook@ updateVisibilityHook;

        void InitializeHook() {
            @togglePBHook = PBVisibilityUpdateHook("TMGame_Record_TogglePB");
            MLHook::RegisterMLHook(togglePBHook, "TMGame_Record_TogglePB", true);

            @updateVisibilityHook = PBVisibilityUpdateHook("TMGame_Record_UpdatePBGhostVisibility");
            MLHook::RegisterMLHook(updateVisibilityHook, "TMGame_Record_UpdatePBGhostVisibility", true);

            log("PBVisibilityHook: Hooks registered for TogglePB and UpdatePBGhostVisibility.", LogLevel::Info, 41, "InitializeHook");
        }

        void UninitializeHook() {
            if (togglePBHook !is null) {
                MLHook::UnregisterMLHookFromAll(togglePBHook);
                @togglePBHook = null;
            }
            if (updateVisibilityHook !is null) {
                MLHook::UnregisterMLHookFromAll(updateVisibilityHook);
                @updateVisibilityHook = null;
            }
            log("PBVisibilityHook: Hooks unregistered for TogglePB and UpdatePBGhostVisibility.", LogLevel::Info, 53, "UninitializeHook");
        }
    }

    // pbManager.as
    class PBRecord {
        string MapUid;
        string FileName;
        string FullFilePath;

        PBRecord(const string &in mapUid, const string &in fileName, const string &in fullFilePath) {
            MapUid = mapUid;
            FileName = fileName;
            FullFilePath = fullFilePath;
        }
    }

    namespace PBManager {
        array<PBRecord@> pbRecords;
        string autosaves_index = Server::serverPB + "autosaves_index.json";

        NGameGhostClips_SMgr@ ghostMgr;
        CGameCtnMediaClipPlayer@ currentPBGhostPlayer;
        array<PBRecord@> currentMapPBRecords;
        array<uint> saving;

        void Initialize(CGameCtnApp@ app) {
            @ghostMgr = GhostClipsMgr::Get(app);
            needsRefresh = true;
        }

        bool IsPBLoaded() {
            if (ghostMgr is null) return false;
            CGameCtnMediaClipPlayer@ pbClipPlayer = GhostClipsMgr::GetPBClipPlayer(ghostMgr);
            return pbClipPlayer !is null;
        }

        bool IsLocalPBLoaded() {
            auto net = cast<CGameCtnNetwork>(GetApp().Network);
            if (net is null) return false;
            auto cmap = cast<CGameManiaAppPlayground>(net.ClientManiaAppPlayground);
            if (cmap is null) return false;
            auto dfm = cmap.DataFileMgr;
            if (dfm is null) return false;
            
            for (uint i = 0; i < dfm.Ghosts.Length; i++) {
                if (dfm.Ghosts[i].IdName.ToLower().Contains("personal best")) {
                    return true;
                }
            }
            return false;
        }

        bool needsRefresh = true;
        void LoadPB() {
            UnloadAllPBs();
            if (needsRefresh) LoadPBFromIndex();
            needsRefresh = false;
            LoadPBFromCache();
        }
        
        void LoadPBFromIndex() {
            string loadPath = autosaves_index;
            if (!IO::FileExists(loadPath)) { return; }

            string str_jsonData = _IO::File::ReadFileToEnd(loadPath);
            Json::Value jsonData = Json::Parse(str_jsonData);

            pbRecords.RemoveRange(0, pbRecords.Length);

            for (uint i = 0; i < jsonData.Length; i++) {
                auto j = jsonData[i];
                string mapUid = j["MapUid"];
                string fileName = j["FileName"];
                string fullFilePath = j["FullFilePath"];
                PBRecord@ pbRecord = PBRecord(mapUid, fileName, fullFilePath);
                pbRecords.InsertLast(pbRecord);
                // log("LoadPBFromIndex: Loaded PBRecord for MapUid: " + mapUid + ", FileName: " + fileName, LogLevel::Dark, 73, "LoadPBFromIndex");
            }

            currentMapPBRecords = GetPBRecordsForCurrentMap();
        }

        void LoadPBFromCache() {
            currentMapPBRecords = GetPBRecordsForCurrentMap();
            auto ghostMgr = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;

            for (uint i = 0; i < currentMapPBRecords.Length; i++) {
                if (IO::FileExists(currentMapPBRecords[i].FullFilePath)) {
                    auto task = GetApp().Network.ClientManiaAppPlayground.DataFileMgr.Replay_Load(currentMapPBRecords[i].FullFilePath);
                    while (task.IsProcessing) { yield(); }

                    if (task.HasFailed || !task.HasSucceeded) {
                        log("Failed to load replay file from cache: " + currentMapPBRecords[i].FullFilePath, LogLevel::Error, 89, "LoadPBFromCache");
                        continue;
                    }

                    for (uint j = 0; j < task.Ghosts.Length; j++) {
                        auto ghost = task.Ghosts[j];
                        ghost.IdName = "Personal best";
                        ghost.Nickname = "$5d8" + "Personal best";
                        ghost.Trigram = "PB";
                        ghostMgr.Ghost_Add(ghost);
                    }
                    
                    log("Loaded PB ghost from " + currentMapPBRecords[i].FullFilePath, LogLevel::Info, 101, "LoadPBFromCache");
                }
            }
        }

        void UnloadAllPBs() {
            auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
            if (ps is null) { return; }
            auto mgr = GhostClipsMgr::Get(GetApp());
            if (mgr is null) { return; }

            for (int i = int(mgr.Ghosts.Length) - 1; i >= 0; i--) {
                string ghostNickname;
                try {
                    ghostNickname = mgr.Ghosts[i].GhostModel.GhostNickname;
                } catch {
                    log("UnloadAllPBs: Failed to access GhostNickname for ghost at index " + i, LogLevel::Warn, 117, "UnloadAllPBs");
                    continue;
                }

                if (ghostNickname.ToLower().Contains("personal best")) {
                    UnloadPB(uint(i));
                }
            }

            auto net = cast<CGameCtnNetwork>(GetApp().Network);
            if (net is null) return;
            auto cmap = cast<CGameManiaAppPlayground>(net.ClientManiaAppPlayground);
            if (cmap is null) return;
            auto dfm = cmap.DataFileMgr;
            if (dfm is null) return;
            
            array<MwId> ghostIds;

            for (uint i = 0; i < dfm.Ghosts.Length; i++) {
                if (dfm.Ghosts[i].IdName.ToLower().Contains("personal best")) {
                    ghostIds.InsertLast(dfm.Ghosts[i].Id);
                }
            }

            for (uint i = 0; i < ghostIds.Length; i++) {
                dfm.Ghost_Release(ghostIds[i]);
            }

            currentMapPBRecords.RemoveRange(0, currentMapPBRecords.Length);
        }

        void UnloadPB(uint i) {
            auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
            if (ps is null) { return; }
            auto mgr = GhostClipsMgr::Get(GetApp());
            if (mgr is null) { return; }
            if (i >= mgr.Ghosts.Length) { return; }

            uint id = GhostClipsMgr::GetInstanceIdAtIx(mgr, i);
            if (id == uint(-1)) { return; }

            string wsid = LoginToWSID(mgr.Ghosts[i].GhostModel.GhostLogin);
            Update_ML_SetGhostUnloaded(wsid);

            ps.GhostMgr.Ghost_Remove(MwId(id));

            int ix = saving.Find(id);
            if (ix >= 0) { saving.RemoveAt(ix); }

            if (i < currentMapPBRecords.Length) {
                string removedMapUid = currentMapPBRecords[i].MapUid;
                string removedFilePath = currentMapPBRecords[i].FullFilePath;
                currentMapPBRecords.RemoveAt(i);
            }
        }

        array<PBRecord@>@ GetPBRecordsForCurrentMap() {
            string currentMapUid = get_CurrentMapUID();
            array<PBRecord@> currentMapRecords;
            currentMapRecords.Resize(0);

            for (uint i = 0; i < pbRecords.Length; i++) {
                if (pbRecords[i].MapUid == currentMapUid) {
                    currentMapRecords.InsertLast(pbRecords[i]);
                }
            }

            return currentMapRecords;
        }

        const string SetFocusedRecord_PageUID = "SetFocusedRecord";
        dictionary ghostWsidsLoaded;

        void Update_ML_SetGhostUnloaded(const string &in wsid) {
            if (ghostWsidsLoaded.Exists(wsid)) {
                ghostWsidsLoaded.Delete(wsid);
            }
            MLHook::Queue_MessageManialinkPlayground(SetFocusedRecord_PageUID, {"SetGhostUnloaded", wsid});
        }

        string LoginToWSID(const string &in login) {
            try {
                auto buf = MemoryBuffer();
                buf.WriteFromBase64(login, true);
                string hex = Utils::BufferToHex(buf);
                string wsid = hex.SubStr(0, 8)
                    + "-" + hex.SubStr(8, 4)
                    + "-" + hex.SubStr(12, 4)
                    + "-" + hex.SubStr(16, 4)
                    + "-" + hex.SubStr(20);
                return wsid;
            } catch {
                return login;
            }
        }
    }

    namespace GhostClipsMgr {
        const uint16 GhostsOffset = GetOffset("NGameGhostClips_SMgr", "Ghosts");
        const uint16 GhostInstIdsOffset = GhostsOffset + 0x10;

        NGameGhostClips_SMgr@ Get(CGameCtnApp@ app) {
            return GetGhostClipsMgr(app);
        }

        NGameGhostClips_SMgr@ GetGhostClipsMgr(CGameCtnApp@ app) {
            if (app.GameScene is null) return null;
            auto nod = Dev::GetOffsetNod(app.GameScene, 0x120);
            if (nod is null) return null;
            return Dev::ForceCast<NGameGhostClips_SMgr@>(nod).Get();
        }

        CGameCtnMediaClipPlayer@ GetPBClipPlayer(NGameGhostClips_SMgr@ mgr) {
            return cast<CGameCtnMediaClipPlayer>(Dev::GetOffsetNod(mgr, 0x40));
        }

        uint GetInstanceIdAtIx(NGameGhostClips_SMgr@ mgr, uint ix) {
            if (mgr is null) return uint(-1);
            uint bufOffset = GhostInstIdsOffset;
            uint64 bufPtr = Dev::GetOffsetUint64(mgr, bufOffset);
            uint nextIdOrSomething = Dev::GetOffsetUint32(mgr, bufOffset + 0x8);
            uint bufLen = Dev::GetOffsetUint32(mgr, bufOffset + 0xC);
            uint bufCapacity = Dev::GetOffsetUint32(mgr, bufOffset + 0x10);

            if (bufLen == 0 || bufCapacity == 0) return uint(-1);

            // A bunch of trial and error to figure this out >.< // Thank you XertroV :peeepoLove:
            if (bufLen <= ix) return uint(-1);
            if (bufPtr == 0 || bufPtr % 8 != 0) return uint(-1);
            uint slot = Dev::ReadUInt32(bufPtr + (bufCapacity * 4) + ix * 4);
            uint msb = Dev::ReadUInt32(bufPtr + slot * 4) & 0xFF000000;
            return msb + slot;
        }
    }

    uint16 GetOffset(const string &in className, const string &in memberName) {
        auto ty = Reflection::GetType(className);
        auto memberTy = ty.GetMember(memberName);
        return memberTy.Offset;
    }

    namespace Utils {
        string BufferToHex(MemoryBuffer@ buf) {
            buf.Seek(0);
            uint size = buf.GetSize();
            string ret;
            for (uint i = 0; i < size; i++) {
                ret += Uint8ToHex(buf.ReadUInt8());
            }
            return ret;
        }

        string Uint8ToHex(uint8 val) {
            return Uint4ToHex(val >> 4) + Uint4ToHex(val & 0xF);
        }

        string Uint4ToHex(uint8 val) {
            if (val > 0xF) throw('val out of range: ' + val);
            string ret = " ";
            if (val < 10) {
                ret[0] = val + 0x30;
            } else {
                // 0x61 = a
                ret[0] = val - 10 + 0x61;
            }
            return ret;
        }
    }
}


    namespace ValidationReplay {

        void AddValidationReplay() {
            if (ValidationReplayExists()) {
                ReplayLoader::LoadReplayFromPath(GetValidationReplayFilePathForCurrentMap());
            }
        }

        bool ValidationReplayExists() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return false;
            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return false;
            CGameDataFileManagerScript@ dataFileMgr = playground.DataFileMgr;
            if (dataFileMgr is null) { /*log("DataFileMgr is null", LogLevel::Error, 17, "ValidationReplayExists");*/ return false; }
            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) { /*log("Author ghost is empty", LogLevel::Warn, 19, "ValidationReplayExists");*/ return false; }
            return true;
        }

        void OnMapLoad() {
            if (ValidationReplayExists()) {
                ExtractValidationReplay();
            }
        }

        void ExtractValidationReplay() {
            try {
                CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
                if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 32, "ExtractValidationReplay"); }
                string outputFileName = Server::currentMapRecordsValidationReplay + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
                CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
                if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 35, "ExtractValidationReplay"); }
                CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, GetApp().RootMap, authorGhost);
                if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 37, "ExtractValidationReplay"); }
                while (taskResult.IsProcessing) { yield(); }
                if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 39, "ExtractValidationReplay"); }
                log("Replay extracted to: " + outputFileName, LogLevel::Info, 40, "ExtractValidationReplay");
            } catch {
                log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 42, "ExtractValidationReplay");
            }
        }

        int GetValidationReplayTime() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return -1;
            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return -1;
            CGameDataFileManagerScript@ dataFileMgr = playground.DataFileMgr;
            if (dataFileMgr is null) return -1;
            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) return -1;
            return authorGhost.Result.Time;
        }

        string GetValidationReplayFilePathForCurrentMap() {
            if (GetApp().RootMap is null) { log("RootMap is null, no replay can be loaded...", LogLevel::Info, 59, "GetValidationReplayFilePathForCurrentMap"); return ""; }
            string path = Server::currentMapRecordsValidationReplay + "Validation_" + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
            if (!IO::FileExists(path)) { log("Validation replay does not exist at path: " + path + " | This is likely due to the validation replay not yet being extracted.", LogLevel::Info, 61, "GetValidationReplayFilePathForCurrentMap"); return ""; }
            return path;
        }
    }

    namespace Medals {
        class Medal {
            bool medalExists = false;
            uint currentMapMedalTime = 0;
            int timeDifference = 0;

            string displaySavePath = "";
            uint displayTimeDifference = 0;

            bool medalHasExactMatch = false;
            bool reqForCurrentMapFinished = false;

            CGameCtnChallenge@ rootMap = null;

            void AddMedal() {
                if (medalExists) {
                    startnew(CoroutineFunc(FetchSurroundingRecords));
                }
            }

            void OnMapLoad() {
                if (MedalExists()) {
                    ResetState();
                    medalExists = true;
                    FetchMedalTime();
                } else {
                    medalExists = false;
                }
                return;
            }

            void ResetState() {
                medalExists = false;
                currentMapMedalTime = 0;
                timeDifference = 0;
                displaySavePath = "";
                displayTimeDifference = 0;
                medalHasExactMatch = false;
                reqForCurrentMapFinished = false;
            }

            bool MedalExists() {
                int startTime = Time::Now;
                while (Time::Now - startTime < 2000 || GetMedalTime() == 0) { yield(); }
                log("Medal time is: " + GetMedalTime(), LogLevel::Info, 109, "MedalExists");
                return GetMedalTime() > 0;
            }

            void FetchMedalTime() {
                if (medalExists) {
                    currentMapMedalTime = GetMedalTime();
                }
            }

            void FetchSurroundingRecords() {
                if (!medalExists) return;

                string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + get_CurrentMapUID() + "/surround/1/1?score=" + currentMapMedalTime;
                auto req = NadeoServices::Get("NadeoLiveServices", url);
                req.Start();

                while (!req.Finished()) { yield(); }

                if (req.ResponseCode() != 200) {
                    log("Failed to fetch surrounding records, response code: " + req.ResponseCode(), LogLevel::Error, 129, "FetchSurroundingRecords");
                    return;
                }

                Json::Value data = Json::Parse(req.String());
                if (data.GetType() == Json::Type::Null) {
                    log("Failed to parse response for surrounding records.", LogLevel::Error, 135, "FetchSurroundingRecords");
                    return;
                }

                Json::Value tops = data["tops"];
                if (tops.GetType() != Json::Type::Array || tops.Length == 0) {
                    log("Invalid tops data in response.", LogLevel::Error, 141, "FetchSurroundingRecords");
                    return;
                }

                Json::Value top = tops[0]["top"];
                if (top.GetType() != Json::Type::Array || top.Length == 0) {
                    log("Invalid top data in response.", LogLevel::Error, 147, "FetchSurroundingRecords");
                    return;
                }

                uint closestScore = 0;
                int smallestDifference = int(0x7FFFFFFF);
                string closestAccountId;
                int closestPosition = -1;
                bool exactMatchFound = false;

                for (uint i = 0; i < top.Length; i++) {
                    if (i == top.Length / 2) continue;

                    uint score = top[i]["score"];
                    string accountId = top[i]["accountId"];
                    int position = top[i]["position"];
                    int difference = int(currentMapMedalTime) - int(score);

                    log("Found surrounding record: score = " + score + ", accountId = " + accountId + ", position = " + position + ", difference = " + difference, LogLevel::Info, 165, "FetchSurroundingRecords");

                    if (difference == 0) {
                        closestScore = score;
                        closestAccountId = accountId;
                        closestPosition = position;
                        smallestDifference = difference;
                        exactMatchFound = true;
                        break;
                    } else if (difference > 0 && difference < smallestDifference) {
                        closestScore = score;
                        closestAccountId = accountId;
                        closestPosition = position;
                        smallestDifference = difference;
                    }
                }

                if (closestAccountId != "") {
                    timeDifference = smallestDifference;
                    medalHasExactMatch = exactMatchFound;

                    log("Closest record found: score = " + closestScore + ", accountId = " + closestAccountId + ", position = " + closestPosition + ", difference = " + timeDifference, LogLevel::Info, 186, "FetchSurroundingRecords");
                    LoadRecordFromArbitraryMap::LoadSelectedRecord(get_CurrentMapUID(), tostring(closestPosition - 1), "Medal", closestAccountId);
                }

                reqForCurrentMapFinished = true;
            }

            uint GetMedalTime() { return 0; }
        }

        class ChampionMedal : Medal {
            uint GetMedalTime() override {
                int x = -1;
#if DEPENDENCY_CHAMPIONMEDALS
                x = ChampionMedals::GetCMTime();
#endif
                return x;
            }
        }

        class WarriorMedal : Medal {
            uint GetMedalTime() override {
                int x = -1;
#if DEPENDENCY_WARRIORMEDALS
                x = WarriorMedals::GetWMTime();
#endif
                return x;
            }
        }

        class SBVilleMedal : Medal {
            uint GetMedalTime() override {
                int x = -1;
#if DEPENDENCY_SBVILLECAMPAIGNCHALLENGES
                x = SBVilleCampaignChallenges::getChallengeTime();
#endif
                return x;
            }
        }

#if DEPENDENCY_CHAMPIONMEDALS
        namespace ChampMedal {
            ChampionMedal medal;
        }
#endif

#if DEPENDENCY_WARRIORMEDALS
        namespace WarriorMedal {
            WarriorMedal medal;
        }
#endif

#if DEPENDENCY_SBVILLECAMPAIGNCHALLENGES
        namespace SBVille {
            SBVilleMedal medal;
        }
#endif
    }

    /* Pain Pain Go Away 
        // GPS extraction/loading is something I've canned for now, due to lack of knowledge on my part...

        // namespace GPS {
        //     string savePathBase = "";
        //     CGameCtnChallenge@ rootMap = null;
        //     array<GhostData@> ghosts;
        //     string finalSavePath = "";
        //     uint64 CTmRaceResult_VTable_Ptr = 0x0;
        //     int selectedGhostIndex = -1;

        //     bool gpsReplayCanBeLoaded = false;

        //     void LoadReplay() {
        //         if (selectedGhostIndex >= 0 && selectedGhostIndex < ghosts.Length) {
        //             ReplayLoader::LoadReplayFromPath(ghosts[selectedGhostIndex].savePath);
        //         }
        //     }

        //     void OnMapLoad() {
        //         FetchMap();
                
        //         gpsReplayCanBeLoaded = GPSReplayCanBeLoadedForCurrentMap();
        //         if (!gpsReplayCanBeLoaded) { return; }

        //         FetchPath();
        //         FetchVTablePtr();
        //         FetchGhosts();
        //         ConvertGhosts();
        //         SaveReplays();
        //     }

        //     bool GPSReplayCanBeLoadedForCurrentMap() {
        //         if (rootMap is null || rootMap.ClipGroupInGame is null) {
        //             log("rootMap or ClipGroupInGame is null", LogLevel::Error, 278, "GPSReplayCanBeLoadedForCurrentMap");
        //             return false;
        //         }

        //         for (uint i = 0; i < rootMap.ClipGroupInGame.Clips.Length; i++) {
        //             auto clip = rootMap.ClipGroupInGame.Clips[i];
        //             if (clip is null) continue;
        //             for (uint j = 0; j < clip.Tracks.Length; j++) {
        //                 auto track = clip.Tracks[j];
        //                 if (track is null) continue;
        //                 if (track.Name.StartsWith("Ghost:")) {
        //                     return true;
        //                 }
        //             }
        //         }
        //         return false;
        //     }

        //     void FetchPath() {
        //         savePathBase = Server::currentMapRecordsGPS + Text::StripFormatCodes(GetApp().RootMap.MapName) + "_" + GetApp().RootMap.MapInfo.MapUid + "/";
        //     }

        //     void FetchMap() {
        //         @rootMap = GetApp().RootMap;
        //     }

        //     void FetchVTablePtr() {
        //         string ghostFilePath = IO::FromUserGameFolder("Replays/ArbitraryRecordLoader/Dummy/CTmRaceResult_VTable_Ptr.Replay.Gbx");

        //         while (rootMap is null) { yield(); }    // Change to something that waits until the player is loaded.
        //         sleep(1000);                            // Change to something that waits until the player is loaded.

        //         auto dfm = cast<CGameDataFileManagerScript>(GetApp().Network.ClientManiaAppPlayground.DataFileMgr);
        //         if (dfm is null) { log("DataFileMgr is null", LogLevel::Error, 311, "FetchVTablePtr"); return; }

        //         auto task = dfm.Replay_Load(ghostFilePath);
        //         while (task.IsProcessing) { yield(); }

        //         if (task.HasFailed || !task.HasSucceeded) {
        //             log("Failed to load replay file!", LogLevel::Error, 317, "FetchVTablePtr");
        //             log(task.ErrorCode, LogLevel::Error, 318, "FetchVTablePtr");
        //             log(task.ErrorDescription, LogLevel::Error, 319, "FetchVTablePtr");
        //             log(task.ErrorType, LogLevel::Error, 320, "FetchVTablePtr");
        //             log(tostring(task.Ghosts.Length), LogLevel::Error, 321, "FetchVTablePtr");
        //             return;
        //         }

        //         if (task.Ghosts.Length == 0) { log("No ghosts found in the replay file!", LogLevel::Warn, 325, "FetchVTablePtr"); return; }

        //         auto ghost = task.Ghosts[0];
        //         if (ghost is null) { log("Failed to retrieve the ghost from the replay file", LogLevel::Error, 328, "FetchVTablePtr"); return; }

        //         uint64 pointer = Dev::GetOffsetUint64(ghost.Result, 0x0);
        //         log("Hexadecimal pointer: " + Text::FormatPointer(pointer), LogLevel::Info, 331, "FetchVTablePtr");

        //         CTmRaceResult_VTable_Ptr = pointer;
        //     }

        //     array<CGameGhostScript@> GetGhost(CGameDataFileManagerScript@ dfm) {
        //         array<CGameGhostScript@> ghosts;
        //         for (uint i = 0; i < dfm.Ghosts.Length; i++) {
        //             if (dfm.Ghosts[i].Nickname == "cfa844b7-6b53-4663-ac0d-9bdd3ad1af22") {
        //                 ghosts.InsertLast(dfm.Ghosts[i]);
        //             }
        //         }
        //         return ghosts;
        //     }

        //     void FetchGhosts() {
        //         for (uint i = 0; i < rootMap.ClipGroupInGame.Clips.Length; i++) {
        //             auto clip = rootMap.ClipGroupInGame.Clips[i];
        //             for (uint j = 0; j < clip.Tracks.Length; j++) {
        //                 auto track = clip.Tracks[j];
        //                 if (track.Name.StartsWith("Ghost:")) {
        //                     for (uint k = 0; k < track.Blocks.Length; k++) {
        //                         auto block = cast<CGameCtnMediaBlockEntity>(track.Blocks[k]);
        //                         if (block !is null) {
        //                             auto recordData = cast<CPlugEntRecordData>(Dev::GetOffsetNod(block, 0x58));
        //                             if (recordData !is null) {
        //                                 auto newGhost = CGameCtnGhost();
        //                                 Dev::SetOffset(newGhost, 0x2e0, recordData);
        //                                 recordData.MwAddRef();
                                        
        //                                 newGhost.ModelIdentName.SetName("CarSport");
        //                                 newGhost.ModelIdentAuthor.SetName("Nadeo");
        //                                 newGhost.Validate_ChallengeUid.SetName(rootMap.EdChallengeId);

        //                                 auto ptr1 = GetSomeMemory();
        //                                 auto ptr2 = GetSomeMemory();
        //                                 Dev::SetOffset(newGhost, 0x2e8, ptr1);
        //                                 Dev::SetOffset(newGhost, 0x2F0, uint(1));
        //                                 Dev::SetOffset(newGhost, 0x2F4, uint(1));
        //                                 Dev::Write(ptr1, ptr2);
        //                                 Dev::Write(ptr2, uint(2));
        //                                 Dev::Write(ptr2 + 4, uint(0x02000156));
        //                                 Dev::Write(ptr2 + 8, uint(0));
        //                                 Dev::Write(ptr2 + 0xC, uint(45450));
        //                                 Dev::Write(ptr2 + 0x10, uint64(0));
        //                                 Dev::Write(ptr2 + 0x18, uint64(0));
        //                                 Dev::Write(ptr2 + 0x20, uint(0xD100000));
        //                                 Dev::Write(ptr2 + 0x24, uint(1));

        //                                 string ghostName = track.Name.SubStr(6);  // Remove "ghost:" prefix
        //                                 string savePath = savePathBase + ghostName + "_" + Text::Format("%d", i) + ".Replay.Gbx";

        //                                 if (!IO::FolderExists(_IO::File::GetFilePathWithoutFileName(savePath))) {
        //                                     IO::CreateFolder(_IO::File::GetFilePathWithoutFileName(savePath), true);
        //                                 }

        //                                 print(ghostName + " _ " + newGhost.GhostNickname);

        //                                 ghosts.InsertLast(GhostData(ghostName, savePath, newGhost));
        //                             }
        //                         }
        //                     }
        //                 }
        //             }
        //         }
        //     }

        //     uint64 GetSomeMemory() {
        //         CGameGhostScript@ tmp1 = CGameGhostScript();
        //         Dev::SetOffset(tmp1, 0x8, tmp1);
        //         auto ptr = Dev::GetOffsetUint64(tmp1, 0x8);
        //         for (uint i = 0; i < 0x58; i += 8) {
        //             Dev::SetOffset(tmp1, i, uint64(0));
        //         }
        //         return ptr;
        //     }


        //     void ConvertGhosts() {
        //         for (uint i = 0; i < ghosts.Length; i++) {
        //             if (ghosts[i] is null) { log("Ghost at index " + i + " is null", LogLevel::Error, 411, "ConvertGhosts"); continue; }
        //             ghosts[i].ConvertToScript(CTmRaceResult_VTable_Ptr, ghosts[i].ghost);
        //         }
        //     }

        //     void SaveReplays() {
        //         for (uint i = 0; i < ghosts.Length; i++) {
        //             if (ghosts[i] is null) {
        //                 log("Ghost at index " + i + " is null", LogLevel::Error, 419, "SaveReplays");
        //                 continue;
        //             }
        //             ghosts[i].Save(rootMap);
        //         }
        //     }
        // }

        // class GhostData {
        //     int selcetedGhostIndex = -1;

        //     string name;
        //     string savePath;
        //     CGameCtnGhost@ ghost;
        //     CGameGhostScript@ ghostScript;

        //     GhostData(const string &in name, const string &in savePath, CGameCtnGhost@ ghost) {
        //         this.name = name;
        //         this.savePath = savePath;
        //         @this.ghost = ghost;
        //     }

        //     void ConvertToScript(uint64 CTmRaceResult_VTable_Ptr, CGameCtnGhost@ ghost) {
        //         if (ghost is null) { log("Ghost is null in ConvertToScript", LogLevel::Error, 442, "ConvertToScript"); return; }

        //         ghost.MwAddRef();

        //         @ghostScript = CGameGhostScript();
        //         MwId ghostId = MwId();
        //         Dev::SetOffset(ghostScript, 0x18, ghostId.Value);
        //         Dev::SetOffset(ghostScript, 0x20, ghost);
        //         uint64 ghostPtr = Dev::GetOffsetUint64(ghostScript, 0x20);

        //         CGameGhostScript@ tmRaceResultNodPre = CGameGhostScript();
        //         Dev::SetOffset(tmRaceResultNodPre, 0x0, CTmRaceResult_VTable_Ptr);
        //         CTmRaceResultNod@ tmRaceResultNod = Dev::ForceCast<CTmRaceResultNod@>(tmRaceResultNodPre).Get();
        //         @tmRaceResultNodPre = null;
        //         Dev::SetOffset(tmRaceResultNod, 0x18, ghostPtr + 0x28);
        //         tmRaceResultNod.MwAddRef();

        //         Dev::SetOffset(ghostScript, 0x28, tmRaceResultNod);
        //     }

        //     void Save(CGameCtnChallenge@ rootMap) {
        //         if (ghostScript is null) { log("GhostScript is null in Save for ghost " + name, LogLevel::Error, 463, "Save"); return; }

        //         print(savePath);
        //         print(rootMap.MapName);
        //         print(ghostScript.Nickname);

        //         CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
        //         CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(savePath, rootMap, ghostScript);
        //         if (taskResult is null) {
        //             log("Replay task returned null for ghost " + name, LogLevel::Error, 472, "Save");
        //         }
        //     }
        // }
    */
}