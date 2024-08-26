string[] GameModeBlackList = {
    ""
};

namespace AllowCheck {

    void OnMapLoad() {
        auto net = cast<CGameCtnNetwork>(GetApp().Network);
        if (net is null) return;

        auto cnsi = cast<CGameCtnNetServerInfo>(net.ServerInfo);
        if (cnsi is null) return;

        auto mode = cnsi.ModeName;
        if (mode.Length == 0) return;

        print("Mode: " + mode);
    }

}