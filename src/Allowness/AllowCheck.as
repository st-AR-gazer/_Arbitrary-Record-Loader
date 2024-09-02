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
                log("Map loading disabled due to blacklisted mode.", LogLevel::Warn, 33, "OnMapLoad");
                AllowdToLoadRecords = false;
                return;
            }

            AllowdToLoadRecords = true;
        }

    }

    namespace MapCommentCheck {

        enum MapperSetting {
            None = 0,
            Hide,
            HideUCI,
            Order,
            Xdd
        }

        MapperSetting MapperSettings(CGameCtnChallenge@ map) {
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
                if (StartOrder == 65531) return MapperSetting::Hide;

                if (StartOrder == 65537) return MapperSetting::HideUCI;
                if (StartOrder == 65536) return MapperSetting::Order;
                if (StartOrder == 65539) return MapperSetting::Xdd;
            }

            return MapperSetting::None;
        }

        void OnMapLoad() {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto map = app.RootMap;
            if (map is null) return;

            auto setting = MapperSettings(map);

            switch (setting) {
                case MapperSetting::Hide:
                    log("Map loading disabled due to ARL Hide setting.", LogLevel::Warn, 108, "OnMapLoad");
                    AllowdToLoadRecords = false;
                    return;
                
                case MapperSetting::HideUCI:
                    log("Map loading disabled due to UCI Hide setting.", LogLevel::Warn, 113, "OnMapLoad");
                    AllowdToLoadRecords = false;
                    return;

                case MapperSetting::Order:
                    log("Map loaded with UCI Order setting.", LogLevel::Info, 118, "OnMapLoad");
                    AllowdToLoadRecords = true;
                    break;

                case MapperSetting::Xdd:
                    log("Map loaded with UCI Xdd setting.", LogLevel::Info, 123, "OnMapLoad");
                    AllowdToLoadRecords = true;
                    break;

                default:
                    AllowdToLoadRecords = true;
                    // log("Map loaded without any UCI restrictions.", LogLevel::Info, 129, "OnMapLoad");
                    break;
            }
        }
    }

}