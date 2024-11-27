// src/Features/CurrentRecordsInfo/ui.as

namespace Features {
namespace CRInfo {

    MwId selectedRecordID;
    bool isDropdownOpen = false;

    void RT_CRInfo() {
        auto dfm = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        auto ghosts = dfm.Ghosts;

        UI::Separator();

        UI::Text("Information about all the currently loaded records");

        UI::Separator();

        if (UI::Button("Remove All Records")) {
            log("Remove All Records button clicked", LogLevel::Info, 14, "RT_CRInfo");
            RecordManager::RemoveAllRecords();
        }

        string selectedGhostName = selectedRecordID.Value != MwId().Value 
                                ? RecordManager::get_RecordNameFromId(selectedRecordID) 
                                : "Select a ghost instance";

        if (UI::BeginCombo("Select a ghost instance", selectedGhostName)) {
            if (!isDropdownOpen) {
                isDropdownOpen = true;
            }

            for (uint i = 0; i < ghosts.Length; i++) {
                auto ghost = ghosts[i];
                bool isSelected = (selectedRecordID.Value == ghost.Id.Value);
                if (ghost.Nickname.Length != 0) {
                    if (UI::Selectable(ghost.Nickname, isSelected)) {
                        selectedRecordID = ghost.Id;
                    }
                } else {
                    if (UI::Selectable("##", isSelected)) {
                        selectedRecordID = ghost.Id;
                    }
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
            string ghostInfo = RecordManager::get_GhostInfo(selectedRecordID);
            UI::Text("Selected Record Info:");
            UI::Text(ghostInfo);
        }

        if (UI::Button(Icons::UserTimes + " Remove Specific Record")) {
            log("Remove Specific Record button clicked", LogLevel::Info, 56, "RT_CRInfo");
            RecordManager::RemoveInstanceRecord(selectedRecordID);
            selectedRecordID = MwId();
        }

        if (UI::Button(Icons::Kenney::Save + " Save Ghost/Replay")) {
            log("Save Ghost button clicked", LogLevel::Info, 63, "RT_CRInfo");
            RecordManager::Save::SaveRecord();
        }
        
        if (Features::LRBasedOnCurrentMap::ValidationReplay::ValidationReplayExists()) {
            if (UI::Button(Icons::Kenney::Save + " Save validation replay")) {
                RecordManager::Save::SaveRecordByPath(Features::LRBasedOnCurrentMap::ValidationReplay::GetValidationReplayFilePathForCurrentMap());
            }
        } else {
            _UI::DisabledButton(Icons::Kenney::Save + " Save validation replay");
        }
    }

}
}