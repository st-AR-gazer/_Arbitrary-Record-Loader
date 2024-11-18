// src/Features/CurrentRecordsInfo/ui.as

namespace Features {
namespace CRInfo {

    MwId selectedRecordID;
    bool isDropdownOpen = false;

    void RT_CRInfo() {

        UI::Separator();

        if (UI::Button("Remove All Records")) {
            log("Remove All Records button clicked", LogLevel::Info, 129, "RenderTab_CurrentLoadedRecords");
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
            string ghostInfo = RecordManager::GhostTracker::GetTrackedGhostInfo(selectedRecordID);
            UI::Text("Selected Record Info:");
            UI::Text(ghostInfo);
        }

        if (UI::Button(Icons::UserTimes + " Remove Specific Record")) {
            log("Remove Specific Record button clicked", LogLevel::Info, 171, "RenderTab_CurrentLoadedRecords");
            RecordManager::RemoveInstanceRecord(selectedRecordID);
            RecordManager::GhostTracker::RefreshTrackedGhosts();
            selectedRecordID = MwId();
        }

        if (UI::Button(Icons::Kenney::Save + " Save Ghost/Replay")) {
            log("Save Ghost button clicked", LogLevel::Info, 178, "RenderTab_CurrentLoadedRecords");
            RecordManager::Save::SaveRecord();
        }
        
        if (CurrentMapRecords::ValidationReplay::ValidationReplayExists()) {
            if (UI::Button(Icons::Kenney::Save + " Save validation replay")) {
                RecordManager::Save::SaveRecordByPath(CurrentMapRecords::ValidationReplay::GetValidationReplayFilePathForCurrentMap());
            }
        } else {
            _UI::DisabledButton(Icons::Kenney::Save + " Save validation replay");
        }
    }

}
}