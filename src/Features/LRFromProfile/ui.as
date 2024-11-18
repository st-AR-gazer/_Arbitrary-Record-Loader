namespace Features {
namespace LRFromProfile {
    string selectedJsonFile;
    array<string> jsonFiles = OtherManager::GetAvailableJsonFiles();
    int selectedIndex = 0;
    string downloadedContent;
    array<Json::Value> mapList;

    string newJsonName;

    int otherOffset = 0;

    void RenderTab_OtherSpecificUIDs() {

        UI::Separator();

        string downloadPath;
        UI::InputText("Download URL", downloadPath);
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
}
}