// src/Features/LoadRecordFromProfile/ui.as

namespace Features {
namespace LRFromProfile {
    string selectedJsonFile;
    array<string> jsonFiles = GetAvailableJsonFiles();
    int selectedIndex = 0;
    string downloadedContent;
    array<Json::Value> mapList;

    string newJsonName;

    int otherOffset = 0;

    void RT_LRFromProfile() {

        UI::Separator();

        string downloadPath;
        UI::InputText("Download URL", downloadPath);
        UI::SameLine();
        if (UI::Button("Create New Download Profile")) {
            isCreatingProfile = true;
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
            jsonFiles = GetAvailableJsonFiles();
        }

        otherOffset = UI::InputInt("Offset", otherOffset);

        UI::Separator();
        if (UI::BeginCombo("Select JSON File", selectedJsonFile)) {
            for (uint i = 0; i < jsonFiles.Length; i++) {
                bool isSelected = (selectedIndex == int(i));
                if (UI::Selectable(jsonFiles[i], isSelected)) {
                    selectedIndex = i;
                    selectedJsonFile = jsonFiles[i];
                    downloadedContent = LoadJsonContent(selectedJsonFile);
                    mapList = GetMapListFromJson(downloadedContent);
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
                        loadRecord.LoadRecordFromMapUid(map["mapUid"], tostring(otherOffset), "OtherMaps");
                    }
                    UI::Separator();
                }
            }
        }

        if (IsDownloading) {
            UI::OpenPopup("Downloading");
        }

        if (UI::BeginPopupModal("Downloading", IsDownloading, UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize)) {
            UI::Text("Downloading, please wait...");
            UI::EndPopup();
        }

        if (isCreatingProfile) {
            UI::OpenPopup("Create New Download Profile");
        }

        if (UI::BeginPopupModal("Create New Download Profile", isCreatingProfile, UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize)) {
            newJsonName = UI::InputText("JSON Name", newJsonName);

            for (uint i = 0; i < NewProfileMaps.Length; i++) {
                NewProfileMaps[i].mapName = UI::InputText("Map Name##" + i, NewProfileMaps[i].mapName);
                UI::SameLine();
                NewProfileMaps[i].mapUid = UI::InputText("Map UID##" + i, NewProfileMaps[i].mapUid);
                UI::SameLine();
                if (UI::Button("Remove##" + i)) {
                    NewProfileMaps.RemoveAt(i);
                    i--;
                }
                UI::Separator();
            }

            if (UI::Button("Add Map")) {
                NewProfileMaps.InsertLast(MapEntry());
            }
            UI::SameLine();
            if (UI::Button("Save Profile")) {
                SaveNewProfile(newJsonName);
                isCreatingProfile = false;
                UI::CloseCurrentPopup();
            }
            UI::SameLine();
            if (UI::Button("Cancel")) {
                isCreatingProfile = false;
                UI::CloseCurrentPopup();
            }

            UI::EndPopup();
        }
    }
}
}