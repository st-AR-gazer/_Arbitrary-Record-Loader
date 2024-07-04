string s_currMap = "";
bool mapRecordsLoaded = false;
string mapUID = "";

string s_currMapName = "";
string mapName;

[Setting category="General" name="Enable Ghosts" hidden]
bool g_enableGhosts = true;

void MapCoro() {
    while(true) {
        sleep(273);
        if (!g_enableGhosts) continue;
        if (s_currMap != CurrentMap) {
            s_currMap = CurrentMap;
            s_currMapName = CurrentMapName;
            mapRecordsLoaded = false;
            CurrentMapRecords::ValidationReplay::validationReplayCanBeLoaded = CurrentMapRecords::ValidationReplay::ValidationReplayCanBeLoadedForCurrentMap();
            // CurrentMapRecords::GPS::gpsReplayCanBeLoaded = CurrentMapRecords::GPS::GPSReplayCanBeLoadedForCurrentMap(); // GPS on hold for now...

            if (!mapRecordsLoaded) {
                ReplayLoader::LoadReplayAfterFileExplorer();
                mapRecordsLoaded = true;
                mapUID = s_currMap;
                mapName = s_currMapName;
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

string get_CurrentMapName() {
    if (_Game::IsMapLoaded()) {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app is null) return "";
        CGameCtnChallenge@ map = app.RootMap;
        if (map is null) return "";
        return map.MapInfo.Name;
    }
    return "";
}