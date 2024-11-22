namespace RecordManager {
    array<CGameGhostScript@> ghosts;

    void RemoveAllRecords() {
        // Does technically remove all the ghosts, but the instance isn't cleared...
        // if (GetApp().PlaygroundScript is null) return;
        // auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        // gm.Ghost_RemoveAll();
        // log("All ghosts removed.", LogLevel::Info, 9, "RemoveAllRecords");
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
        log("Record with the MwID of: " + instanceId.GetName() + " removed.", LogLevel::Info, 31, "RemoveInstanceRecord");
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
}