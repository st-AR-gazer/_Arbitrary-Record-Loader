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

        allownessModules.InsertLast(GamemodeAllowness::CreateInstance());
        allownessModules.InsertLast(MapcommentAllowness::CreateInstance());

        startnew(InitializeAllModules);
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

//       ___           ___           ___                    ___           ___           ___           ___           ___           ___           ___           ___                    ___           ___       ___       ___           ___           ___           ___           ___           ___                    ___           ___           ___     
//      /\__\         /\  \         /\  \                  /\  \         /\  \         /\__\         /\  \         /\__\         /\  \         /\  \         /\  \                  /\  \         /\__\     /\__\     /\  \         /\__\         /\__\         /\  \         /\  \         /\  \                  /\__\         /\  \         /\  \    
//     /::|  |       /::\  \       /::\  \                /::\  \       /::\  \       /::|  |       /::\  \       /::|  |       /::\  \       /::\  \       /::\  \                /::\  \       /:/  /    /:/  /    /::\  \       /:/ _/_       /::|  |       /::\  \       /::\  \       /::\  \                /::|  |       /::\  \       /::\  \   
//    /:|:|  |      /:/\:\  \     /:/\:\  \              /:/\:\  \     /:/\:\  \     /:|:|  |      /:/\:\  \     /:|:|  |      /:/\:\  \     /:/\:\  \     /:/\:\  \              /:/\:\  \     /:/  /    /:/  /    /:/\:\  \     /:/ /\__\     /:|:|  |      /:/\:\  \     /:/\ \  \     /:/\ \  \              /:|:|  |      /:/\:\  \     /:/\:\  \  
//   /:/|:|__|__   /::\~\:\  \   /::\~\:\  \            /:/  \:\  \   /::\~\:\  \   /:/|:|__|__   /::\~\:\  \   /:/|:|__|__   /:/  \:\  \   /:/  \:\__\   /::\~\:\  \            /::\~\:\  \   /:/  /    /:/  /    /:/  \:\  \   /:/ /:/ _/_   /:/|:|  |__   /::\~\:\  \   _\:\~\ \  \   _\:\~\ \  \            /:/|:|__|__   /:/  \:\  \   /:/  \:\__\ 
//  /:/ |::::\__\ /:/\:\ \:\__\ /:/\:\ \:\__\          /:/__/_\:\__\ /:/\:\ \:\__\ /:/ |::::\__\ /:/\:\ \:\__\ /:/ |::::\__\ /:/__/ \:\__\ /:/__/ \:|__| /:/\:\ \:\__\          /:/\:\ \:\__\ /:/__/    /:/__/    /:/__/ \:\__\ /:/_/:/ /\__\ /:/ |:| /\__\ /:/\:\ \:\__\ /\ \:\ \ \__\ /\ \:\ \ \__\          /:/ |::::\__\ /:/__/ \:\__\ /:/__/ \:|__|
//  \/__/~~/:/  / \/__\:\/:/  / \/__\:\/:/  /          \:\  /\ \/__/ \/__\:\/:/  / \/__/~~/:/  / \:\~\:\ \/__/ \/__/~~/:/  / \:\  \ /:/  / \:\  \ /:/  / \:\~\:\ \/__/          \/__\:\/:/  / \:\  \    \:\  \    \:\  \ /:/  / \:\/:/ /:/  / \/__|:|/:/  / \:\~\:\ \/__/ \:\ \:\ \/__/ \:\ \:\ \/__/          \/__/~~/:/  / \:\  \ /:/  / \:\  \ /:/  /
//        /:/  /       \::/  /       \::/  /            \:\ \:\__\        \::/  /        /:/  /   \:\ \:\__\         /:/  /   \:\  /:/  /   \:\  /:/  /   \:\ \:\__\                 \::/  /   \:\  \    \:\  \    \:\  /:/  /   \::/_/:/  /      |:/:/  /   \:\ \:\__\    \:\ \:\__\    \:\ \:\__\                  /:/  /   \:\  /:/  /   \:\  /:/  / 
//       /:/  /        /:/  /         \/__/              \:\/:/  /        /:/  /        /:/  /     \:\ \/__/        /:/  /     \:\/:/  /     \:\/:/  /     \:\ \/__/                 /:/  /     \:\  \    \:\  \    \:\/:/  /     \:\/:/  /       |::/  /     \:\ \/__/     \:\/:/  /     \:\/:/  /                 /:/  /     \:\/:/  /     \:\/:/  /  
//      /:/  /        /:/  /                              \::/  /        /:/  /        /:/  /       \:\__\         /:/  /       \::/  /       \::/__/       \:\__\                  /:/  /       \:\__\    \:\__\    \::/  /       \::/  /        /:/  /       \:\__\        \::/  /       \::/  /                 /:/  /       \::/  /       \::/__/   
//      \/__/         \/__/                                \/__/         \/__/         \/__/         \/__/         \/__/         \/__/         ~~            \/__/                  \/__/         \/__/     \/__/     \/__/         \/__/         \/__/         \/__/         \/__/         \/__/                  \/__/         \/__/                
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
                log("Map loading disabled due to blacklisted mode: " + mode, LogLevel::Warn, 59, "OnMapLoad");
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


//       ___           ___           ___                    ___           ___           ___           ___           ___           ___           ___                    ___           ___       ___       ___           ___           ___           ___           ___           ___                    ___           ___           ___     
//      /\__\         /\  \         /\  \                  /\  \         /\  \         /\__\         /\__\         /\  \         /\__\         /\  \                  /\  \         /\__\     /\__\     /\  \         /\__\         /\__\         /\  \         /\  \         /\  \                  /\__\         /\  \         /\  \    
//     /::|  |       /::\  \       /::\  \                /::\  \       /::\  \       /::|  |       /::|  |       /::\  \       /::|  |        \:\  \                /::\  \       /:/  /    /:/  /    /::\  \       /:/ _/_       /::|  |       /::\  \       /::\  \       /::\  \                /::|  |       /::\  \       /::\  \   
//    /:|:|  |      /:/\:\  \     /:/\:\  \              /:/\:\  \     /:/\:\  \     /:|:|  |      /:|:|  |      /:/\:\  \     /:|:|  |         \:\  \              /:/\:\  \     /:/  /    /:/  /    /:/\:\  \     /:/ /\__\     /:|:|  |      /:/\:\  \     /:/\ \  \     /:/\ \  \              /:|:|  |      /:/\:\  \     /:/\:\  \  
//   /:/|:|__|__   /::\~\:\  \   /::\~\:\  \            /:/  \:\  \   /:/  \:\  \   /:/|:|__|__   /:/|:|__|__   /::\~\:\  \   /:/|:|  |__       /::\  \            /::\~\:\  \   /:/  /    /:/  /    /:/  \:\  \   /:/ /:/ _/_   /:/|:|  |__   /::\~\:\  \   _\:\~\ \  \   _\:\~\ \  \            /:/|:|__|__   /:/  \:\  \   /:/  \:\__\ 
//  /:/ |::::\__\ /:/\:\ \:\__\ /:/\:\ \:\__\          /:/__/ \:\__\ /:/__/ \:\__\ /:/ |::::\__\ /:/ |::::\__\ /:/\:\ \:\__\ /:/ |:| /\__\     /:/\:\__\          /:/\:\ \:\__\ /:/__/    /:/__/    /:/__/ \:\__\ /:/_/:/ /\__\ /:/ |:| /\__\ /:/\:\ \:\__\ /\ \:\ \ \__\ /\ \:\ \ \__\          /:/ |::::\__\ /:/__/ \:\__\ /:/__/ \:|__|
//  \/__/~~/:/  / \/__\:\/:/  / \/__\:\/:/  /          \:\  \  \/__/ \:\  \ /:/  / \/__/~~/:/  / \/__/~~/:/  / \:\~\:\ \/__/ \/__|:|/:/  /    /:/  \/__/          \/__\:\/:/  / \:\  \    \:\  \    \:\  \ /:/  / \:\/:/ /:/  / \/__|:|/:/  / \:\~\:\ \/__/ \:\ \:\ \/__/ \:\ \:\ \/__/          \/__/~~/:/  / \:\  \ /:/  / \:\  \ /:/  /
//        /:/  /       \::/  /       \::/  /            \:\  \        \:\  /:/  /        /:/  /        /:/  /   \:\ \:\__\       |:/:/  /    /:/  /                    \::/  /   \:\  \    \:\  \    \:\  /:/  /   \::/_/:/  /      |:/:/  /   \:\ \:\__\    \:\ \:\__\    \:\ \:\__\                  /:/  /   \:\  /:/  /   \:\  /:/  / 
//       /:/  /        /:/  /         \/__/              \:\  \        \:\/:/  /        /:/  /        /:/  /     \:\ \/__/       |::/  /     \/__/                     /:/  /     \:\  \    \:\  \    \:\/:/  /     \:\/:/  /       |::/  /     \:\ \/__/     \:\/:/  /     \:\/:/  /                 /:/  /     \:\/:/  /     \:\/:/  /  
//      /:/  /        /:/  /                              \:\__\        \::/  /        /:/  /        /:/  /       \:\__\         /:/  /                               /:/  /       \:\__\    \:\__\    \::/  /       \::/  /        /:/  /       \:\__\        \::/  /       \::/  /                 /:/  /       \::/  /       \::/__/   
//      \/__/         \/__/                                \/__/         \/__/         \/__/         \/__/         \/__/         \/__/                                \/__/         \/__/     \/__/     \/__/         \/__/         \/__/         \/__/         \/__/         \/__/                  \/__/         \/__/                
// MAP COMMENT ALLOWNESS MOD

namespace MapcommentAllowness {
    enum MapperSetting {
        Hide,
        HideUCI,
        Order,
        Xdd,
        None
    }

    class MapcommentAllownessCheck : AllowCheck::IAllownessCheck {
        bool isAllowed = false;
        string disallowReason = "";
        bool initialized = false;

        void Initialize() {
            OnMapLoad();
            initialized = true;
        }
        bool IsInitialized() { return initialized; }
        bool IsConditionMet() { return isAllowed; }
        string GetDisallowReason() { return isAllowed ? "" : disallowReason; }

        // void OnMapLoad() {
        //     isAllowed = true;
        // }

        // This doesn't properly check for anything Arena is always null 

        void OnMapLoad() {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto map = app.RootMap;
            if (map is null) {
                log("MapcommentAllownessCheck: Map is null in OnMapLoad.", LogLevel::Warn, 201, "OnMapLoad");
                isAllowed = false;
                disallowReason = "Map is null.";
                return;
            }

            return;

            // MapperSetting setting = DetermineMapperSetting(map);
            // log("MapcommentAllownessCheck: MapperSetting determined as " + EnumToString(setting), LogLevel::Info, 202, "OnMapLoad");

            // switch (setting) {
            //     case MapperSetting::Hide:
            //         log("MapcommentAllownessCheck: Map loading disabled due to ARL Hide setting.", LogLevel::Warn, 203, "OnMapLoad");
            //         isAllowed = false;
            //         disallowReason = "Map loading disabled due to ARL Hide setting.";
            //         break;

            //     case MapperSetting::HideUCI:
            //         log("MapcommentAllownessCheck: Map loading disabled due to UCI Hide setting.", LogLevel::Warn, 204, "OnMapLoad");
            //         isAllowed = false;
            //         disallowReason = "Map loading disabled due to UCI Hide setting.";
            //         break;

            //     case MapperSetting::Order:
            //     case MapperSetting::Xdd:
            //     case MapperSetting::None:
            //         log("MapcommentAllownessCheck: Map loading allowed.", LogLevel::Info, 205, "OnMapLoad");
            //         isAllowed = true;
            //         disallowReason = "";
            //         break;

            //     default:
            //         log("MapcommentAllownessCheck: Unknown MapperSetting. Defaulting to disallow.", LogLevel::Warn, 206, "OnMapLoad");
            //         isAllowed = false;
            //         disallowReason = "Unknown MapperSetting.";
            //         break;
            // }

            // log("MapcommentAllownessCheck: isAllowed set to " + (isAllowed ? "true" : "false"), LogLevel::Info, 207, "OnMapLoad");
        }

        // MapperSetting DetermineMapperSetting(CGameCtnChallenge@ map) {
        //     string comment = string(map.Comments).ToLower();

        //     if (comment.Contains("/arl hide")) {
        //         return MapperSetting::Hide;
        //     }
        //     else if (comment.Contains("/uci hide")) {
        //         return MapperSetting::HideUCI;
        //     } 
        //     else if (comment.Contains("/uci order")) {
        //         return MapperSetting::Order;
        //     } 
        //     else if (comment.Contains("/uci xdd")) {
        //         return MapperSetting::Xdd;
        //     }

        //     auto app = cast<CGameManiaPlanet>(GetApp());
        //     auto arena = cast<CSmArena>(app.CurrentPlayground);
        //     if (arena is null) {
        //         log("MapcommentAllownessCheck: Arena is null. Returning MapperSetting::None.", LogLevel::Warn, 106, "DetermineMapperSetting");
        //         return MapperSetting::None;
        //     }

        //     uint startOrder = 0;
        //     for (uint i = 0; i < arena.MapLandmarks.Length; i++) {
        //         auto lm = arena.MapLandmarks[i];
        //         if (lm.Waypoint is null && lm.Order > 65535) {
        //             startOrder = lm.Order;
        //             log("MapcommentAllownessCheck: Found landmark with Order > 65535 without Waypoint. Order: " + startOrder, LogLevel::Info, 107, "DetermineMapperSetting");
        //             break;
        //         }
        //         if (lm.Waypoint is null) continue;
        //         if (lm.Waypoint.IsMultiLap && lm.Order > 65535) {
        //             startOrder = lm.Order;
        //             log("MapcommentAllownessCheck: Found multi-lap landmark with Order > 65535. Order: " + startOrder, LogLevel::Info, 108, "DetermineMapperSetting");
        //             continue;
        //         }
        //     }

        //     if (startOrder > 65530) {
        //         if (startOrder == 65531) {
        //             log("MapcommentAllownessCheck: Determined setting = Hide based on startOrder.", LogLevel::Info, 109, "DetermineMapperSetting");
        //             return MapperSetting::Hide;
        //         }
        //         if (startOrder == 65537) {
        //             log("MapcommentAllownessCheck: Determined setting = HideUCI based on startOrder.", LogLevel::Info, 110, "DetermineMapperSetting");
        //             return MapperSetting::HideUCI;
        //         }
        //         if (startOrder == 65536) {
        //             log("MapcommentAllownessCheck: Determined setting = Order based on startOrder.", LogLevel::Info, 111, "DetermineMapperSetting");
        //             return MapperSetting::Order;
        //         }
        //         if (startOrder == 65539) {
        //             log("MapcommentAllownessCheck: Determined setting = Xdd based on startOrder.", LogLevel::Info, 112, "DetermineMapperSetting");
        //             return MapperSetting::Xdd;
        //         }
        //     }

        //     log("MapcommentAllownessCheck: Determined setting = None.", LogLevel::Info, 113, "DetermineMapperSetting");
        //     return MapperSetting::None;
        // }

        // string EnumToString(MapperSetting setting) {
        //     switch (setting) {
        //         case MapperSetting::Hide: return "Hide";
        //         case MapperSetting::HideUCI: return "HideUCI";
        //         case MapperSetting::Order: return "Order";
        //         case MapperSetting::Xdd: return "Xdd";
        //         case MapperSetting::None: return "None";
        //         default: return "Unknown";
        //     }
        // }
    }

    AllowCheck::IAllownessCheck@ CreateInstance() {
        return MapcommentAllownessCheck();
    }
}