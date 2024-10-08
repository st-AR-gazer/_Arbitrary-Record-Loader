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

            CurrentMapRecords::ValidationReplay::OnMapLoad();
            startnew(CoroutineFunc(champMedal.OnMapLoad));
            startnew(CoroutineFunc(warriorMedal.OnMapLoad));
            startnew(CoroutineFunc(sbVilleMedal.OnMapLoad));
            // CurrentMapRecords::GPS::OnMapLoad();

            AllowCheck::Chester::OnMapLoad();
            AllowCheck::MapCommentCheck::OnMapLoad();

            if (!mapRecordsLoaded) {
                // ReplayLoader::LoadReplayAfterFileExplorer();
                mapRecordsLoaded = true;
                mapUID = s_currMap;
                mapName = s_currMapName;
            }

            RecordManager::GhostTracker::Init();
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