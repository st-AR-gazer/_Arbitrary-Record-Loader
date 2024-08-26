string[] GameModeBlackList = {
    "TrackMania/TM_TimeAttack_Online", "TrackMania/TM_Rounds_Online"
};

namespace AllowCheck {
    bool AllowdToLoadRecords = true;

    namespace Chester {

        bool IsBlacklisted(string mode) {
            for (uint i = 0; i < GameModeBlackList.Length; i++) {
                if (mode.ToLower() == GameModeBlackList[i].ToLower()) {
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
                log("Map loading disabled due to blacklisted mode.", LogLevel::Warn, 60, "OnMapLoad");
                AllowdToLoadRecords = false;
                return;
            }

            AllowdToLoadRecords = true;
        }

    }

    namespace UciMapCheck {

        enum UciSetting {
            None = 0,
            Hide,
            Order,
            Xdd
        }

        UciSetting GetUciSetting(CGameCtnChallenge@ map) {
            if (map is null) return UciSetting::None;
            string comment = string(map.Comments).ToLower();

            if (comment.Contains("/uci hide")) {
                return UciSetting::Hide;
            } else if (comment.Contains("/uci order")) {
                return UciSetting::Order;
            } else if (comment.Contains("/uci xdd")) {
                return UciSetting::Xdd;
            }

            auto app = cast<CGameManiaPlanet>(GetApp());
            auto arena = cast<CSmArena>(app.CurrentPlayground);
            if (arena is null) return UciSetting::None;

            for (uint i = 0; i < arena.MapLandmarks.Length; i++) {
                auto landmark = arena.MapLandmarks[i];
                if (landmark.Waypoint is null && landmark.Order > 65535) {
                    uint startOrder = landmark.Order;

                    if ((startOrder - 65535) & 1 > 0) return UciSetting::Order;
                    if ((startOrder - 65535) & 2 > 0) return UciSetting::Hide;
                    if ((startOrder - 65535) & 4 > 0) return UciSetting::Xdd;
                }
            }

            return UciSetting::None;
        }

        void OnMapLoad() {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto map = app.RootMap;
            if (map is null) return;

            UciSetting setting = GetUciSetting(map);

            switch (setting) {
                case UciSetting::Hide:
                    log("Map loading disabled due to UCI Hide setting.", LogLevel::Warn, 70, "OnMapLoad");
                    AllowdToLoadRecords = false;
                    return;

                case UciSetting::Order:
                    log("Map loaded with UCI Order setting.", LogLevel::Info, 75, "OnMapLoad");
                    AllowdToLoadRecords = true;
                    break;

                case UciSetting::Xdd:
                    log("Map loaded with UCI Xdd setting.", LogLevel::Info, 80, "OnMapLoad");
                    AllowdToLoadRecords = true;
                    break;

                case UciSetting::None:
                default:
                    AllowdToLoadRecords = true;
                    // log("Map loaded without any UCI restrictions.", LogLevel::Info, 86, "OnMapLoad");
                    break;
            }
        }
    }

}