namespace ToggleGhostMgr {
    class GhostData {
        string playerId;
        int offset;

        string name;
        int score;
        bool isLoaded;

        GhostData() {
            isLoaded = false;
        }
    }
}


namespace ToggleGhostMgr {
    array<LoadedRecords_Widget@> lr_w_s;

    class LoadedRecords_Widget {
        string pid;
        int offset;

        string name;
        int score;
        bool isLoaded;

        GhostData() {
            isLoaded = false;
        }
    }

    const string CUSTOM_EVENT_TOGGLE_GHOST = "TMGame_Record_ToggleGhost";

    void ToggleGhost(const string &in playerId) {
        if (playerId.Length == 0) { log("ToggleGhost: Player ID is empty.", LogLevel::Warn, 20, "ToggleGhost"); return; }

        LoadedRecords_Widget@ ghost = FindGhostByPlayerId(playerId);
        if (ghost !is null) {
            if (ghost.isLoaded) {
                UnloadGhost(playerId);
            } else {
                LoadGhost(playerId, ghost.offset);
            }
        }
    }

    void LoadGhost(const string &in playerId, int offset) {
        if (playerId.Length == 0) {
            log("LoadGhost: Player ID is empty.", LogLevel::Warn, 20, "LoadGhost");
            return;
        }

        LoadedRecords_Widget@ ghost = FindGhostByPlayerId(playerId);
        if (ghost !is null && ghost.isLoaded) {
            log("LoadGhost: Ghost with Player ID " + playerId + " is already loaded.", LogLevel::Warn, 20, "LoadGhost");
            return;
        }

        string[] eventData = { playerId, tostring(offset) };
        MLHook::Queue_SH_SendCustomEvent(CUSTOM_EVENT_TOGGLE_GHOST, eventData);

        if (offset >= int(lr_w_s.Length)) {
            lr_w_s.Resize(offset + 1);
        }
        @lr_w_s[offset] = LoadedRecords_Widget();
        lr_w_s[offset].pid = playerId;
        lr_w_s[offset].offset = offset;
        lr_w_s[offset].isLoaded = true;
    }

    void UnloadGhost(const string &in playerId) {
        if (playerId.Length == 0) {
            log("UnloadGhost: Player ID is empty.", LogLevel::Warn, 20, "UnloadGhost");
            return;
        }

        LoadedRecords_Widget@ ghost = FindGhostByPlayerId(playerId);
        if (ghost is null || !ghost.isLoaded) {
            log("UnloadGhost: Ghost with Player ID " + playerId + " is not loaded.", LogLevel::Warn, 20, "UnloadGhost");
            return;
        }

        string[] eventData = { playerId };
        MLHook::Queue_SH_SendCustomEvent(CUSTOM_EVENT_TOGGLE_GHOST, eventData);

        for (uint i = 0; i < lr_w_s.Length; i++) {
            if (lr_w_s[i] !is null && lr_w_s[i].pid == playerId) {
                @lr_w_s[i] = null;
            }
        }
    }


    LoadedRecords_Widget@ FindGhostByPlayerId(const string &in playerId) {
        for (uint i = 0; i < lr_w_s.Length; i++) {
            if (lr_w_s[i] !is null && lr_w_s[i].pid == playerId) {
                return lr_w_s[i];
            }
        }
        return null;
    }


    void UpdateLoadedGhosts(const string &in pid, int offset) {
        if (pid.Length == 0) { log("UpdateLoadedGhosts: Player ID is empty.", LogLevel::Warn, 20, "UpdateLoadedGhosts"); return; }

        LoadedRecords_Widget@ ghost = FindGhostByPlayerId(pid);
        if (ghost is null) {
            log("No ghost exists for this, it was not loaded with this plugin, adding it as visible anyway.", LogLevel::Warn, 20, "UpdateLoadedGhosts");
            @ghost = LoadedRecords_Widget();
            ghost.pid = pid;
            ghost.offset = offset;
            ghost.isLoaded = true;
            return;
        }

        ghost.isLoaded = !ghost.isLoaded;
        ghost.offset = offset;
    }
}



//CustomEvent(TMGame_Record_ToggleGhost, {"758913de-7ea1-4d5d-9d3f-b8b19670c2a4", "3"}, Source=PG_SendCE)