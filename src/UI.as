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
        UI::SetNextWindowSize(670, 300, UI::Cond::FirstUseEver);
        if (UI::Begin("Load arbitrary Ghost or Replay", S_windowOpen)) {
            UI::BeginTabBar("Tabs");
            if (UI::BeginTabItem("Local Files")) {
                RenderTab_LocalFiles();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Saved Ghosts and Replays")) {
                RenderTab_SavedGhostsAndReplays();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Load Ghost from Map")) {
                RenderTab_LoadGhostFromMap();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Other Specific UIDs")) {
                RenderTab_OtherSpecificUIDs();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Official Maps")) {
                RenderTab_OfficialMaps();
                UI::EndTabItem();
            }
            UI::EndTabBar();
        }
        UI::End();
    }
}

void RenderTab_LocalFiles() {
    if (UI::Button("Open File Explorer")) {
        _IO::FileExplorer::OpenFileExplorer(true, IO::FromUserGameFolder("Replays/"), "", { "replay", "ghost" });
    }

    string filePath = _IO::FileExplorer::Exports::GetExportPath();
    UI::Text("Selected File: " + filePath);
    filePath = UI::InputText("File Path", filePath);

    if (UI::Button("Load Ghost or Replay")) {
        ProcessSelectedFile(filePath);
    }

    if (UI::Button("Save Ghost/Replay")) {
        SaveRecordPath();
    }

    if (UI::Button("Remove All Ghosts")) {
        GhostLoader::RemoveAllGhosts();
    }
}

void RenderTab_SavedGhostsAndReplays() {
    if (UI::Button("Open Saved Folder")) {
        _IO::FileExplorer::OpenFileExplorer(true, Server::savedFilesDirectory, "", { "replay", "ghost" });
    }

    string filePath = _IO::FileExplorer::Exports::GetExportPath();
    if (filePath != "") {
        UI::Text("Selected File: " + filePath);

        if (UI::Button("Load Ghost or Replay")) {
            ProcessSelectedFile(filePath);
        }
    }

    UI::Text("Current selected file: " );
    UI::InputText("File Path", _IO::FileExplorer::Exports::GetExportPath());

    if (UI::Button("Pin Run")) {
        // Placeholder for pin functionality here
    }

    UI::Text("Pinned Runs:");
    // Placeholder for displaying pinned runs
}

void RenderTab_OtherSpecificUIDs() {
    UI::Text("This is a placeholder for loading maps from a JSON file.");
}

void RenderTab_LoadGhostFromMap() {
    UI::Text("Build a request: ");
    UI::Separator();

    string ghostPosition = "";

    mapUID = UI::InputText("Map UID", mapUID);
    ghostPosition = UI::InputText("Ghost Position", ghostPosition);

    if (UI::Button("Fetch Ghost")) {
        // FetchGhostFromMap(mapUID, ghostPosition);
    }

    UI::Separator();
}

void RenderTab_OfficialMaps() {
    UI::Text("This is a placeholder for loading official maps.");
}


void CheckFileExplorerSelection() {
    while (true) {
        yield();
        string filePath = _IO::FileExplorer::Exports::GetExportPath();
        if (filePath != "") {
            filePath = filePath;
            break;
        }
    }
}

void ProcessSelectedFile(const string &in filePath) {
    string fileExt = _IO::FileExplorer::Exports::GetExportPathFileExt().ToLower();
    if (fileExt == "replay") {
        ReplayLoader::LoadReplay(filePath);
    } else if (fileExt == "ghost") {
        GhostLoader::LoadGhost(filePath);
    } else {
        NotifyWarn("Error | Unsupported file type.");
    }
}