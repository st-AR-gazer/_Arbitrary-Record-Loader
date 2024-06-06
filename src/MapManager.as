string s_currMap = "";

CTrackMania@ get_app() {
    return cast<CTrackMania>(GetApp());
}

CGameManiaAppPlayground@ get_cmap() {
    auto app = get_app();
    if (app is null) return null;
    return app.Network.ClientManiaAppPlayground;
}

bool IsInMap() {
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app is null) return false;

    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    return !(playground is null || playground.Arena.Players.Length == 0);
}

string get_CurrentMap() {
    if (IsInMap()) {
        auto app = get_app();
        if (app is null) return "";
        auto map = app.RootMap;
        if (map is null) return "";
        return map.MapInfo.MapUid;
    }
    return "";
}
