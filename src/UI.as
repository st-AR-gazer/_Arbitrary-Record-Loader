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
        if (UI::Begin("Load arbitrary Records", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
            UI::BeginTabBar("Tabs");
            if (UI::BeginTabItem("Local Files")) {
                RenderTab_LocalFiles();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Current Loaded Records")) {
                RenderTab_CurrentLoadedRecords();
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
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE \nNO CARSWAP GATES ON THE CURRENT MAP.");
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
        RecordManager::RemoveAllRecords();
    }
}

//////////////////// Render Current Loaded Records Tab /////////////////////

MwId recordID;

void RenderTab_CurrentLoadedRecords() {
    // UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE \nNO CARSWAP GATES ON THE CURRENT MAP.");
    // UI::Separator();

    // recordID = UI::InputText("RecordID", recordID);
    // UI::SameLine();
    if (UI::Button("Remove Specific Record")) {        // TODO: Crate a loop that loops through all the current records and make a dropdown weather you can select the record you
        RecordManager::RemoveInstanceRecord(recordID); // want to remove based on it's MwId and also display the record's name (maybe just dossard will do?). Should probably be done in RecordManager::
    }

    if (UI::Button("Remove All Records")) {
        RecordManager::RemoveAllRecords();
    }

}


//////////////////// Render Saved Ghosts and Replays Tab /////////////////////

void RenderTab_SavedGhostsAndReplays() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE \nNO CARSWAP GATES ON THE CURRENT MAP.");
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

    array<string> files = /*IO::IndexFolder(Server::savedJsonDirectory)*/ { "test.json" };
    UI::Text("Saved Runs:");

    for (uint i = 0; i < files.Length; i++) {
        // string fileName = files[i];
        // string jsonContent = _IO::File::ReadFileToEnd(Server::savedJsonDirectory + fileName);
        // Json::Value json = Json::Parse(jsonContent);

        
        // if (json.GetType() == Json::Type::Object && json.HasKey("content")) {
        //     UI::Text("FileName: " + json["content"]["FileName"]);
        //     UI::Text("FromLocalFile: " + tostring(json["content"]["FromLocalFile"]));
        //     UI::Text("FilePath: " + json["content"]["FilePath"]);

        //     if (UI::Button("Load " + fileName)) {
        //         if (json["content"]["FromLocalFile"]) {
        //             ProcessSelectedFile(json["content"]["FilePath"]);
        //         } else {
        //             NotifyWarn("Func not implemented yet..."); // TODO: Implement this :xdd:
        //         }
        //     }
        // } else {
        //     UI::Text("Error reading " + fileName);
        // }
    }
}

//////////////////// Render Other Specific UIDs Tab /////////////////////

void RenderTab_OtherSpecificUIDs() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE \nNO CARSWAP GATES ON THE CURRENT MAP.");
    // UI::Separator();

    // string downloadPath;
    // string selectedJsonFile;
    // string downloadedContent;
    // array<string> jsonFiles = GetAvailableJsonFiles();
    // int selectedIndex = 0;

    // UI::InputText("Download Provided from external", downloadPath);
    
    // if (UI::Button("Download Provided")) {
    //     if (_IO::File::GetFileExtension(downloadPath).ToLower() != "json" && _IO::File::GetFileExtension(downloadPath).ToLower() != ".json") {
    //         NotifyWarn("Error | Invalid file extension.");
    //     } else if (downloadPath != "") {
    //         string destinationPath = Server::specificDownloadedJsonFilesDirectory + _IO::File::GetFileName(downloadPath);
    //         _Net::DownloadFileToDestination(downloadPath, destinationPath);
    //         jsonFiles = GetAvailableJsonFiles();
    //     } else {
    //         NotifyWarn("Error | No Json Download provided.");
    //     }
    // }

    // UI::Separator();
    // if (UI::BeginCombo("Select JSON File", selectedJsonFile)) {
    //     for (uint i = 0; i < jsonFiles.Length; i++) {
    //         bool isSelected = (selectedIndex == int(i));
    //         if (UI::Selectable(jsonFiles[i], isSelected)) {
    //             selectedIndex = i;
    //             selectedJsonFile = jsonFiles[i];
    //             downloadedContent = LoadJsonContent(selectedJsonFile);
    //         }
    //         if (isSelected) {
    //             UI::SetItemDefaultFocus();
    //         }
    //     }
    //     UI::EndCombo();
    // }

    // if (downloadedContent != "") {
    //     Json::Value json = Json::Parse(downloadedContent);
    //     if (json.GetType() == Json::Type::Object && json.HasKey("maps")) {
    //         Json::Value maps = json["maps"];
    //         for (uint i = 0; i < maps.Length; i++) {
    //             Json::Value map = maps[i];
    //             if (map.HasKey("files")) {
    //                 UI::Text("Title: " + map["title"]);
    //                 UI::Text("Description: " + map["description"]);
    //                 UI::Separator();

    //                 Json::Value files = map["files"];
    //                 for (uint j = 0; j < files.Length; j++) {
    //                     Json::Value file = files[j];
    //                     string fileName = file["fileName"];
    //                     string filePath = file["filePath"];

    //                     UI::Text("File Name: " + fileName);
    //                     if (UI::Button("Load " + fileName)) {
    //                         ProcessSelectedFile(filePath);
    //                     }
    //                     UI::Text("File Path: " + filePath);
    //                     UI::Separator();
    //                 }
    //             }
    //         }
    //     } else {
    //         UI::Text("Failed to parse downloaded JSON content.");
    //     }
    // }
}

array<string> GetAvailableJsonFiles() {
    // array<string> jsonFiles;
    // if (IO::FolderExists(Server::specificDownloadedJsonFilesDirectory) == false) {
    //     _IO::Folder::RecursiveCreateFolder(Server::specificDownloadedJsonFilesDirectory);
    // }
    // array<string> files = IO::IndexFolder(Server::specificDownloadedJsonFilesDirectory);
    // for (uint i = 0; i < files.Length; i++) {
    //     jsonFiles.InsertLast(_IO::File::GetFileName(files[i]));
    // }
    // return jsonFiles;
    return { "test.json" };
}
string LoadJsonContent(const string &in fileName) {
    // string filePath = Server::specificDownloadedJsonFilesDirectory + fileName;
    // return _IO::File::ReadFileToEnd(filePath);
    return fileName;
}

//////////////////// Render Load Ghost from Map Tab /////////////////////

void RenderTab_LoadGhostFromMap() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE \nNO CARSWAP GATES ON THE CURRENT MAP.");
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

int selectedYear = -1;
int selectedSeason = -1;
int selectedMap = -1;
string selectedOffset = "";

string Official_MapUID;

array<int> years;
array<string> seasons;
array<string> maps;

void RenderTab_OfficialMaps() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE \nNO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    if (UI::Button("Reset Selections")) {
        OfficialManager::UI::UpdateYears();
        OfficialManager::UI::UpdateSeasons();
        OfficialManager::UI::UpdateMaps();
    }

    // Year Dropdown
    if (UI::BeginCombo("Year", selectedYear == -1 ? "Select Year" : tostring(years[selectedYear]))) {
        for (uint i = 0; i < years.Length; i++) {
            bool isSelected = (selectedYear == int(i));
            if (UI::Selectable(tostring(years[i]), isSelected)) {
                selectedYear = i;
            }
            if (isSelected) {
                UI::SetItemDefaultFocus();
            }
        }
        UI::EndCombo();
    }
    UI::SameLine();
    // Season Dropdown
    if (UI::BeginCombo("Season", selectedSeason == -1 ? "Select Season" : seasons[selectedSeason])) {
        for (uint i = 0; i < seasons.Length; i++) {
            bool isSelected = (selectedSeason == int(i));
            if (UI::Selectable(seasons[i], isSelected)) {
                selectedSeason = i;
            }
            if (isSelected) {
                UI::SetItemDefaultFocus();
            }
        }
        UI::EndCombo();
    }
    UI::SameLine();
    // Map Dropdown
    if (UI::BeginCombo("Map", selectedMap == -1 ? "Select Map" : maps[selectedMap])) {
        for (uint i = 0; i < maps.Length; i++) {
            bool isSelected = (selectedMap == int(i));
            if (UI::Selectable(maps[i], isSelected)) {
                selectedMap = i;
            }
            if (isSelected) {
                UI::SetItemDefaultFocus();
            }
        }
        UI::EndCombo();
    }

    // Offset Input
    selectedOffset = UI::InputText("Offset", selectedOffset);

    UI::Separator();

    Official_MapUID = OfficialManager::HandlingUserInput::FetchMapUID();

    /*Official_MapUID = */UI::/*Input*/Text(OfficialManager::HandlingUserInput::FetchMapUID()/*, Official_MapUID*/);

    // Load Button
    if (UI::Button("Load Record")) {
        OfficialManager::HandlingUserInput::LoadSelectedRecord();
    }
}


//////////////////// Render Current Map Ghost Tab /////////////////////

void RenderTab_CurrentMapGhost() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE \nNO CARSWAP GATES ON THE CURRENT MAP.");
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