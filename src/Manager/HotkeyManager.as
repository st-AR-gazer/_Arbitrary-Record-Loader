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
