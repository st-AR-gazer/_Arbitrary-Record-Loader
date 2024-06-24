string s_currMap = "";
bool mapRecordsLoaded = false;

string mapUID = "";

[Setting category="General" name="Enable Ghosts" hidden]
bool g_enableGhosts = true;

void MapCoro() {
    while(true) {
        sleep(273);
        if (!g_enableGhosts) continue;
        if (s_currMap != CurrentMap) {
            s_currMap = CurrentMap;
            mapRecordsLoaded = false;
            if (!mapRecordsLoaded) {

                ReplayLoader::CheckReplayLoad();
                mapRecordsLoaded = true;

                mapUID = s_currMap;

            }
        }
    }
}

string get_CurrentMap() {
    if (_Game::IsMapLoaded()) {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app is null) return "";
        CGameCtnChallenge@ map = app.RootMap;
        if (map is null) return "";
        return map.MapInfo.MapUid;
    }
    return "";
}
