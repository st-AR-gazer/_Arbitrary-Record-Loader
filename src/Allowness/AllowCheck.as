// https://patorjk.com/software/taag/#p=display&f=Small

namespace AllowCheck {
    interface IAllownessCheck {
        void Initialize();
        bool IsConditionMet();
        string GetDisallowReason();
        bool IsInitialized();
    }

    array<IAllownessCheck@> allownessModules;
    bool isInitializing = false;

    void InitializeAllowCheck() {
        if (isInitializing) { return; }
        isInitializing = true;

        while (allownessModules.Length > 0) {allownessModules.RemoveLast();}

        // 

        allownessModules.InsertLast(GamemodeAllowness::CreateInstance());
        allownessModules.InsertLast(MapcommentAllowness::CreateInstance());

        // 

        startnew(InitializeAllModules);
    }

    void InitializeAllowCheckWithTimeout(uint timeout) {
        uint startTime = Time::Now;
        AllowCheck::InitializeAllowCheck();
        bool conditionMet = false;
        while (!conditionMet) { 
            if (Time::Now - startTime > timeout) { 
                NotifyWarn("Condition check timed out ("+timeout+" ms was given), assuming invalid state."); 
                break; 
            }
            yield(); 
            conditionMet = AllowCheck::ConditionCheckMet();
        }
    }

    void InitializeAllModules() {
        for (uint i = 0; i < allownessModules.Length; i++) { allownessModules[i].Initialize(); }
        isInitializing = false;
    }

    bool ConditionCheckMet() {
        bool allMet = true;
        for (uint i = 0; i < allownessModules.Length; i++) {
            auto module = allownessModules[i];
            bool initialized = module.IsInitialized();
            bool condition = module.IsConditionMet();
            // log("ConditionCheckMet: Module " + i + " initialized: " + (initialized ? "true" : "false") + ", condition met: " + (condition ? "true" : "false"), LogLevel::Info, 55, "ConditionCheckMet");
            if (!initialized || !condition) { allMet = false; }
        }
        return allMet;
    }

    string DissalowReason() {
        string reason = "";
        for (uint i = 0; i < allownessModules.Length; i++) {
            if (!allownessModules[i].IsConditionMet()) {
                reason += allownessModules[i].GetDisallowReason() + " ";
            }
        }
        return reason.Trim().Length > 0 ? reason.Trim() : "Unknown reason.";
    }
}

//   __  __   _   ___    ___   _   __  __ ___ __  __  ___  ___  ___     _   _    _    _____      ___  _ ___ ___ ___   __  __  ___  ___  
//  |  \/  | /_\ | _ \  / __| /_\ |  \/  | __|  \/  |/ _ \|   \| __|   /_\ | |  | |  / _ \ \    / / \| | __/ __/ __| |  \/  |/ _ \|   \ 
//  | |\/| |/ _ \|  _/ | (_ |/ _ \| |\/| | _|| |\/| | (_) | |) | _|   / _ \| |__| |_| (_) \ \/\/ /| .` | _|\__ \__ \ | |\/| | (_) | |) |
//  |_|  |_/_/ \_\_|    \___/_/ \_\_|  |_|___|_|  |_|\___/|___/|___| /_/ \_\____|____\___/ \_/\_/ |_|\_|___|___/___/ |_|  |_|\___/|___/ 
// MAP GAMEMODE ALLOWNESS MOD

namespace GamemodeAllowness {
    string[] GameModeBlackList = {
        "TM_COTDQualifications_Online", "TM_KnockoutDaily_Online"
    };

    class GamemodeAllownessCheck : AllowCheck::IAllownessCheck {
        bool isAllowed = false;
        bool initialized = false;
        
        void Initialize() {
            OnMapLoad();
            initialized = true;
        }
        bool IsInitialized() { return initialized; }
        bool IsConditionMet() { return isAllowed; }
        string GetDisallowReason() { return isAllowed ? "" : "You cannot load maps in the blacklisted game mode."; }

        // 

        void OnMapLoad() {
            auto net = cast<CGameCtnNetwork>(GetApp().Network);
            if (net is null) return;
            auto cnsi = cast<CGameCtnNetServerInfo>(net.ServerInfo);
            if (cnsi is null) return;
            string mode = cnsi.ModeName;

            if (mode.Length == 0 || !IsBlacklisted(mode)) {
                isAllowed = true;
            } else {
                // log("Map loading disabled due to blacklisted mode: " + mode, LogLevel::Warn, 107, "OnMapLoad");
                isAllowed = false;
            }
        }

        bool IsBlacklisted(const string &in mode) {
            return GameModeBlackList.Find(mode) >= 0;
        }        
    }

    AllowCheck::IAllownessCheck@ CreateInstance() {
        return GamemodeAllownessCheck();
    }
}


//   __  __   _   ___    ___ ___  __  __ __  __ ___ _  _ _____     _   _    _    _____      ___  _ ___ ___ ___   __  __  ___  ___  
//  |  \/  | /_\ | _ \  / __/ _ \|  \/  |  \/  | __| \| |_   _|   /_\ | |  | |  / _ \ \    / / \| | __/ __/ __| |  \/  |/ _ \|   \ 
//  | |\/| |/ _ \|  _/ | (_| (_) | |\/| | |\/| | _|| .` | | |    / _ \| |__| |_| (_) \ \/\/ /| .` | _|\__ \__ \ | |\/| | (_) | |) |
//  |_|  |_/_/ \_\_|    \___\___/|_|  |_|_|  |_|___|_|\_| |_|   /_/ \_\____|____\___/ \_/\_/ |_|\_|___|___/___/ |_|  |_|\___/|___/ 
// MAP COMMENT ALLOWNESS MOD

namespace MapcommentAllowness {
    enum MapperSetting {
        Hide,
        HideUCI,
        Order,
        Xdd,
        Always,
        None
    }

    class MapcommentAllownessCheck : AllowCheck::IAllownessCheck {
        bool isAllowed = true;
        string disallowReason = "";
        bool initialized = false;

        void Initialize() {
            OnMapLoad();
            initialized = true;
        }
        bool IsInitialized() { return initialized; }
        bool IsConditionMet() { return isAllowed; }
        string GetDisallowReason() { return isAllowed ? "" : disallowReason; }

        void OnMapLoad() {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto map = app.RootMap;
            if (map is null) {
                isAllowed = false;
                disallowReason = "Map is null.";
                return;
            }

            MapperSetting setting = DetermineMapperSetting(map);

            switch (setting) {
                case MapperSetting::Hide:
                    isAllowed = false;
                    disallowReason = "Map loading disabled due to ARL Hide setting.";
                    break;

                case MapperSetting::HideUCI:
                    isAllowed = false;
                    disallowReason = "Map loading disabled due to UCI Hide setting.";
                    break;

                case MapperSetting::Order:
                    isAllowed = true;
                    disallowReason = "";
                    break;

                case MapperSetting::Xdd:
                    isAllowed = true;
                    disallowReason = "";
                    break;

                case MapperSetting::Always:
                    isAllowed = true;
                    disallowReason = "";
                    break;

                case MapperSetting::None:
                    isAllowed = true;
                    disallowReason = "";
                    break;

                default:
                    isAllowed = true;
                    disallowReason = "";
                    break;
            }

            // log("MapcommentAllownessCheck: isAllowed set to " + (isAllowed ? "true" : "false"), LogLevel::Info, 200, "OnMapLoad");
        }

        MapperSetting DetermineMapperSetting(CGameCtnChallenge@ map) {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
            if (playground is null) {
                return MapperSetting::None;
            }

            uint startOrder = 0;
            for (uint i = 0; i < playground.Arena.MapLandmarks.Length; i++) {
                auto lm = playground.Arena.MapLandmarks[i];
                if (lm.Waypoint is null && lm.Order > 65535) {
                    startOrder = lm.Order;
                    break;
                }
                if (lm.Waypoint is null) continue;
                if (lm.Waypoint.IsMultiLap && lm.Order > 65535) {
                    startOrder = lm.Order;
                }
            }

            MapperSetting setting = MapperSetting::None;

            if (startOrder > 65530) {
                if (startOrder == 65531) {
                    setting = MapperSetting::Hide;
                }
                else if (startOrder == 65537) {
                    setting = MapperSetting::HideUCI;
                }
                else if (startOrder == 65536) {
                    setting = MapperSetting::Order;
                }
                else if (startOrder == 65539) {
                    setting = MapperSetting::Xdd;
                }
            }

            string comment = string(map.Comments).ToLower();

            if (comment.Contains("/arl hide")) {
                setting = MapperSetting::Hide;
            }
            if (comment.Contains("/uci hide")) {
                setting = MapperSetting::HideUCI;
            }
            if (comment.Contains("/uci order")) {
                setting = MapperSetting::Order;
            }
            if (comment.Contains("/uci xdd")) {
                setting = MapperSetting::Xdd;
            }
            if (comment.Contains("/uci always")) {
                setting = MapperSetting::Always;
            }

            // log("MapcommentAllownessCheck: Final MapperSetting determined as " + EnumToString(setting), LogLevel::Info, 258, "OnMapLoad");
            return setting;
        }

        string EnumToString(MapperSetting setting) {
            switch (setting) {
                case MapperSetting::Hide: return "Hide";
                case MapperSetting::HideUCI: return "HideUCI";
                case MapperSetting::Order: return "Order";
                case MapperSetting::Xdd: return "Xdd";
                case MapperSetting::Always: return "Always";
                case MapperSetting::None: return "None";
                default: return "Unknown";
            }
        }
    }

    AllowCheck::IAllownessCheck@ CreateInstance() {
        return MapcommentAllownessCheck();
    }
}