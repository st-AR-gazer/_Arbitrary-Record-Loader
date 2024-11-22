[Setting category="General" name="Window Open"]
bool S_windowOpen = false;

void RenderMenu() {
    if (UI::MenuItem(Colorize(Icons::SnapchatGhost + Icons::Magic + Icons::FileO, {"#aaceac", "#c5d0a8", "#6ec9a8"}) + "\\$g" + " Arbitrary Ghost/Replay Loader", "", S_windowOpen)) {
        S_windowOpen = !S_windowOpen;
    }
}

void RenderInterface() {
    FILE_EXPLORER_BASE_RENDERER(); // Required for the file explorer to work.


    // If playground script is null we cannot load records with .Replay_Add (which allows for loading records from other maps, and from local files, so we can only load records from the current map and if we know the playerID of the person we want to get the replay for if playground script is null)
    // and we have to use MLHook, so we want to show a limited UI. 
    if (GetApp().PlaygroundScript !is null) {

        if (S_windowOpen) {
            // UI::SetNextWindowSize(670, 300, UI::Cond::FirstUseEver);
            if (UI::Begin(Icons::UserPlus + " Load arbitrary Records", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
                UI::BeginTabBar("Tabs");
                if (UI::BeginTabItem(Icons::Users + " " + Icons::Folder + " Local Files")) {
                    Features::LRFromFile::RT_LocalFiles();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Users + Icons::Info + " Loaded")) {
                    Features::CRInfo::RT_CRInfo();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Users + " " + Icons::Kenney::Save + " Saved")) {
                    Features::LRFromSaved::RT_LRFromSaved();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Users + " " + Icons::Link + " Link")) {
                    Features::LRFromUrl::RT_LRFromUrl();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Users + " " + Icons::Download + " Profile")) {
                    Features::LRFromProfile::RT_LRFromProfile();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Map + " " + Icons::Download + " Any Map")) {
                    Features::LRFromMapIdentifier::RT_LRFromMapUid();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Map + " " + Icons::Globe + " Official")) {
                    Features::LRFromOfficialMaps::RT_LRFromOfficialMaps();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Map + " Current Map")) {
                    Features::LRBasedOnCurrentMap::RT_LRBasedOnCurrentMap();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::KeyboardO + " Hotkeys")) {
                    Features::Hotkeys::RT_Hotkeys();
                    UI::EndTabItem();
                }
                UI::EndTabBar();
            }
            UI::End();
        }

    } else {

        if (S_windowOpen) {
            // UI::SetNextWindowSize(670, 300, UI::Cond::FirstUseEver);
            if (UI::Begin(Icons::UserPlus + " Load arbitrary Records", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
                UI::BeginTabBar("Tabs");
                if (UI::BeginTabItem(Icons::Users + " Player ID")) {
                    Features::LRFromPlayerId::RT_LocalFiles();
                    UI::EndTabItem();
                }




                if (UI::BeginTabItem(Icons::Users + " " + Icons::Folder + " Local Files")) {
                    Features::LRFromFile::RT_LocalFiles();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Users + Icons::Info + " Loaded")) {
                    Features::CRInfo::RT_CRInfo();
                    UI::EndTabItem();
                }
                UI::EndTabBar();
            }
            UI::End();
        }
    
    }
}

////////////////////////////// TABS //////////////////////////////

//////////////////// Render Loacal Files Tab /////////////////////

//////////////////// Render Current Loaded Records Tab /////////////////////

//////////////////// Render Saved Ghosts and Replays Tab /////////////////////

//////////////////// Render Link Tab /////////////////////

//////////////////// Render Other Specific UIDs Tab /////////////////////

//////////////////// Render Load Ghost from Map Tab /////////////////////

//////////////////// Render Official Maps Tab /////////////////////

//////////////////// Render Current Map Ghost Tab /////////////////////

//////////////////// Render Hotkey Tab /////////////////////

////////////////////////////// End Tabs //////////////////////////////