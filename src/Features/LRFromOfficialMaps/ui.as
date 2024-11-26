// src/Features/LoadRecordFromOfficialMaps/ui.as

namespace Features {
namespace LRFromOfficialMaps {
    int selectedYear = -1;
    int selectedSeason = -1;
    int selectedMap = -1;
    int selectedOffset = 0;

    string Official_MapUID;

    array<int> years;
    array<string> seasons;
    array<string> maps;

    void RT_LRFromOfficialMaps() {

        UI::Separator();

        if (UI::Button("Reset Selections")) {
            Official::UpdateYears();
            Official::UpdateSeasons();
            Official::UpdateMaps();
        }
        UI::SameLine();
        if (UI::Button("Run check for New Campaigns again")) {
            Campaign::CheckForNewCampaign();
        }
        UI::SameLine();
        if (UI::Button("Set season year to current")) {
            Official::SetSeasonYearToCurrent();
        }
        UI::SameLine();
        if (UI::Button("Try to set current map based on name")) {
            Official::SetCurrentMapBasedOnName();
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

        selectedOffset = UI::InputInt("Offset", selectedOffset);

        UI::Separator();

        Official_MapUID = Official::FetchOfficialMapUID();

        UI::Text(Official_MapUID);

        if (UI::Button("Load Record")) {
            loadRecord.LoadRecordFromMapUid(Official_MapUID, tostring(selectedOffset), "Official");
        }
    }
}
}