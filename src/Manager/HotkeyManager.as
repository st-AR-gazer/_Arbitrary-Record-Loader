class Hotkey {
    string[] keyCombination;
    string action;
    int extraValue = -1;
    int keyAmount = 1;

    string get_description() const {
        string keys = "";
        for (uint i = 0; i < keyCombination.Length; i++) {
            if (i > 0) keys += " + ";
            keys += keyCombination[i];
        }
        return keys + " : " + action;
    }

    Hotkey(string[] keyCombination, string action, int extraValue) {
        this.keyCombination = keyCombination;
        this.action = action;
        this.extraValue = extraValue;
    }
}

array<Hotkey@> hotkeys;
bool isCreatingNewHotkey = false;
string selectedAction = "";
int selectedActionIndex = -1;
string[] selectedKeys;
int keyAmount = 1;
string[] availableActions = {
    "Load top 1 time",
    "Load top 2 time",
    "Load top 3 time",
    "Load top 4 time",
    "Load top 5 time",
    "Load X time",
    "Remove all ghosts from current map",
    "Remove ghost with specific MwId",
    "Remove PB Ghost",
    "Open/Close Interface",
    "Open Interface",
    "Close Interface"
};

void RenderTab_Hotkeys() {
    UI::Text("Hotkeys");
    UI::Separator();

    if (UI::Button("Create New Hotkey")) {
        isCreatingNewHotkey = true;
        selectedKeys = {};
        selectedAction = "";
        selectedActionIndex = -1;
        keyAmount = 1;
    }

    if (isCreatingNewHotkey) {
        UI::Text("Define Hotkey:");
        UI::Separator();

        UI::Text("Number of keys: " + tostring(keyAmount));
        if (UI::Button("Add another key")) {
            keyAmount++;
        }
        UI::SameLine();
        if (UI::Button("Remove last key")) {
            if (keyAmount > 1) keyAmount--;
        }

        for (int i = 0; i < keyAmount; i++) {
            string keyName = i < int(selectedKeys.Length) ? selectedKeys[i] : "Select Key";
            UI::Text("Key " + tostring(i + 1) + ": ");
            UI::SameLine();
            if (UI::BeginCombo("##KeyCombo" + tostring(i), keyName)) {
                for (uint j = 0; j < allPossibleKeys.Length; j++) {
                    if (UI::Selectable(allPossibleKeys[j], selectedKeys.Find(allPossibleKeys[j]) != -1)) {
                        if (i < int(selectedKeys.Length)) {
                            selectedKeys[i] = allPossibleKeys[j];
                        } else {
                            selectedKeys.InsertLast(allPossibleKeys[j]);
                        }
                    }
                }
                UI::EndCombo();
            }
        }

        // Select an action
        UI::Text("Perform Action: ");
        UI::SameLine();
        if (UI::BeginCombo("##ActionCombo", selectedActionIndex == -1 ? "Select Action" : availableActions[selectedActionIndex])) {
            for (uint i = 0; i < availableActions.Length; i++) {
                bool isSelected = selectedActionIndex == int(i);
                if (UI::Selectable(availableActions[i], isSelected)) {
                    selectedActionIndex = int(i);
                    selectedAction = availableActions[i];
                }
            }
            UI::EndCombo();
        }

        int userDefinedTime = -1;
        if (selectedAction == "Load X time") {
            userDefinedTime = UI::InputInt("Specify X Time", 1);
        }

        UI::Separator();

        if (UI::Button("Finish Creating Hotkey")) {
            hotkeys.InsertLast(Hotkey(selectedKeys, selectedAction, userDefinedTime));
            isCreatingNewHotkey = false;
        }

        UI::SameLine();
        if (UI::Button("Cancel")) {
            isCreatingNewHotkey = false;
        }
    }

    UI::Separator();

    UI::Text("All Current Hotkeys:");
    for (uint i = 0; i < hotkeys.Length; i++) {
        UI::Text(hotkeys[i].description);
        UI::SameLine();
        if (UI::Button("Edit##" + i)) {
            StartEditingHotkey(i);
        }
        UI::SameLine();
        if (UI::Button("Delete##" + i)) {
            hotkeys.RemoveAt(i);
        }
    }
}

void StartEditingHotkey(int index) {
    isCreatingNewHotkey = true;
    selectedKeys = hotkeys[index].keyCombination;
    selectedAction = hotkeys[index].action;
    selectedActionIndex = availableActions.Find(selectedAction);
    keyAmount = hotkeys[index].keyCombination.Length;
    hotkeys.RemoveAt(index);
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (down) {
        string keyName = tostring(key);
        for (uint i = 0; i < hotkeys.Length; i++) {
            if (CheckKeyCombination(hotkeys[i], keyName)) {
                ExecuteHotkeyAction(hotkeys[i]);
            }
        }
    }
    return UI::InputBlocking::DoNothing;
}

bool CheckKeyCombination(Hotkey@ hotkey, const string &in keyName) {
    for (uint i = 0; i < hotkey.keyCombination.Length; i++) {
        if (hotkey.keyCombination[i] == keyName) {
            return true;
        }
    }
    return false;
}

void ExecuteHotkeyAction(Hotkey@ hotkey) {
    if (hotkey.action == "Load top 1 time") {
        // Logic to load the top 1 time
    } else if (hotkey.action == "Load top 2 time") {
        // Logic to load the top 2 time
    } else if (hotkey.action == "Load top 3 time") {
        // Logic to load the top 3 time
    } else if (hotkey.action == "Load top 4 time") {
        // Logic to load the top 4 time
    } else if (hotkey.action == "Load top 5 time") {
        // Logic to load the top 5 time
    } else if (hotkey.action == "Load X time" && hotkey.extraValue > 0) {
        // Logic to load the specific time
    } else if (hotkey.action == "Open/Close Interface") {
        // Logic to open or close the interface
    } else if (hotkey.action == "Open Interface") {
        // Logic to open the interface
    } else if (hotkey.action == "Close Interface") {
        // Logic to close the interface
    } else if (hotkey.action == "Remove all ghosts from current map") {
        // Logic to remove all ghosts from the current map
    } else if (hotkey.action == "Remove ghost with specific MwId") {
        // Logic to remove ghost with specific MwId
    } else if (hotkey.action == "Remove PB Ghost") {
        // Logic to remove PB ghost
    } else {
        print("Action not implemented: " + hotkey.action);
    }
}
