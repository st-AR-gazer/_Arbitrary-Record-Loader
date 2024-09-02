string[] GameModeBlackList = {
    "TM_TimeAttack_Online", "TM_Rounds_Online"
};

// TrackMania/TM_TimeAttack_Online

namespace AllowCheck {
    bool AllowdToLoadRecords = true;

    namespace Chester {

        bool IsBlacklisted(string mode) {
            for (uint i = 0; i < GameModeBlackList.Length; i++) {
                if (mode.ToLower().Contains(GameModeBlackList[i].ToLower())) {
                    return true;
                }
            }
            return false;
        }

        void OnMapLoad() {
            auto net = cast<CGameCtnNetwork>(GetApp().Network);
            if (net is null) return;

            auto cnsi = cast<CGameCtnNetServerInfo>(net.ServerInfo);
            if (cnsi is null) return;

            wstring mode = cnsi.ModeName;
            if (mode.Length == 0) return;

            if (IsBlacklisted(mode)) {
                NotifyWarn("Loading records on the current map is disabled due to playing in the blacklisted mode: '" + mode + "'");
                log("Map loading disabled due to blacklisted mode.", LogLevel::Warn, 60, "OnMapLoad");
                AllowdToLoadRecords = false;
                return;
            }

            AllowdToLoadRecords = true;
        }

    }

    namespace MapCommentCheck {

        enum MapperSetting {
            uci_None = 0,
            uci_Hide,
            uci_Order,
            uci_Xdd,
            
            arl_None = 0,
            arl_Hide
        }

        MapperSetting MapperSettings(CGameCtnChallenge@ map) {
            if (map is null) return MapperSetting::arl_None;
            string comment = string(map.Comments).ToLower();

            if (comment.Contains("/arl hide")) {
                return MapperSetting::arl_Hide;
            }
            else if (comment.Contains("/uci hide")) {
                return MapperSetting::uci_Hide;
            } else if (comment.Contains("/uci order")) {
                return MapperSetting::uci_Order;
            } else if (comment.Contains("/uci xdd")) {
                return MapperSetting::uci_Xdd;
            }

            auto app = cast<CGameManiaPlanet>(GetApp());
            auto arena = cast<CSmArena>(app.CurrentPlayground);
            if (arena is null) return MapperSetting::arl_None;

            uint StartOrder = 0;
            for (uint i = 0; i < arena.MapLandmarks.Length; i++) {
                auto lm = arena.MapLandmarks[i];
                // starting block
                if (lm.Waypoint is null && lm.Order > 65535) {
                    StartOrder = lm.Order;
                    break;
                }
                if (lm.Waypoint is null) continue;
                // multilap -- we keep going b/c maybe there's a starting block
                if (lm.Waypoint.IsMultiLap && lm.Order > 65535) {
                    StartOrder = lm.Order;
                    continue;
                }
            }

            if (StartOrder > 65530) {
                if (StartOrder == 65531) return MapperSetting::arl_Hide;

                if (StartOrder == 65537) return MapperSetting::uci_Hide;
                if (StartOrder == 65536) return MapperSetting::uci_Order;
                if (StartOrder == 65539) return MapperSetting::uci_Xdd;
            }

            return MapperSetting::arl_None;
        }

        void OnMapLoad() {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto map = app.RootMap;
            if (map is null) return;

            MapperSetting setting = MapperSetting(map);

            switch (setting) {
                case MapperSetting::arl_Hide:
                    log("Map loading disabled due to ARL Hide setting.", LogLevel::Warn, 65, "OnMapLoad");
                    AllowdToLoadRecords = false;
                    return;

                case MapperSetting::uci_Hide:
                    log("Map loading disabled due to UCI Hide setting.", LogLevel::Warn, 70, "OnMapLoad");
                    AllowdToLoadRecords = false;
                    return;

                case MapperSetting::uci_Order:
                    log("Map loaded with UCI Order setting.", LogLevel::Info, 75, "OnMapLoad");
                    AllowdToLoadRecords = true;
                    break;

                case MapperSetting::uci_Xdd:
                    log("Map loaded with UCI Xdd setting.", LogLevel::Info, 80, "OnMapLoad");
                    AllowdToLoadRecords = true;
                    break;

                default:
                    AllowdToLoadRecords = true;
                    // log("Map loaded without any UCI restrictions.", LogLevel::Info, 86, "OnMapLoad");
                    break;
            }
        }
    }

}