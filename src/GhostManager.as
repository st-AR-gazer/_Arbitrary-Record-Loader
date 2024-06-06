dictionary ghostStates;

[Setting category="General" name="Replay File Path"]
string g_replayFilePath = "";

[Setting category="General" name="Load Replay Hotkey"]
VirtualKey g_loadReplayHotkey = VirtualKey::F9;

void Update(float dt) {
    if (IsInMap()) return;

    CheckHotkey();
}

void CheckHotkey() {
    if (UI::IsKeyPressed(g_loadReplayHotkey)) {
        LoadReplayFromFile(g_replayFilePath);
    }
}

void LoadReplayFromFile(const string &in filePath) {
    if (filePath == "") {
        NotifyError("Replay file path is empty.");
        return;
    }

    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app is null) return;

    auto netClient = cast<CTrackManiaNetwork>(app.Network);
    if (netClient is null) return;

    auto gamePlayground = cast<CSmArenaClient>(netClient.ClientManiaAppPlayground.Playground);
    if (gamePlayground is null) return;

    CGameReplayScriptPlayer@ replayPlayer = cast<CGameReplayScriptPlayer>(netClient.ReplayPlayer);
    if (replayPlayer is null) return;

    replayPlayer.ReplayFilename = filePath;
    replayPlayer.Load();
    NotifyInfo("Loaded replay: " + filePath);
}

void ToggleGhost(const string &in playerId, bool enable) {
    if (!permissionsOkay) return;

    bool currentState;
    if (ghostStates.Get(playerId, currentState)) {
        if (currentState == enable) {
            return;
        }
    }

    log((enable ? "Enabling" : "Disabling") + " ghost for playerId: " + playerId, LogLevel::Info, 121, "ToggleGhost");
    MLHook::Queue_SH_SendCustomEvent(g_MLHookCustomEvent, {playerId});
    ghostStates[playerId] = enable;
}
