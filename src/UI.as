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
        if (UI::Begin("Load arbitrary Records", S_windowOpen)) {
            UI::BeginTabBar("Tabs");
            if (UI::BeginTabItem("Local Files")) {
                RenderTab_LocalFiles();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Saved Records")) {
                RenderTab_SavedGhostsAndReplays();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Load record from any Map")) {
                RenderTab_LoadGhostFromMap();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Load record from other")) {
                RenderTab_OtherSpecificUIDs();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Official Maps")) {
                RenderTab_OfficialMaps();
                UI::EndTabItem();
            }
            if (ValidationReplay::ValidationReplayExists()) {
                if (UI::BeginTabItem("Current Map Ghost")) {
                    RenderTab_CurrentMapGhost();
                    UI::EndTabItem();
                }
            }
            UI::EndTabBar();
        }
        UI::End();
    }
}

////////////////////////////// TABS //////////////////////////////

//////////////////// Render Loacal Files Tab /////////////////////

void RenderTab_LocalFiles() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR OR MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

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

//////////////////// Render Saved Ghosts and Replays Tab /////////////////////

void RenderTab_SavedGhostsAndReplays() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR OR MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    if (UI::Button("Open Saved Folder")) {
        _IO::FileExplorer::OpenFileExplorer(true, Server::savedFilesDirectory, "", { "replay", "ghost" });
    }

    string filePath = _IO::FileExplorer::Exports::GetExportPath();
    if (filePath != "") {
        UI::Text("Selected File: " + filePath);

        if (UI::Button("Load Selected Record")) {
            ProcessSelectedFile(filePath);
        }
    }

    UI::Text("Current selected file: ");
    UI::InputText("File Path", _IO::FileExplorer::Exports::GetExportPath());

    const string savedJsonDirectory = _IO::File::SafeFromStorageFolder("Server/Saved/JsonData/");

    array<string> files = IO::IndexFolder(savedJsonDirectory);
    UI::Text("Saved Runs:");

    for (uint i = 0; i < files.Length; i++) {
        string fileName = files[i];
        string jsonContent = _IO::File::ReadFileToEnd(savedJsonDirectory + fileName);
        Json::Value json = Json::Parse(jsonContent);
        
        if (json.GetType() == Json::Type::Object && json.HasKey("content")) {
            UI::Text("FileName: " + json["content"]["FileName"]);
            UI::Text("FromLocalFile: " + tostring(json["content"]["FromLocalFile"]));
            UI::Text("FilePath: " + json["content"]["FilePath"]);

            if (UI::Button("Load " + fileName)) {
                if (json["content"]["FromLocalFile"]) {
                    ProcessSelectedFile(json["content"]["FilePath"]);
                } else {
                    NotifyWarn("Func not implemented yet..."); // TODO: Implement this :xdd:
                }
            }
        } else {
            UI::Text("Error reading " + fileName);
        }
    }
}

//////////////////// Render Other Specific UIDs Tab /////////////////////

void RenderTab_OtherSpecificUIDs() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR OR MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    string downloadPath;
    UI::InputText("Download Provided from external", downloadPath);
    
    if (UI::Button("Download Provided")) {
        if (downloadPath != "") {
            
        } else {
            NotifyWarn("Error | No Json Download provided.");
        }
    }
}

//////////////////// Render Load Ghost from Map Tab /////////////////////

void RenderTab_LoadGhostFromMap() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR OR MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    UI::Text("Build a request: ");
    UI::Separator();

    string ghostPosition;
    if (UI::Button("Set MapUID to current map")) {
        mapUID = get_CurrentMap();
    }

    mapUID = UI::InputText("Map UID", mapUID);
    ghostPosition = UI::InputText("Ghost Position", ghostPosition);

    if (UI::Button("Fetch Ghost")) {
        api.GetMapRecords(mapUID, ghostPosition);
    }

    UI::Separator();
}

//////////////////// Render Official Maps Tab /////////////////////

void RenderTab_OfficialMaps() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR OR MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();
    
    UI::Text("This is a placeholder for loading official maps.");
}

//////////////////// Render Current Map Ghost Tab /////////////////////

void RenderTab_CurrentMapGhost() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR OR MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();
    
    UI::Text("\\$0ff" + "WARNING\\$g " + "This uses the old 'Extract Validation Replay' method. Since ghosts were removed from map \nfiles at some point, this will not be possible for maps older than _NN_");
    if (UI::Button("Add validation replay to current run")) {
        ValidationReplay::AddValidationReplay();
    }

    if (UI::Button("Save validation replay")) {
        SaveRecordPath(ValidationReplay::GetValidationReplayFilePath());
    }
}

////////////////////////////// End Tabs //////////////////////////////

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