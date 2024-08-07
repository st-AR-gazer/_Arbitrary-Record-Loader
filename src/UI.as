[Setting category="General" name="Window Open"]
bool S_windowOpen = false;

void RenderMenu() {
    if (UI::MenuItem(Colorize(Icons::SnapchatGhost + Icons::Magic + Icons::FileO, {"#aaceac", "#c5d0a8", "#6ec9a8"}) + "\\$g" + " Arbitrary Ghost/Replay Loader", "", S_windowOpen)) {
        S_windowOpen = !S_windowOpen;
    }
}

void RenderInterface() {
    FILE_EXPLORER_V1_BASE_RENDERER(); // Required for the file explorer to work.
    // FILE_EXPLORER_BASE_RENDERER(); // Required for the file explorer to work.
    // Temporaryly moved to the main Render script to avoid conflicts with the file explorer while develoption, this should be moved back to the main RenderInterface functions once the file explorer is fully implemented.

    if (S_windowOpen) {
        // UI::SetNextWindowSize(670, 300, UI::Cond::FirstUseEver);
        if (UI::Begin(Icons::UserPlus + " Load arbitrary Records", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
            UI::BeginTabBar("Tabs");
            if (UI::BeginTabItem(Icons::Users + " " + Icons::Folder + " Local Files")) {
                RenderTab_LocalFiles();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Users + Icons::Info + "Current Loaded Records")) {
                RenderTab_CurrentLoadedRecords();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Users + " " + Icons::Kenney::Save + " Saved Records")) {
                RenderTab_SavedGhostsAndReplays();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Users + " " + Icons::Download + " Load record from other")) {
                RenderTab_OtherSpecificUIDs();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Map + " " + Icons::Download + " Load record from any Map")) {
                RenderTab_LoadGhostFromMap();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Map + " " + Icons::Globe + " Official Maps")) {
                RenderTab_OfficialMaps();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Map + " Current Map Ghost")) {
                RenderTab_CurrentMapGhost();
                UI::EndTabItem();
            }
            UI::EndTabBar();
        }
        UI::End();
    }
}

////////////////////////////// TABS //////////////////////////////

//////////////////// Render Loacal Files Tab /////////////////////

void RenderTab_LocalFiles() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    if (UI::Button(Icons::FolderOpen + " Open File Explorer")) {
        _IO::FileExplorer::OpenFileExplorer(true, IO::FromUserGameFolder("Replays/"), "", { "replay", "ghost" });
    }

    string filePath = _IO::FileExplorer::Exports::GetExportPath();
    UI::Text("Selected File: " + filePath);
    filePath = UI::InputText("File Path", filePath);

    if (UI::Button(Icons::Download + Icons::SnapchatGhost + " Load Ghost or Replay")) {
        ProcessSelectedFile(filePath);
    }

    if (UI::Button(Icons::Users + Icons::EyeSlash + " Remove All Ghosts")) {
        RecordManager::RemoveAllRecords();
    }
}

//////////////////// Render Current Loaded Records Tab /////////////////////

MwId selectedRecordID;
bool isDropdownOpen = false;

void RenderTab_CurrentLoadedRecords() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    if (UI::Button("Remove All Records")) {
        log("Remove All Records button clicked", LogLevel::Info, 88, "RenderTab_CurrentLoadedRecords");
        RecordManager::RemoveAllRecords();
    }

    string selectedGhostName = selectedRecordID.Value != MwId().Value 
                               ? RecordManager::GhostTracker::GetTrackedGhostNameById(selectedRecordID) 
                               : "Select a ghost instance";

    if (UI::BeginCombo("Select a ghost instance", selectedGhostName)) {
        if (!isDropdownOpen) {
            RecordManager::GhostTracker::UpdateGhosts();
            isDropdownOpen = true;
        }

        for (uint i = 0; i < RecordManager::GhostTracker::trackedGhosts.Length; i++) {
            auto ghost = RecordManager::GhostTracker::trackedGhosts[i];
            bool isSelected = (selectedRecordID.Value == ghost.Id.Value);
            if (UI::Selectable(ghost.Nickname, isSelected)) {
                selectedRecordID = ghost.Id;
            }
            if (isSelected) {
                UI::SetItemDefaultFocus();
            }
        }
        UI::EndCombo();
    } else {
        isDropdownOpen = false;
    }

    if (selectedRecordID.Value != MwId().Value) {
        string ghostInfo = RecordManager::GhostTracker::GetTrackedGhostInfo(selectedRecordID);
        UI::Text("Selected Record Info:");
        UI::Text(ghostInfo);
    }

    if (UI::Button(Icons::UserTimes + " Remove Specific Record")) {
        log("Remove Specific Record button clicked", LogLevel::Info, 124, "RenderTab_CurrentLoadedRecords");
        RecordManager::RemoveInstanceRecord(selectedRecordID);
        RecordManager::GhostTracker::RefreshTrackedGhosts();
        selectedRecordID = MwId();
    }

    if (UI::Button(Icons::Kenney::Save + " Save Ghost/Replay")) {
        log("Save Ghost button clicked", LogLevel::Info, 131, "RenderTab_CurrentLoadedRecords");
        RecordManager::Save::SaveRecord();
    }
}


    /*if (UI::Button(Icons::Kenney::Save + " Save validation replay")) {
        RecordManager::Save::SaveRecord(CurrentMapRecords::ValidationReplay::GetValidationReplayFilePath());
    }*/

//////////////////// Render Saved Ghosts and Replays Tab /////////////////////

void RenderTab_SavedGhostsAndReplays() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    if (UI::Button(Icons::Folder + "Open Saved Folder")) {
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

    array<string>@ files = IO::IndexFolder(Server::savedJsonDirectory, true);
    UI::Text("Saved Runs:");
    UI::Separator();

    for (uint i = 0; i < files.Length; i++) {
        string fullFilePath = files[i];
        string fileName = _IO::File::GetFileName(fullFilePath);
        if (fileName.EndsWith(".json")) {
            string jsonContent = _IO::File::ReadFileToEnd(Server::savedJsonDirectory + fileName);
            Json::Value json = Json::Parse(jsonContent);


            if (json.GetType() == Json::Type::Object && json.HasKey("content")) {
                Json::Value content = json["content"];

                UI::Text("Nickname: " + string(content["Nickname"]));
                UI::Text("FileName: " + string(content["FileName"]));
                UI::Text("Trigram: " + string(content["Trigram"]));
                UI::Text("Time: " + int(content["Time"]));
                UI::Text("ReplayFilePath: " + string(content["ReplayFilePath"]));
                UI::Text("FullFilePath: " + string(content["FullFilePath"]));
                UI::Text("CountryPath: " + string(content["CountryPath"]));
                if (!bool(content["FromLocalFile"])) UI::Text("FromLocalFile: " + bool(content["FromLocalFile"]));
                UI::Text("StuntScore: " + int(content["StuntScore"]));
                UI::Text("MwId: " + uint(content["MwId Value"]));

                if (UI::Button("Load " + fileName)) {
                    if (bool(content["FromLocalFile"])) {
                        ProcessSelectedFile(string(content["ReplayFilePath"]) + string(content["FileName"]));
                    } else {
                        NotifyWarn("Func not implemented yet... You can only load local files.."); // TODO: Implement this :xdd:
                    }
                }
                UI::SameLine();
                if (UI::Button("Delete " + fileName)) {
                    IO::Delete(Server::savedJsonDirectory + fileName);
                    IO::Delete(Server::savedFilesDirectory + string(content["FileName"]) + ".Replay.Gbx");
                }
                UI::Separator();
            } else {
                UI::Text("Error reading " + fileName);
            }
        }
    }
}


//////////////////// Render Other Specific UIDs Tab /////////////////////

string selectedJsonFile;
array<string> jsonFiles = OtherManager::GetAvailableJsonFiles();
int selectedIndex = 0;
string downloadedContent;
array<Json::Value> mapList;

string newJsonName;

int otherOffset = 0;

void RenderTab_OtherSpecificUIDs() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    string downloadPath;
    UI::InputText("Download URL", downloadPath);
    UI::SameLine();
    if (UI::Button("Download Provided")) {
        OtherManager::StartDownload(downloadPath);
    }
    UI::SameLine();
    if (UI::Button("Create New Download Profile")) {
        OtherManager::IsCreatingProfile = true;
    }
    UI::SameLine();
    if (UI::Button(Icons::Folder + " Profiles Folder")) {
        _IO::OpenFolder(Server::specificDownloadedCreatedProfilesDirectory);
    }
    UI::SameLine();
    if (UI::Button(Icons::Folder + " Downloads Folder")) {
        _IO::OpenFolder(Server::specificDownloadedJsonFilesDirectory);
    }
    UI::SameLine();
    if (UI::Button(Icons::Refresh + " Refresh")) {
        jsonFiles = OtherManager::GetAvailableJsonFiles();
    }

    otherOffset = UI::InputInt("Offset", otherOffset);

    UI::Separator();
    if (UI::BeginCombo("Select JSON File", selectedJsonFile)) {
        for (uint i = 0; i < jsonFiles.Length; i++) {
            bool isSelected = (selectedIndex == int(i));
            if (UI::Selectable(jsonFiles[i], isSelected)) {
                selectedIndex = i;
                selectedJsonFile = jsonFiles[i];
                downloadedContent = OtherManager::LoadJsonContent(selectedJsonFile);
                mapList = OtherManager::GetMapListFromJson(downloadedContent);
            }
            if (isSelected) {
                UI::SetItemDefaultFocus();
            }
        }
        UI::EndCombo();
    }

    UI::Separator();
    if (mapList.Length > 0) {
        for (uint i = 0; i < mapList.Length; i++) {
            Json::Value map = mapList[i];
            if (map.HasKey("mapName") && map.HasKey("mapUid")) {
                UI::Text("Map Name: " + string(map["mapName"]));
                UI::SameLine();
                if (UI::Button("Load Records##" + i)) {
                    LoadRecordFromArbitraryMap::LoadSelectedRecord(map["mapUid"], tostring(otherOffset), "OtherMaps");
                }
                UI::Separator();
            }
        }
    }

    if (OtherManager::IsDownloading) {
        UI::OpenPopup("Downloading");
    }

    if (UI::BeginPopupModal("Downloading", OtherManager::IsDownloading, UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize)) {
        UI::Text("Downloading, please wait...");
        UI::EndPopup();
    }

    if (OtherManager::IsCreatingProfile) {
        UI::OpenPopup("Create New Download Profile");
    }

    if (UI::BeginPopupModal("Create New Download Profile", OtherManager::IsCreatingProfile, UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize)) {
        newJsonName = UI::InputText("JSON Name", newJsonName);

        for (uint i = 0; i < OtherManager::NewProfileMaps.Length; i++) {
            OtherManager::NewProfileMaps[i].mapName = UI::InputText("Map Name##" + i, OtherManager::NewProfileMaps[i].mapName);
            UI::SameLine();
            OtherManager::NewProfileMaps[i].mapUid = UI::InputText("Map UID##" + i, OtherManager::NewProfileMaps[i].mapUid);
            UI::SameLine();
            if (UI::Button("Remove##" + i)) {
                OtherManager::NewProfileMaps.RemoveAt(i);
                i--;
            }
            UI::Separator();
        }

        if (UI::Button("Add Map")) {
            OtherManager::NewProfileMaps.InsertLast(OtherManager::MapEntry());
        }
        UI::SameLine();
        if (UI::Button("Save Profile")) {
            OtherManager::SaveNewProfile(newJsonName);
            OtherManager::IsCreatingProfile = false;
            UI::CloseCurrentPopup();
        }
        UI::SameLine();
        if (UI::Button("Cancel")) {
            OtherManager::IsCreatingProfile = false;
            UI::CloseCurrentPopup();
        }

        UI::EndPopup();
    }
}



//////////////////// Render Load Ghost from Map Tab /////////////////////

string ghostPosition;

void RenderTab_LoadGhostFromMap() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    UI::Text("Build a request: ");
    UI::Separator();

    if (UI::Button("Set MapUID to current map")) {
        mapUID = get_CurrentMap();
    }

    mapUID = UI::InputText("Map UID", mapUID);
    ghostPosition = UI::InputText("Ghost Position", ghostPosition);

    if (UI::Button("Fetch Ghost")) {

        LoadRecordFromArbitraryMap::LoadSelectedRecord(mapUID, ghostPosition, "AnyMap");
    }

    UI::Separator();
}

//////////////////// Render Official Maps Tab /////////////////////

int selectedYear = -1;
int selectedSeason = -1;
int selectedMap = -1;
int selectedOffset = 0;

string Official_MapUID;

array<int> years;
array<string> seasons;
array<string> maps;

void RenderTab_OfficialMaps() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    if (UI::Button("Reset Selections")) {
        OfficialManager::UI::UpdateYears();
        OfficialManager::UI::UpdateSeasons();
        OfficialManager::UI::UpdateMaps();
    }
    UI::SameLine();
    if (UI::Button("Run check for New Campaigns again")) {
        OfficialManager::DownloadingFiles::CheckForNewCampaignIfNeeded();
    }
    UI::SameLine();
    if (UI::Button("Set season year to current")) {
        OfficialManager::UI::SetSeasonYearToCurrent();
    }
    UI::SameLine();
    if (UI::Button("Try to set current map based on name")) {
        OfficialManager::UI::SetCurrentMapBasedOnName();
    }

    // Year Dropdown
    if (UI::BeginCombo("Year", selectedYear == -1 ? "Select Year" : tostring(years[selectedYear]))) {
        for (uint i = 0; i < years.Length; i++) {
            bool isSelected = (selectedYear == int(i));
            if (UI::Selectable(tostring(years[i]), isSelected)) {
                selectedYear = int(i);
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
                selectedSeason = int(i);
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
                selectedMap = int(i);
            }
            if (isSelected) {
                UI::SetItemDefaultFocus();
            }
        }
        UI::EndCombo();
    }

    // Offset Input
    selectedOffset = UI::InputInt("Offset", selectedOffset);

    UI::Separator();

    Official_MapUID = OfficialManager::UI::FetchOfficialMapUID();

    UI::Text(Official_MapUID);

    // Load Button
    if (UI::Button("Load Record")) {
        LoadRecordFromArbitraryMap::LoadSelectedRecord(Official_MapUID, tostring(selectedOffset), "Official");
    }
}


//////////////////// Render Current Map Ghost Tab /////////////////////

void RenderTab_CurrentMapGhost() {
    UI::Text("\\$f00" + "WARNING" + "\\$g " + "LOADING A GHOST THAT CHANGES CAR ON THE CURRENT MAP WILL CRASH THE GAME IF THERE ARE NO CARSWAP GATES ON THE CURRENT MAP.");
    UI::Separator();

    UI::Text("\\$0ff" + "WARNING\\$g " + "This uses the old 'Extract Validation Replay' method. Since ghosts were removed from map \nfiles at some point, this will not be possible for maps older than _NN_");

    if (!CurrentMapRecords::ValidationReplay::ValidationReplayExists()) {
        UI::Text("\\$f00" + "WARNING" + "\\$g " + "No validation replay found for current map.");
    } else {
        UI::Text("\\$0f0" + "Validation Replay found for current map.");
    }
    if (!CurrentMapRecords::ValidationReplay::ValidationReplayExists()) {
        _UI::DisabledButton(Icons::UserPlus + " Add validation replay to current run");
    } else {
        if (UI::Button(Icons::UserPlus + " Add validation replay to current run")) {
            CurrentMapRecords::ValidationReplay::AddValidationReplay();
        }
    }

    // GPS extraction/loading is something I've canned for now, due to lack of knowledge on my part...

    // UI::Separator();
    // if (!CurrentMapRecords::GPS::gpsReplayCanBeLoaded) {
    //     UI::Text("No GPS replays available for the current map.");
    // }

    // UI::Text("GPS Replays:");

    // if (CurrentMapRecords::GPS::ghosts.Length == 1) {
    //     UI::Text(CurrentMapRecords::GPS::ghosts[0].name);
    //     UI::Text("Only one GPS replay found.");
    //     CurrentMapRecords::GPS::selectedGhostIndex = 0;
    // }
    // if (CurrentMapRecords::GPS::selectedGhostIndex > 0) {
    //     if (UI::BeginCombo("Select GPS Replay", CurrentMapRecords::GPS::ghosts[CurrentMapRecords::GPS::selectedGhostIndex].name)) {
    //         for (uint i = 0; i < CurrentMapRecords::GPS::ghosts.Length; i++) {
    //             bool isSelected = (CurrentMapRecords::GPS::selectedGhostIndex == int(i));
    //             if (UI::Selectable(CurrentMapRecords::GPS::ghosts[i].name, isSelected)) {
    //                 CurrentMapRecords::GPS::selectedGhostIndex = i;
    //             }
    //             if (isSelected) {
    //                 UI::SetItemDefaultFocus();
    //             }
    //         }
    //         UI::EndCombo();
    //     }
    // }
    // if (!CurrentMapRecords::GPS::gpsReplayCanBeLoaded) {
    //     _UI::DisabledButton(Icons::UserPlus + " Load GPS Replay");
    // } else {
    //     if (UI::Button(Icons::UserPlus + " Load GPS Replay")) {
    //         CurrentMapRecords::GPS::LoadReplay();
    //     }
    // }
#if DEPENDENCY_CHAMPIONMEDALS
    UI::Separator();

    UI::Text("Champion Medal Information");

    UI::Text("Current Champion Medal Time: " + FromMsToFormat(CurrentMapRecords::ChampMedal::currentMapChampionMedal));

    if (!CurrentMapRecords::ChampMedal::championMedalExists) {
        _UI::DisabledButton(Icons::UserPlus + " Load Nearest Champion Medal Time");
    } else {
        if (UI::Button(Icons::UserPlus + " Load Nearest Champion Medal Time")) {
            CurrentMapRecords::ChampMedal::AddChampionMedal();
        }
    }

    if (CurrentMapRecords::ChampMedal::ReqForCurrentMapFinished) {
        if (CurrentMapRecords::ChampMedal::championMedalHasExactMatch) {
            UI::Text("Exact match found for the champion medal!");
            UI::Text("Time difference: " + tostring(CurrentMapRecords::ChampMedal::timeDifference) + " ms");
        } else {
            UI::Text("There is no exact match for the champion medal. Using the closest ghost that still beats the champion medal time.");
            UI::Text("Time difference: " + tostring(CurrentMapRecords::ChampMedal::timeDifference) + " ms");
        }
    } else {
        UI::Text("The current state of the champion medal record is unknown. Please load a champion medal record to check if there is an exact match.");
    }
#endif
}

string FromMsToFormat(uint ms) {
    uint minutes = ms / 60000;
    uint seconds = (ms % 60000) / 1000;
    uint milliseconds = ms % 1000;
    return pad(minutes, 2) + ":" + pad(seconds, 2) + "." + pad(milliseconds, 3);
}

string pad(uint value, uint length) {
    string result = "" + value;
    while (result.Length < length) {
        result = "0" + result;
    }
    return result;
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