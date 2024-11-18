[Setting category="General" name="Window Open"]
bool S_windowOpen = false;

void RenderMenu() {
    if (UI::MenuItem(Colorize(Icons::SnapchatGhost + Icons::Magic + Icons::FileO, {"#aaceac", "#c5d0a8", "#6ec9a8"}) + "\\$g" + " Arbitrary Ghost/Replay Loader", "", S_windowOpen)) {
        S_windowOpen = !S_windowOpen;
    }
}

void RenderInterface() {
    FILE_EXPLORER_BASE_RENDERER(); // Required for the file explorer to work.

    if (S_windowOpen) {
        // UI::SetNextWindowSize(670, 300, UI::Cond::FirstUseEver);
        if (UI::Begin(Icons::UserPlus + " Load arbitrary Records", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
            UI::BeginTabBar("Tabs");
            if (UI::BeginTabItem(Icons::Users + " " + Icons::Folder + " Local Files")) {
                Features::LRFromLocalFile::RT_LocalFiles();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Users + Icons::Info + " Loaded")) {
                RenderTab_CurrentLoadedRecords();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Users + " " + Icons::Kenney::Save + " Saved")) {
                RenderTab_SavedGhostsAndReplays();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Users + " " + Icons::Link + " Link")) {
                RenderTab_Link();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Users + " " + Icons::Download + " Predetermined Set")) {
                RenderTab_OtherSpecificUIDs();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Map + " " + Icons::Download + " Any Map")) {
                RenderTab_LoadGhostFromMap();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Map + " " + Icons::Globe + " Official")) {
                RenderTab_OfficialMaps();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Map + " Current Map")) {
                RenderTab_CurrentMapGhost();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::KeyboardO + " Hotkeys")) {
                HotkeyManager::RenderTab_Hotkeys();
                UI::EndTabItem();
            }
            UI::EndTabBar();
        }
        UI::End();
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