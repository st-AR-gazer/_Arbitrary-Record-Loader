[Setting category="General" name="Window Open"]
bool S_windowOpen = false;

void RenderMenu() {
    if (UI::MenuItem(Colorize(Icons::SnapchatGhost + Icons::Magic + Icons::FileO, {"#aaceac", "#c5d0a8", "#6ec9a8"}) + "\\$g" + " Arbitrary Ghost/Replay Loader", "", S_windowOpen)) {
        S_windowOpen = !S_windowOpen;
    }
}

void RenderInterface() {
    FILE_EXPLORER_BASE_RENDERER(); // Required for the file explorer to work.
    Features::Hotkeys::HKInterfaceModule::RenderInterface(); // Required for the hotkeys popup to work.


    // If PlaygroundScript is null, it means that we are on a server, and not in a local playground. This means that loading records through ".Replay_Add" is not possible,
    // and we then have to use MLHooks "MLHook::Queue_SH_SendCustomEvent("TMGame_Record_ToggleGhost", {pid})" to laod a record. There are still a couple of ways to get the 
    // pid, even without a local playground script, but it is not as easy as just using ".Replay_Add", since we can do less overall we also want to restrict the UI

    if (GetApp().PlaygroundScript !is null) {

        if (S_windowOpen) {
            // UI::SetNextWindowSize(670, 300, UI::Cond::FirstUseEver);
            if (UI::Begin(Icons::UserPlus + " Load arbitrary Records", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
                UI::BeginTabBar("Tabs");
                if (UI::BeginTabItem(Icons::Users + " " + Icons::Folder + " Local Files")) {
                    Features::LRFromFile::RT_LRFromLocalFiles();
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
                if (UI::BeginTabItem(Icons::Users + " " + Icons::IdCard + " Player Id")) {
                    Features::LRFromPlayerId::RT_LRFromPlayerID();
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
                if (UI::BeginTabItem(Icons::Users + " " + Icons::IdCard + " Player Id")) {
                    Features::LRFromPlayerId::RT_LRFromPlayerID();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Map + " " + Icons::Download + " This Map")) {
                    Features::LRFromThisMap::RT_LRFromThisMap();
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Users + Icons::Info + " Loaded")) {
                    Features::CRInfo::RT_CRInfo();
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