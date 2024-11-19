namespace RecordManager {

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
    
}