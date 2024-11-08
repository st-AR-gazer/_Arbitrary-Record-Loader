namespace Features {
namespace LRBasedOnCurrentMap {
    CurrentMapRecords::Medals::ChampionMedal champMedal;
    CurrentMapRecords::Medals::WarriorMedal warriorMedal;
    CurrentMapRecords::Medals::SBVilleMedal sbVilleMedal;

    void RT_LRBasedOnCurrentMap() {

        UI::Separator();

        UI::Text("\\$0cf" + "Load PB Ghost");

        UI::Text("\\$0cf" + "Autosaves");
        if (UI::Button(Icons::UserPlus + " Load PB Ghost")) {
            CurrentMapRecords::PB::PBManager::LoadPB();
        }

        if (UI::Button(Icons::UserTimes + " Unload PB Ghost")) {
            CurrentMapRecords::PB::PBManager::UnloadAllPBs();
        }

#if DEPENDENCY_ARCHIVIST
        UI::Separator();
        
        UI::Text("\\$0cf" + "Archivist");

        // Re-index PB Ghosts Button
        if (UI::Button(Icons::Refresh + " Re-index PB Ghosts")) {
            CurrentMapRecords::PB::IndexAndSaveToFile();
        }

        if (UI::Button(Icons::UserPlus + " Load Complete PB Ghost")) {
            // CurrentMapRecords::PB::LoadCompletePB();
        }

        if (UI::Button(Icons::UserPlus + " Load Segmented PB Ghost")) {
            CurrentMapRecords::PB::PBManager::LoadSegmentedPB();
        }

        if (UI::Button(Icons::UserPlus + " Load Partial PB Ghost")) {
            CurrentMapRecords::PB::PBManager::LoadPartialPB();
        }

#else
        _UI::SimpleTooltip(Icons::UserPlus + " Archivist is required for this feature.");
        _UI::DisabledButton(Icons::Refresh + " Re-index PB Ghosts");
        _UI::DisabledButton(Icons::UserPlus + " Load Complete PB Ghost");
        _UI::DisabledButton(Icons::UserPlus + " Load Segmented PB Ghost");
        _UI::DisabledButton(Icons::UserPlus + " Load Partial PB Ghost");
#endif

        UI::Separator();

        UI::Text("\\$0ff" + "WARNING\\$g " + "This uses the old 'Extract Validation Replay' method. Since ghosts were removed from map \nfiles, this will not be possible for maps older than October 1st 2022");

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
        if (CurrentMapRecords::ValidationReplay::ValidationReplayExists()) {
            if (UI::Button(Icons::UserTimes + " Validation replay time")) {
                CurrentMapRecords::ValidationReplay::GetValidationReplayTime();
            }
        }


        UI::Separator();


        UI::Text("\\$0ff" + "WARNING\\$g " + "This uses the old 'Extract Validation Replay' method. Since ghosts were removed from map \nfiles, this will not be possible for maps older than October 1st 2022");


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
        if (CurrentMapRecords::ValidationReplay::ValidationReplayExists()) {
            if (UI::Button(Icons::UserTimes + " Validation replay time")) {
                CurrentMapRecords::ValidationReplay::GetValidationReplayTime();
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

        UI::Text("\\$e79Champion Medal Information");

        UI::Text("Current Champion Medal Time: " + FromMsToFormat(champMedal.currentMapMedalTime));

        if (!champMedal.medalExists) {
            _UI::DisabledButton(Icons::UserPlus + " Load Nearest Champion Medal Time");
        } else {
            if (UI::Button(Icons::UserPlus + " Load Nearest Champion Medal Time")) {
                champMedal.AddMedal();
            }
        }

        if (champMedal.reqForCurrentMapFinished) {
            if (champMedal.medalHasExactMatch) {
                UI::Text("Exact match found for the champion medal!");
                UI::Text("Time difference: " + tostring(champMedal.timeDifference) + " ms");
            } else {
                UI::Text("There is no exact match for the champion medal. Using the closest ghost that still beats the champion medal time.");
                UI::Text("Time difference: " + tostring(champMedal.timeDifference) + " ms");
            }
        } else {
            UI::Text("The current state of the champion medal record is unknown. Please load a champion medal record to check if there is an exact match.");
        }
#endif
#if DEPENDENCY_WARRIORMEDALS
        UI::Separator();

        UI::Text("\\$0cfWarrior Medal Information");

        UI::Text("Current Warrior Medal Time: " + FromMsToFormat(warriorMedal.currentMapMedalTime));

        if (!warriorMedal.medalExists) {
            _UI::DisabledButton(Icons::UserPlus + " Load Nearest Warrior Medal Time");
        } else {
            if (UI::Button(Icons::UserPlus + " Load Nearest Warrior Medal Time")) {
                warriorMedal.AddMedal();
            }
        }

        if (warriorMedal.reqForCurrentMapFinished) {
            if (warriorMedal.medalHasExactMatch) {
                UI::Text("Exact match found for the warrior medal!");
                UI::Text("Time difference: " + tostring(warriorMedal.timeDifference) + " ms");
            } else {
                UI::Text("There is no exact match for the warrior medal. Using the closest ghost that still beats the warrior medal time.");
                UI::Text("Time difference: " + tostring(warriorMedal.timeDifference) + " ms");
            }
        } else {
            UI::Text("The current state of the warrior medal record is unknown. Please load a warrior medal record to check if there is an exact match.");
        }
#endif
#if DEPENDENCY_SBVILLECAMPAIGNCHALLENGES
        UI::Separator();

        UI::Text("\\$f90SB Ville Medal Information");

        UI::Text("Current SB Ville Medal Time: " + FromMsToFormat(sbVilleMedal.currentMapMedalTime));

        if (!sbVilleMedal.medalExists) {
            _UI::DisabledButton(Icons::UserPlus + " Load Nearest SB Ville Medal Time");
        } else {
            if (UI::Button(Icons::UserPlus + " Load Nearest SB Ville Medal Time")) {
                sbVilleMedal.AddMedal();
            }
        }

        if (sbVilleMedal.reqForCurrentMapFinished) {
            if (sbVilleMedal.medalHasExactMatch) {
                UI::Text("Exact match found for the SB Ville medal!");
                UI::Text("Time difference: " + tostring(sbVilleMedal.timeDifference) + " ms");
            } else {
                UI::Text("There is no exact match for the SB Ville medal. Using the closest ghost that still beats the SB Ville medal time.");
                UI::Text("Time difference: " + tostring(sbVilleMedal.timeDifference) + " ms");
            }
        } else {
            UI::Text("The current state of the SB Ville medal record is unknown. Please load a SB Ville medal record to check if there is an exact match.");
        }
#endif
    }
}
}