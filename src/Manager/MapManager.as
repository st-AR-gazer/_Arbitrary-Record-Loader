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

                uint timeout = 10000;
                uint startTime = Time::Now;
                AllowCheck::InitializeAllowCheck();
                bool conditionMet = false;
                while (!conditionMet) { 
                    if (Time::Now - startTime > timeout) { NotifyWarn("Condition check timed out ("+timeout+" ms was given), assuming invalid state."); break; }
                    yield(); 
                    conditionMet = AllowCheck::ConditionCheckMet();
                }
                if (AllowCheck::ConditionCheckMet()) {
                    print("aaaaaaaaaaaaaaaaaa it worked");
                    // 

                    CurrentMapRecords::ValidationReplay::OnMapLoad();
                    startnew(CoroutineFunc(champMedal.OnMapLoad));
                    startnew(CoroutineFunc(warriorMedal.OnMapLoad));
                    startnew(CoroutineFunc(sbVilleMedal.OnMapLoad));
                    // CurrentMapRecords::GPS::OnMapLoad();
                    
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
