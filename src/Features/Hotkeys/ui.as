// src/Features/Hotkeys/ui.as

namespace Features {
namespace Hotkeys {
    void RT_Hotkeys() {
        UI::Text("Hotkey Configuration");
        UI::Separator();

        UI::Text("Existing Hotkeys:");
        array<string> keys = hotkeyMappings.GetKeys();
        if (keys.Length > 0) {
            for (uint i = 0; i < keys.Length; i++) {
                array<Hotkey@>@ hotkeysList = cast<array<Hotkey@>@>(hotkeyMappings[keys[i]]);
                for (uint j = 0; j < hotkeysList.Length; j++) {
                    Hotkey@ hotkey = hotkeysList[j];
                    string currentKeys = hotkey.get_description();

                    UI::Text(hotkey.action + ": ");
                    UI::SameLine();
                    if (UI::Button(currentKeys + "##edit" + keys[i] + "-" + j)) {
                        actionToEdit = keys[i];
                        editKeyCombination = hotkey.keyCombination;
                        showEditHotkeyUI = true;
                    }
                    UI::SameLine();
                    if (UI::Button("Remove##remove" + keys[i] + "-" + j)) {
                        RemoveHotkey(keys[i], j);
                    }
                }
            }
        } else {
            UI::TextDisabled("No hotkeys configured yet.");
        }

        UI::Dummy(vec2(0, 10));

        UI::Separator();
        UI::Dummy(vec2(0, 10));

        if (UI::Button(showAddHotkeyUI ? "Cancel Adding New Hotkey" : "Add New Hotkey")) {
            showAddHotkeyUI = !showAddHotkeyUI;
            showEditHotkeyUI = false;
            selectedAction = "";
            newKeyCombination.RemoveRange(0, newKeyCombination.Length);
            loadXPosition = 1;
        }

        if (showAddHotkeyUI) {
            UI::Dummy(vec2(0, 10));
            UI::Text("New Hotkey Configuration:");
            UI::Separator();

            UI::Text("Action:");
            if (UI::BeginCombo("##SelectAction", selectedAction.Length == 0 ? "Select Action" : selectedAction)) {
                for (uint i = 0; i < availableActions.Length; i++) {
                    if (UI::Selectable(availableActions[i], availableActions[i] == selectedAction)) {
                        selectedAction = availableActions[i];
                    }
                }
                UI::EndCombo();
            }

            if (selectedAction == "Load X time") {
                UI::Dummy(vec2(0, 10));
                UI::Text("Specify Position:");
                loadXPosition = Math::Clamp(UI::InputInt("Position (1 for top)", loadXPosition), 1, 1000);
            }

            UI::Dummy(vec2(0, 10));

            UI::Text("Key Combination:");
            if (UI::Button("Add Key")) {
                newKeyCombination.InsertLast("Select Key");
            }

            for (uint i = 0; i < newKeyCombination.Length; i++) {
                if (UI::BeginCombo("##Key" + (i + 1), newKeyCombination[i])) {
                    array<string> allKeys = GenerateKeyList();
                    for (uint k = 0; k < allKeys.Length; k++) {
                        if (UI::Selectable(allKeys[k], allKeys[k] == newKeyCombination[i])) {
                            newKeyCombination[i] = allKeys[k];
                        }
                    }
                    UI::EndCombo();
                }
                if (newKeyCombination[i] != "Select Key") {
                    UI::SameLine();
                    if (UI::Button("Remove##new" + i)) {
                        newKeyCombination.RemoveAt(i);
                        i--;
                    }
                }
            }

            UI::Dummy(vec2(0, 10));

            if (UI::Button("Add Hotkey") && selectedAction.Length > 0 && newKeyCombination.Length > 0) {
                int extraValue = (selectedAction == "Load X time") ? loadXPosition : -1;
                RegisterHotkey(newKeyCombination, selectedAction, extraValue);
                showAddHotkeyUI = false;
            }
        }

        if (showEditHotkeyUI) {
            UI::Dummy(vec2(0, 10));
            UI::Text("Edit Hotkey Configuration:");
            UI::Separator();

            UI::Text("Action: " + actionToEdit);

            UI::Dummy(vec2(0, 10));

            UI::Text("Key Combination:");
            if (UI::Button("Add Key")) {
                editKeyCombination.InsertLast("Select Key");
            }

            for (uint i = 0; i < editKeyCombination.Length; i++) {
                if (UI::BeginCombo("##EditKey" + (i + 1), editKeyCombination[i])) {
                    array<string> allKeys = GenerateKeyList();
                    for (uint k = 0; k < allKeys.Length; k++) {
                        if (UI::Selectable(allKeys[k], allKeys[k] == editKeyCombination[i])) {
                            editKeyCombination[i] = allKeys[k];
                        }
                    }
                    UI::EndCombo();
                }
                if (editKeyCombination[i] != "Select Key") {
                    UI::SameLine();
                    if (UI::Button("Remove##edit" + i)) {
                        editKeyCombination.RemoveAt(i);
                        i--;
                    }
                }
            }

            UI::Dummy(vec2(0, 10));

            if (UI::Button("Update Hotkey") && editKeyCombination.Length > 0) {
                int extraValue = (actionToEdit == "Load X time") ? loadXPosition : -1;
                UpdateHotkey(actionToEdit, 0 /*Update the first one*/, editKeyCombination, extraValue);
                showEditHotkeyUI = false;
            }
        }
    }
}
}