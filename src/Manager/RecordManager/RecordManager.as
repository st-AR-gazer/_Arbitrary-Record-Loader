namespace RecordManager {

    void RemoveAllRecords_KeepReferences() {
        if (GetApp().PlaygroundScript is null) return;
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_RemoveAll();
        log("All ghosts removed.", LogLevel::Info, 9, "RemoveAllRecords");
    }

    void RemoveAllRecords() {
        if (GetApp().PlaygroundScript is null) return;

        auto dataFileMgr = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        auto newGhosts = dataFileMgr.Ghosts;

        for (uint i = 0; i < newGhosts.Length; i++) {
            CGameGhostScript@ ghost = cast<CGameGhostScript>(newGhosts[i]);
            RemoveInstanceRecord(ghost.Id);
        }
    }

    void RemoveInstanceRecord(MwId instanceId) {
        if (GetApp().PlaygroundScript is null) return;

        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_Remove(instanceId);
        log("Record with the MwID of: " + instanceId.GetName() + " removed.", LogLevel::Info, 31, "RemoveInstanceRecord");
    }

    void RemovePBRecord() {
        if (GetApp().PlaygroundScript is null) return;

        auto dataFileMgr = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        auto newGhosts = dataFileMgr.Ghosts;

        // More to "Features::LRBasedOnCurrentMap::PB::PBManager::RemovePBRecord"

        for (uint i = 0; i < newGhosts.Length; i++) {
            CGameGhostScript@ ghost = cast<CGameGhostScript>(newGhosts[i]);
            if (ghost.Nickname == "PB") {
                RemoveInstanceRecord(ghost.Id);
                return;
            }
        } 
    }

    void set_RecordDossard(MwId instanceId, const string &in dossard, vec3 color = vec3()) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_SetDossard(instanceId, dossard, color);
        log("Record dossard set.", LogLevel::Info, 53, "RemovePBRecord");
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
        log("Ghost added with offset.", LogLevel::Info, 71, "AddRecordWithOffset");
    }

    string get_RecordNameFromId(MwId id) {
        auto dfm = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        if (dfm is null) return "";
        auto ghosts = dfm.Ghosts;
        if (ghosts.Length == 0) return "";

        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Id.Value == id.Value) {
                return ghosts[i].Nickname;
            }
        }
        return "";
    }

    MwId[] get_RecordIdFromName(const string &in name) {
        array<MwId> ids;

        auto dfm = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        if (dfm is null) return "";
        auto ghosts = dfm.Ghosts;
        if (ghosts.Length == 0) return "";

        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Nickname == name) {
                ids.InsertLast(ghosts[i].Id);
            }
        }
        return ids;
    }

    string get_GhostInfo(MwId id) {
        auto dfm = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        if (dfm is null) return "";
        auto ghosts = dfm.Ghosts;
        if (ghosts.Length == 0) return "";

        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Id.Value == id.Value) {
                auto ghost = ghosts[i];
                
                dictionary ghostInfo;

                ghostInfo["Nickname"] = ghost.Nickname;
                ghostInfo["Trigram"] = ghost.Trigram;
                ghostInfo["CountryPath"] = ghost.CountryPath;
                ghostInfo["Time"] = ghost.Result.Time;
                ghostInfo["StuntScore"] = ghost.Result.Score;
                ghostInfo["MwId"] = ghost.Id.Value;

                return ghostInfo;
            }
        }
        return "No ghost selected.";
    }

    // Not used for now, as this was mostly needed for "GPS" research, I've decided to keep the ghost and function around just in case I work on it more in the future tho :xdd:.
    void AddVTableGhost() {
        auto dfm = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        if (dfm is null) return;
        auto ghosts = dfm.Ghosts;
        if (ghosts.Length == 0) return;

        for (uint i = 0; i < ghosts.Length; i++) {
            if (ghosts[i].Nickname == "cfa844b7-6b53-4663-ac0d-9bdd3ad1af22") {
                log("VTable ghost already exists.", LogLevel::Info, 9, "AddVTableGhost");
                return;
            } else {
                loadRecord.LoadVTableRecord();
            }
        }
    }
}