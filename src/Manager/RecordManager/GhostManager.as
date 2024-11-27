// Uppon thinking about it for a bit I've decided to remove the GhsotTracker since it wasn't really doing anything, and the data can be gotten from the RecordManager and the game directly instead.

namespace GhostTracker {
/*
    
    // array<CGameGhostScript@> ghosts;
    GhostTracker@ ghostTracker;

    class GhostTracker {
        array<CGameGhostScript@> trackedGhosts;
        array<MwId> removedGhosts;

        void UpdateGhosts() {
            if (GetApp().Network.ClientManiaAppPlayground is null) { log("App or network components not ready", LogLevel::Warn, 14, "UpdateGhosts"); return; }

            auto dataFileMgr = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
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

            log("Ghosts updated, count: " + ghosts.Length + " Normal Ghosts: " + ghostsWithoutNickname + " VTable Ghosts: " + ghostsWithNickname, LogLevel::Info, 40, "UpdateGhosts");
        }

        void AddTrackedGhost(CGameGhostScript@ ghost) {
            if (!IsGhostTracked(ghost.Id)) {
                trackedGhosts.InsertLast(ghost);

                if (ghost.Nickname == "cfa844b7-6b53-4663-ac0d-9bdd3ad1af22") return;
                log("Tracked ghost added: " + ghost.Nickname, LogLevel::Info, 48, "AddTrackedGhost");
            }
        }

        void RemoveTrackedGhost(MwId instanceId) {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                if (trackedGhosts[i].Id.Value == instanceId.Value) {
                    log("Tracked ghost removed: " + trackedGhosts[i].Nickname, LogLevel::Info, 55, "RemoveTrackedGhost");
                    trackedGhosts.RemoveAt(i);
                    removedGhosts.InsertLast(instanceId);
                    return;
                }
            }
        }

        void ClearTrackedGhosts() {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                trackedGhosts.RemoveRange(0, trackedGhosts.Length);
            }
            log("Cleared all tracked ghosts.", LogLevel::Info, 68, "ClearTrackedGhosts");
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

        string get_TrackedGhostNameById(MwId id) {
            for (uint i = 0; i < trackedGhosts.Length; i++) {
                if (trackedGhosts[i].Id.Value == id.Value) {
                    return trackedGhosts[i].Nickname;
                }
            }
            return "";
        }

        string get_TrackedGhostInfo(MwId id) {
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
    
*/
}