namespace HotkeyManager {

    bool showAddHotkeyUI = false;
    bool showEditHotkeyUI = false;
    string selectedAction = "";
    string actionToEdit = "";
    array<string> newKeyCombination;
    array<string> editKeyCombination;
    string configFilePath = IO::FromStorageFolder("hotkeys_config.txt");

    class Hotkey {
        array<string> keyCombination;
        string action;
        int extraValue = -1;

        Hotkey(array<string> keyCombination, string action, int extraValue = -1) {
            this.keyCombination = keyCombination;
            this.action = action;
            this.extraValue = extraValue;
        }

        string get_description() const {
            string keys = "";
            for (uint i = 0; i < keyCombination.Length; i++) {
                if (i > 0) keys += " + ";
                keys += keyCombination[i];
            }
            return keys + " : " + action;
        }
    }

    dictionary hotkeyMappings;

    array<string> availableActions = {
        "Load top 1 time", "Load top 2 time", "Load top 3 time",
        "Load top 4 time", "Load top 5 time", "Load X time",
        "Remove all ghosts from current map", "Remove ghost with specific MwId",
        "Remove PB Ghost", "Open/Close Interface", "Open Interface", "Close Interface"
    };

    array<string> GenerateKeyList() {
        array<string> keys;
        for (uint i = 0; i <= 254; i++) {
            VirtualKey vKey = VirtualKey(i);
            string keyName = tostring(vKey);
            if (keyName != "Unknown") {
                keys.InsertLast(keyName);
            }
        }
        return keys;
    }

    bool CompareKeyCombinations(array<string>@ combo1, array<string>@ combo2) {
        if (combo1.Length != combo2.Length) return false;
        for (uint i = 0; i < combo1.Length; i++) {
            if (combo1[i] != combo2[i]) return false;
        }
        return true;
    }

    string JoinKeyCombination(array<string>@ keys) {
        return string::Join(keys, "+");
    }

    void RegisterHotkey(array<string> keyCombination, string action, int extraValue = -1) {
        Hotkey@ hotkey = Hotkey(keyCombination, action, extraValue);
        hotkeyMappings.Set(action, @hotkey);
        SaveHotkeysToFile();
    }

    void UpdateHotkey(string action, array<string> newKeyCombination, int extraValue = -1) {
        if (hotkeyMappings.Exists(action)) {
            Hotkey@ hotkey = cast<Hotkey@>(hotkeyMappings[action]);
            hotkey.keyCombination = newKeyCombination;
            hotkey.extraValue = extraValue;
            SaveHotkeysToFile();
        } else {
            RegisterHotkey(newKeyCombination, action, extraValue);
        }
    }

    void RemoveHotkey(string action) {
        if (hotkeyMappings.Exists(action)) {
            hotkeyMappings.Delete(action);
            SaveHotkeysToFile();
        }
    }

    Hotkey@ GetHotkeyFromCombination(array<string>@ pressedKeys) {
        array<string> keys = hotkeyMappings.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            Hotkey@ hotkey = cast<Hotkey@>(hotkeyMappings[keys[i]]);
            if (CompareKeyCombinations(hotkey.keyCombination, pressedKeys)) {
                return hotkey;
            }
        }
        return null;
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
            // Logic to load the specific time based on extraValue
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

    void LoadHotkeysFromFile() {
        if (!IO::FileExists(configFilePath)) return;

        string configContent = _IO::File::ReadFileToEnd(configFilePath);
        array<string> lines = configContent.Split("\n");
        for (uint i = 0; i < lines.Length; i++) {
            if (lines[i].Trim().Length == 0) continue;

            array<string> parts = lines[i].Split("=");
            if (parts.Length == 2) {
                string action = parts[0];
                array<string> keyCombo = parts[1].Split("+");
                RegisterHotkey(keyCombo, action);
            }
        }
    }

    void SaveHotkeysToFile() {
        array<string> keys = hotkeyMappings.GetKeys();
        string content = "";

        for (uint i = 0; i < keys.Length; i++) {
            Hotkey@ hotkey = cast<Hotkey@>(hotkeyMappings[keys[i]]);
            content += hotkey.action + "=" + JoinKeyCombination(hotkey.keyCombination) + "\n";
        }

        IO::File configFile(configFilePath, IO::FileMode::Write);
        configFile.Write(content);
        configFile.Close();
    }

    void InitHotkeys() {
        LoadHotkeysFromFile();
    }

    UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
        array<string> pressedKeys;

        if (down) {
            pressedKeys.InsertLast(tostring(key));
            Hotkey@ hotkey = GetHotkeyFromCombination(pressedKeys);
            if (hotkey !is null) {
                ExecuteHotkeyAction(hotkey);
            }
        } else {
            int index = pressedKeys.FindByRef(tostring(key));
            if (index >= 0) {
                pressedKeys.RemoveAt(index);
            }
        }
        return UI::InputBlocking::DoNothing;
    }
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    HotkeyManager::OnKeyPress(down, key);

    return UI::InputBlocking::DoNothing;
}
