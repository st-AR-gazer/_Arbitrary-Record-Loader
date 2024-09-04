namespace HotkeyManager {

    bool showAddHotkeyUI = false;
    bool showEditHotkeyUI = false;
    string selectedAction = "";
    string actionToEdit = "";
    array<string> newKeyCombination;
    array<string> editKeyCombination;
    int loadXPosition = 1;
    string configFilePath = IO::FromStorageFolder("hotkeys_config.ini");

    class Hotkey {
        array<string> keyCombination;
        string action;
        int extraValue = -1;

        Hotkey(array<string> keyCombination, const string &in action, int extraValue = -1) {
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
        "Remove all ghosts from current map", "Remove PB Ghost", 
        "Open/Close Interface", "Open Interface", "Close Interface"
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

    void RegisterHotkey(array<string> keyCombination, const string &in action, int extraValue = -1) {
        Hotkey@ hotkey = Hotkey(keyCombination, action, extraValue);
        array<Hotkey@>@ hotkeysList;
        
        if (hotkeyMappings.Exists(action)) {
            @hotkeysList = cast<array<Hotkey@>@>(hotkeyMappings[action]);
        } else {
            @hotkeysList = array<Hotkey@>();
            hotkeyMappings.Set(action, @hotkeysList);
        }

        hotkeysList.InsertLast(hotkey);
        SaveHotkeysToFile();
    }

    void UpdateHotkey(const string &in action, int hotkeyIndex, array<string> newKeyCombination, int extraValue = -1) {
        if (hotkeyMappings.Exists(action)) {
            array<Hotkey@>@ hotkeysList = cast<array<Hotkey@>@>(hotkeyMappings[action]);
            if (hotkeyIndex >= 0 && hotkeyIndex < int(hotkeysList.Length)) {
                Hotkey@ hotkey = hotkeysList[hotkeyIndex];
                hotkey.keyCombination = newKeyCombination;
                hotkey.extraValue = extraValue;
                SaveHotkeysToFile();
            }
        }
    }

    void RemoveHotkey(const string &in action, int hotkeyIndex) {
        if (hotkeyMappings.Exists(action)) {
            array<Hotkey@>@ hotkeysList = cast<array<Hotkey@>@>(hotkeyMappings[action]);
            if (hotkeyIndex >= 0 && hotkeyIndex < int(hotkeysList.Length)) {
                hotkeysList.RemoveAt(hotkeyIndex);
                if (hotkeysList.Length == 0) {
                    hotkeyMappings.Delete(action);
                }
                SaveHotkeysToFile();
            }
        }
    }

    Hotkey@ GetHotkeyFromCombination(array<string>@ pressedKeys) {
        array<string> keys = hotkeyMappings.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            array<Hotkey@>@ hotkeysList = cast<array<Hotkey@>@>(hotkeyMappings[keys[i]]);
            for (uint j = 0; j < hotkeysList.Length; j++) {
                if (CompareKeyCombinations(hotkeysList[j].keyCombination, pressedKeys)) {
                    return hotkeysList[j];
                }
            }
        }
        return null;
    }

    void ExecuteHotkeyAction(Hotkey@ hotkey) {
        if (hotkey.action == "Load top 1 time") {
            LoadRecordFromArbitraryMap::LoadSelectedRecord(get_CurrentMap(), "0", "AnyMap");
        } else if (hotkey.action == "Load top 2 time") {
            LoadRecordFromArbitraryMap::LoadSelectedRecord(get_CurrentMap(), "1", "AnyMap");
        } else if (hotkey.action == "Load top 3 time") {
            LoadRecordFromArbitraryMap::LoadSelectedRecord(get_CurrentMap(), "2", "AnyMap");
        } else if (hotkey.action == "Load top 4 time") {
            LoadRecordFromArbitraryMap::LoadSelectedRecord(get_CurrentMap(), "3", "AnyMap");
        } else if (hotkey.action == "Load top 5 time") {
            LoadRecordFromArbitraryMap::LoadSelectedRecord(get_CurrentMap(), "4", "AnyMap");
        } else if (hotkey.action == "Load X time" && hotkey.extraValue > 0) {
            LoadRecordFromArbitraryMap::LoadSelectedRecord(get_CurrentMap(), tostring(hotkey.extraValue - 1), "AnyMap");
        } else if (hotkey.action == "Open/Close Interface") {
            S_windowOpen = !S_windowOpen;
        } else if (hotkey.action == "Open Interface") {
            S_windowOpen = true;
        } else if (hotkey.action == "Close Interface") {
            S_windowOpen = false;
        } else if (hotkey.action == "Remove all ghosts from current map") {
            RecordManager::RemoveAllRecords();
        } else if (hotkey.action == "Remove PB Ghost") {
            RecordManager::RemovePBRecord();
        } else {
            log("Action not implemented: " + hotkey.action, LogLevel::Warn, 143, "ExecuteHotkeyAction");
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
            array<Hotkey@>@ hotkeysList = cast<array<Hotkey@>@>(hotkeyMappings[keys[i]]);
            for (uint j = 0; j < hotkeysList.Length; j++) {
                Hotkey@ hotkey = hotkeysList[j];
                content += hotkey.action + "=" + JoinKeyCombination(hotkey.keyCombination) + "\n";
            }
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
