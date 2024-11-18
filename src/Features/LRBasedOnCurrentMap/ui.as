namespace Features {
namespace LRBasedOnCurrentMap {

    void RT_LRBasedOnCurrentMap() {
        RTPart_PB();
        UI::Separator();
        RTPart_ValidationReplay();
        UI::Separator();
        RTPart_GPS();
        UI::Separator();
        RTPart_Medals();
    }


    ////////////////////////// PB //////////////////////////


    void RTPart_PB() {
//        UI::Text("\\$0cf" + "Load PB Ghost");
//
//        UI::Text("\\$0cf" + "Autosaves");
//        if (UI::Button(Icons::UserPlus + " Load PB Ghost")) {
//            PB::PBManager::LoadPB();
//        }
//
//        if (UI::Button(Icons::UserTimes + " Unload PB Ghost")) {
//            PB::PBManager::UnloadAllPBs();
//        }
//
//#if DEPENDENCY_ARCHIVIST
//        UI::Separator();
//        
//        UI::Text("\\$0cf" + "Archivist");
//
//        if (UI::Button(Icons::Refresh + " Re-index PB Ghosts")) {
//            PB::IndexAndSaveToFile();
//        }
//
//        if (UI::Button(Icons::UserPlus + " Load Complete PB Ghost")) {
//            // PB::LoadCompletePB();
//        }
//
//        if (UI::Button(Icons::UserPlus + " Load Segmented PB Ghost")) {
//            PB::PBManager::LoadSegmentedPB();
//        }
//
//        if (UI::Button(Icons::UserPlus + " Load Partial PB Ghost")) {
//            PB::PBManager::LoadPartialPB();
//        }
//#else
//        _UI::SimpleTooltip(Icons::UserPlus + " Archivist is required for this feature.");
//        _UI::DisabledButton(Icons::Refresh + " Re-index PB Ghosts");
//        _UI::DisabledButton(Icons::UserPlus + " Load Complete PB Ghost");
//        _UI::DisabledButton(Icons::UserPlus + " Load Segmented PB Ghost");
//        _UI::DisabledButton(Icons::UserPlus + " Load Partial PB Ghost");
//#endif
//
//        UI::Separator();
//
//        UI::Text("\\$0ff" + "WARNING\\$g " + "This uses the old 'Extract Validation Replay' method. Since ghosts were removed from map \nfiles, this will not be possible for maps older than October 1st 2022");
//
//        if (!ValidationReplay::ValidationReplayExists()) {
//            UI::Text("\\$f00" + "WARNING" + "\\$g " + "No validation replay found for current map.");
//        } else {
//            UI::Text("\\$0f0" + "Validation Replay found for current map.");
//        }
//        if (!ValidationReplay::ValidationReplayExists()) {
//            _UI::DisabledButton(Icons::UserPlus + " Add validation replay to current run");
//        } else {
//            if (UI::Button(Icons::UserPlus + " Add validation replay to current run")) {
//                ValidationReplay::AddValidationReplay();
//            }
//        }
//        if (ValidationReplay::ValidationReplayExists()) {
//            if (UI::Button(Icons::UserTimes + " Validation replay time")) {
//                ValidationReplay::GetValidationReplayTime();
//            }
//        }
    }


    ////////////////////////// Validation Replay //////////////////////////


    void RTPart_ValidationReplay() {
        UI::Text("\\$0ff" + "WARNING\\$g " + "This uses the old 'Extract Validation Replay' method. Since ghosts were removed from map \nfiles, this will not be possible for maps older than October 1st 2022");

        if (!ValidationReplay::ValidationReplayExists()) {
            UI::Text("\\$f00" + "WARNING" + "\\$g " + "No validation replay found for current map.");
        } else {
            UI::Text("\\$0f0" + "Validation Replay found for current map.");
        }
        if (!ValidationReplay::ValidationReplayExists()) {
            _UI::DisabledButton(Icons::UserPlus + " Add validation replay to current run");
        } else {
            if (UI::Button(Icons::UserPlus + " Add validation replay to current run")) {
                ValidationReplay::AddValidationReplay();
            }
        }
        if (ValidationReplay::ValidationReplayExists()) {
            if (UI::Button(Icons::UserTimes + " Validation replay time")) {
                ValidationReplay::GetValidationReplayTime();
            }
        }
    }


    ////////////////////////// GPS //////////////////////////


    void RTPart_GPS() {
        // GPS extraction/loading is something I've canned for now, due to lack of knowledge on my part...

        // UI::Separator();
        // if (!GPS::gpsReplayCanBeLoaded) {
        //     UI::Text("No GPS replays available for the current map.");
        // }

        // UI::Text("GPS Replays:");

        // if (GPS::ghosts.Length == 1) {
        //     UI::Text(GPS::ghosts[0].name);
        //     UI::Text("Only one GPS replay found.");
        //     GPS::selectedGhostIndex = 0;
        // }
        // if (GPS::selectedGhostIndex > 0) {
        //     if (UI::BeginCombo("Select GPS Replay", GPS::ghosts[GPS::selectedGhostIndex].name)) {
        //         for (uint i = 0; i < GPS::ghosts.Length; i++) {
        //             bool isSelected = (GPS::selectedGhostIndex == int(i));
        //             if (UI::Selectable(GPS::ghosts[i].name, isSelected)) {
        //                 GPS::selectedGhostIndex = i;
        //             }
        //             if (isSelected) {
        //                 UI::SetItemDefaultFocus();
        //             }
        //         }
        //         UI::EndCombo();
        //     }
        // }
        // if (!GPS::gpsReplayCanBeLoaded) {
        //     _UI::DisabledButton(Icons::UserPlus + " Load GPS Replay");
        // } else {
        //     if (UI::Button(Icons::UserPlus + " Load GPS Replay")) {
        //         GPS::LoadReplay();
        //     }
        // }
    }


    ////////////////////////// MEDALS //////////////////////////


    Medals::ChampionMedal champMedal;
    Medals::WarriorMedal warriorMedal;
    Medals::SBVilleMedal sbVilleMedal;

    void RTPart_Medals() {
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