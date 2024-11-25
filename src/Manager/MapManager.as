namespace MapTracker {
    string oldMapUid = "";

    [Setting category="General" name="Enable Ghosts" hidden]
    bool enableGhosts = true;

    void MapMonitor() {
        while (true) {    
            sleep(273);

            if (!enableGhosts) continue;

            if (HasMapChanged()) {
                while (!_Game::IsPlayingMap()) yield();

                AllowCheck::InitializeAllowCheckWithTimeout(2000);
                if (AllowCheck::ConditionCheckMet()) {
                    // 

                    Features::LRBasedOnCurrentMap::ValidationReplay::OnMapLoad();
                    Features::LRBasedOnCurrentMap::Medals::OnMapLoad();
                    // Features::LRBasedOnCurrentMap::GPS::OnMapLoad();
                    
                    // 
                    
                } else {
                    NotifyWarn("Map is not allowed to load records: " + AllowCheck::DissalowReason());
                }
            }

            if (HasMapChanged()) oldMapUid = get_CurrentMapUID();
        }
    }

    bool HasMapChanged() {
        return oldMapUid != get_CurrentMapUID();
    }
}

string get_CurrentMapUID() {
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
