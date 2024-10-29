namespace AllowCheck {
    interface IAllownessCheck {
        void OnMapLoad();
        bool IsConditionMet();
        string GetDisallowReason();
    }

    array<IAllownessCheck@> allownessModules;

    void InitializeAllowCheck() {
        allownessModules.InsertLast(GamemodeAllowness::CreateInstance());
        allownessModules.InsertLast(MapcommentAllowness::CreateInstance());

        if (allownessModules.Length > 0) startnew(OnMapLoadWrapper0);
        if (allownessModules.Length > 1) startnew(OnMapLoadWrapper1);
    }
    void OnMapLoadWrapper0() { allownessModules[0].OnMapLoad(); }
    void OnMapLoadWrapper1() { allownessModules[1].OnMapLoad(); }


    bool ConditionCheckMet() {
        for (uint i = 0; i < allownessModules.Length; i++) {
            if (!allownessModules[i].IsConditionMet()) {
                return false;
            }
        }
        return true;
    }

    bool AllowedToLoadRecords() {
        if (!ConditionCheckMet()) {
            log("Not all conditions have been checked or passed, records cannot be loaded.", LogLevel::Warn, 20, "AllowedToLoadRecords");
            return false;
        }
        return true;
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

        bool IsConditionMet() { return isAllowed; }

        string GetDisallowReason() {
            return isAllowed ? "" : "You cannot load maps in the blacklisted game mode.";
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

        void OnMapLoad() {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto map = app.RootMap;
            if (map is null) return;

            MapperSetting setting = DetermineMapperSetting(map);

            switch (setting) {
                case MapperSetting::Hide:
                    log("Map loading disabled due to ARL Hide setting.", LogLevel::Warn, 138, "OnMapLoad");
                    isAllowed = false;
                    disallowReason = "Map loading disabled due to ARL Hide setting.";
                    break;

                case MapperSetting::HideUCI:
                    log("Map loading disabled due to UCI Hide setting.", LogLevel::Warn, 143, "OnMapLoad");
                    isAllowed = false;
                    disallowReason = "Map loading disabled due to UCI Hide setting.";
                    break;

                case MapperSetting::Order:
                case MapperSetting::Xdd:
                case MapperSetting::None:
                default:
                    isAllowed = true;
                    disallowReason = "";
                    break;
            }
        }

        bool IsConditionMet() {
            return isAllowed;
        }

        string GetDisallowReason() {
            return isAllowed ? "" : disallowReason;
        }

        MapperSetting DetermineMapperSetting(CGameCtnChallenge@ map) {
            if (map is null) return MapperSetting::None;
            string comment = string(map.Comments).ToLower();

            if (comment.Contains("/arl hide")) {
                return MapperSetting::Hide;
            }
            else if (comment.Contains("/uci hide")) {
                return MapperSetting::HideUCI;
            } else if (comment.Contains("/uci order")) {
                return MapperSetting::Order;
            } else if (comment.Contains("/uci xdd")) {
                return MapperSetting::Xdd;
            }

            auto app = cast<CGameManiaPlanet>(GetApp());
            auto arena = cast<CSmArena>(app.CurrentPlayground);
            if (arena is null) return MapperSetting::None;

            uint startOrder = 0;
            for (uint i = 0; i < arena.MapLandmarks.Length; i++) {
                auto lm = arena.MapLandmarks[i];
                if (lm.Waypoint is null && lm.Order > 65535) {
                    startOrder = lm.Order;
                    break;
                }
                if (lm.Waypoint is null) continue;
                if (lm.Waypoint.IsMultiLap && lm.Order > 65535) {
                    startOrder = lm.Order;
                    continue;
                }
            }

            if (startOrder > 65530) {
                if (startOrder == 65531) return MapperSetting::Hide;
                if (startOrder == 65537) return MapperSetting::HideUCI;
                if (startOrder == 65536) return MapperSetting::Order;
                if (startOrder == 65539) return MapperSetting::Xdd;
            }

            return MapperSetting::None;
        }
    }

    AllowCheck::IAllownessCheck@ CreateInstance() {
        return MapcommentAllownessCheck();
    }
}