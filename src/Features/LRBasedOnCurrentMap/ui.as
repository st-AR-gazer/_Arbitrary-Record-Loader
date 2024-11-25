// src/Features/LoadRecordBasedOnCurrentMap/ui.as

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
        UI::Text("\\$0cf" + "Load PB Ghost");


        #if DEPENDENCY_ARCHIVIST
        if (UI::GetWindowSize().x > 250 && UI::GetWindowSize().y > 155) {
            UI::BeginTable("FileExplorerTable", 3, UI::TableFlags::Resizable | UI::TableFlags::Borders);
            
            UI::TableNextColumn();
                UI::BeginChild("LeftStandardSidebar", vec2(0, 0), true);

                // 
                
                UI::Text("\\$0cf" + "Standard PB Loading");
                    
                if (UI::Button(Icons::FolderOpen + Icons::Refresh + " Index 'Autosave(s)' folder")) {  }

                _UI::SimpleTooltip("Loads the PB ghost from the leaderboard if no PB exists in the 'Autosaves' folder.");
                if (UI::Selectable("Use the 'Leaderboard' to load PBs")) { auto xx = true; }

                
                if (UI::Button(Icons::UserPlus + " Load PB Ghost")) {  }

                _UI::SimpleTooltip("This can also be preformed by clicking the 'load pb ghost' button in the records widget.");
                if (UI::Button(Icons::UserTimes + " Unload PB Ghost")) {  }
                
                
                // 

                UI::EndChild();
            UI::TableNextColumn();
                UI::BeginChild("RightArchevistSidebar", vec2(0, 0), true);

                // 

                UI::Text("\\$0cf" + "Archevist PB Loading");

                if (UI::Button(Icons::FolderOpen + Icons::Refresh + " Index archevist folder")) {  }
                if (UI::Button(Icons::FolderOpen + Icons::Refresh + " Index archevist folder (with validations)")) {  }

                if (UI::Selectable("Allow 'validation' PBs on real maps")) { auto xx = true; }


                if (completePBExists) { if (UI::Button(Icons::UserPlus + " Load Complete PB Ghost")) { PB::PBManager::LoadArchevistPB("Complete"); };
                } else { _UI::DisabledButton(Icons::UserPlus + " Load Complete PB Ghost"); }

                if (segmentedPBExists) { if (UI::Button(Icons::UserPlus + " Load Segmented PB Ghost")) { PB::PBManager::LoadArchevistPB("Segmented"); };
                } else { _UI::DisabledButton(Icons::UserPlus + " Load Segmented PB Ghost"); }

                if (partialPBExists) { if (UI::Button(Icons::UserPlus + " Load Partial PB Ghost")) { PB::PBManager::LoadArchevistPB("Partial"); };
                } else { _UI::DisabledButton(Icons::UserPlus + " Load Partial PB Ghost"); }


                _UI::SimpleTooltip("This can also be preformed by clicking the 'hide pb ghost' button in the records widget.");
                if (UI::Button(Icons::UserTimes + " Unload PB Ghost")) {  }
                
                // 

                UI::EndChild();

            UI::EndTable();
        } else {
            UI::Text("Window too small to \nrender columns (it \nwill crash your game \nif it is rendered any \nsmaller).");
        }
        #else

        UI::Text("\\$0cf" + "Load PB Ghost");
                    
        if (UI::Button(Icons::FolderOpen + Icons::Refresh + " Index 'Autosave(s)' folder")) {  }

        _UI::SimpleTooltip("Loads the PB ghost from the leaderboard if no PB exists in the 'Autosaves' folder.");
        if (UI::Selectable("Use the 'Leaderboard' to load PBs")) { auto xx = true; }
        
        if (UI::Button(Icons::UserPlus + " Load PB Ghost")) {  }

        _UI::SimpleTooltip("Archivist is required for this feature.");
        _UI::DisabledButton(Icons::UserPlus + " Load Ghost from 'Archivist'");

        _UI::SimpleTooltip("This can also be preformed by clicking the 'load pb ghost' button in the records widget.");
        if (UI::Button(Icons::UserTimes + " Unload PB Ghost")) {  }

        #endif
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
    Medals::WarriorMedal  warriorMedal;
    Medals::SBVilleMedal  sbVilleMedal;

    Medals::AuthorMedal authorMedal;
    Medals::GoldMedal   goldMedal;
    Medals::SilverMedal silverMedal;
    Medals::BronzeMedal bronzeMedal;

    void RTPart_Medals() {

///////////////////////// CHAMPION MEDALS //////////////////////////
#if DEPENDENCY_CHAMPIONMEDALS
        UI::Separator();

        UI::Text("\\$e79" + "Champion Medal Information");
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

///////////////////////// WARRIOR MEDALS //////////////////////////
#if DEPENDENCY_WARRIORMEDALS
        UI::Separator();

        UI::Text(WarriorMedals::GetColorStr() + /*"\\$0cf" + */"Warrior Medal Information");

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

///////////////////////// SB VILLE MEDALS //////////////////////////
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

///////////////////////// BUILT-IN MEDALS //////////////////////////

///////////////////////// AUTHOR MEDALS //////////////////////////
// #if DEPENDENCY_AUTHORMEDALS
        UI::Separator();

        UI::Text("\\$7e0" + "Author Medal Information");

        UI::Text("Current Author Medal Time: " + FromMsToFormat(authorMedal.currentMapMedalTime));

        if (!authorMedal.medalExists) {
            _UI::DisabledButton(Icons::UserPlus + " Load Nearest Author Medal Time");
        } else {
            if (UI::Button(Icons::UserPlus + " Load Nearest Author Medal Time")) {
                authorMedal.AddMedal();
            }
        }

        if (authorMedal.reqForCurrentMapFinished) {
            if (authorMedal.medalHasExactMatch) {
                UI::Text("Exact match found for the author medal!");
                UI::Text("Time difference: " + tostring(authorMedal.timeDifference) + " ms");
            } else {
                UI::Text("There is no exact match for the author medal. Using the closest ghost that still beats the author medal time.");
                UI::Text("Time difference: " + tostring(authorMedal.timeDifference) + " ms");
            }
        } else {
            UI::Text("The current state of the author medal record is unknown. Please load an author medal record to check if there is an exact match.");
        }
// #endif

///////////////////////// GOLD MEDALS //////////////////////////
// #if DEPENDENCY_GOLDMEDALS
        UI::Separator();

        UI::Text("\\$fd0" + "Gold Medal Information");

        UI::Text("Current Gold Medal Time: " + FromMsToFormat(goldMedal.currentMapMedalTime));

        if (!goldMedal.medalExists) {
            _UI::DisabledButton(Icons::UserPlus + " Load Nearest Gold Medal Time");
        } else {
            if (UI::Button(Icons::UserPlus + " Load Nearest Gold Medal Time")) {
                goldMedal.AddMedal();
            }
        }

        if (goldMedal.reqForCurrentMapFinished) {
            if (goldMedal.medalHasExactMatch) {
                UI::Text("Exact match found for the gold medal!");
                UI::Text("Time difference: " + tostring(goldMedal.timeDifference) + " ms");
            } else {
                UI::Text("There is no exact match for the gold medal. Using the closest ghost that still beats the gold medal time.");
                UI::Text("Time difference: " + tostring(goldMedal.timeDifference) + " ms");
            }
        } else {
            UI::Text("The current state of the gold medal record is unknown. Please load a gold medal record to check if there is an exact match.");
        }
// #endif

///////////////////////// SILVER MEDALS //////////////////////////
// #if DEPENDENCY_SILVERMEDALS
        UI::Separator();

        UI::Text("\\$ddd" + "Silver Medal Information");

        UI::Text("Current Silver Medal Time: " + FromMsToFormat(silverMedal.currentMapMedalTime));

        if (!silverMedal.medalExists) {
            _UI::DisabledButton(Icons::UserPlus + " Load Nearest Silver Medal Time");
        } else {
            if (UI::Button(Icons::UserPlus + " Load Nearest Silver Medal Time")) {
                silverMedal.AddMedal();
            }
        }

        if (silverMedal.reqForCurrentMapFinished) {
            if (silverMedal.medalHasExactMatch) {
                UI::Text("Exact match found for the silver medal!");
                UI::Text("Time difference: " + tostring(silverMedal.timeDifference) + " ms");
            } else {
                UI::Text("There is no exact match for the silver medal. Using the closest ghost that still beats the silver medal time.");
                UI::Text("Time difference: " + tostring(silverMedal.timeDifference) + " ms");
            }
        } else {
            UI::Text("The current state of the silver medal record is unknown. Please load a silver medal record to check if there is an exact match.");
        }
// #endif

///////////////////////// BRONZE MEDALS //////////////////////////
// #if DEPENDENCY_BRONZEMEDALS
        UI::Separator();

        UI::Text("\\$c73" + "Bronze Medal Information");

        UI::Text("Current Bronze Medal Time: " + FromMsToFormat(bronzeMedal.currentMapMedalTime));

        if (!bronzeMedal.medalExists) {
            _UI::DisabledButton(Icons::UserPlus + " Load Nearest Bronze Medal Time");
        } else {
            if (UI::Button(Icons::UserPlus + " Load Nearest Bronze Medal Time")) {
                bronzeMedal.AddMedal();
            }
        }

        if (bronzeMedal.reqForCurrentMapFinished) {
            if (bronzeMedal.medalHasExactMatch) {
                UI::Text("Exact match found for the bronze medal!");
                UI::Text("Time difference: " + tostring(bronzeMedal.timeDifference) + " ms");
            } else {
                UI::Text("There is no exact match for the bronze medal. Using the closest ghost that still beats the bronze medal time.");
                UI::Text("Time difference: " + tostring(bronzeMedal.timeDifference) + " ms");
            }
        } else {
            UI::Text("The current state of the bronze medal record is unknown. Please load a bronze medal record to check if there is an exact match.");
        }
// #endif
    }
}
}