void Main() {
    PermsCheck();
    if (!permissionsOkay) return;

    @api = NadeoApi();
    MLHook::RequireVersionApi('0.3.1');
    startnew(MapCoro);
}

[Setting category="General" name="Replay File Path"]
string g_replayFilePath = "";

[Setting category="General" name="Load Replay Hotkey"]
VirtualKey g_loadReplayHotkey = VirtualKey::F4;
