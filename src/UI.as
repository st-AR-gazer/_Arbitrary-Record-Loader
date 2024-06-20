[Setting category="General" name="Window Open"]
bool S_windowOpen = false;

void RenderMenu() {
    if (UI::MenuItem(Icons::SnapchatGhost + Icons::Magic + Icons::Spinner + Icons::FileO + "Arbitrary Ghost/Replay Loader", "", S_windowOpen)) {
        S_windowOpen = !S_windowOpen;
    }
}

// Icons:: | Magic + Exchange + Spinner + ()

void RenderInterface() {
    UI::SetNextWindowSize(700, 400, UI::Cond::FirstUseEver);
    if (UI::Begin(Colorize(Icons::SnapchatGhost + Icons::Magic + Icons::Spinner + Icons::FileO + " " + "Aebitrary Ghost/Replay Loader"), UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize)) {
        UI::BeginTabBar("MainTabBar", S_windowOpen, UI::TabBarFlags::Reorderable); //
        if (UI::BeginTabItem("Local Files")) {
            RenderLocalFilesTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Load record from JSON")) {
            RenderJsonTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Official Maps")) {
            RenderOfficialMapsTab();
            UI::EndTabItem();
        }
        UI::EndTabBar(); //
    }
    UI::End();
}

void RenderLocalFilesTab() {
    if (UI::Button("Open File Explorer")) {
        OpenFileExplorerWindow();
    }

    string filePath = "";
    filePath = UI::InputText("File Path", filePath);

    if (UI::Button("Load Ghost or Replay")) {
        ProcessSelectedFile(filePath);
    }
}

void RenderJsonTab() {
    UI::Text("This is a placeholder for loading maps from a JSON file.");
}

void RenderOfficialMapsTab() {
    UI::Text("This is a placeholder for loading official maps.");
}

void OpenFileExplorerWindow() {
    _IO::FileExplorer::OpenFileExplorer(true, IO::FromUserGameFolder("Replays/"), "", { "replay", "ghost" });
    startnew(CheckFileExplorerSelection);
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
    string fileExt = _IO::FileExplorer::Exports::GetExportPathFileExt();
    if (fileExt.ToLower() == "replay") {
        ReplayLoader::LoadReplay(filePath);
    } else if (fileExt.ToLower() == "ghost") {
        GhostLoader::LoadGhost(filePath);
    } else {
        NotifyWarn("Error | Unsupported file type.");
    }
}