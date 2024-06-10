void x() {
    auto app = cast<CTrackMania>(GetApp());
    if (app is null) { return; }

    auto net = cast<CGameCtnNetwork>(app.Network);
    if (net is null) { return; }

    auto playgroundInterface = cast<CGameScriptHandlerPlaygroundInterface>(net.PlaygroundInterfaceScriptHandler);
    if (playgroundInterface is null) { return; }

    auto parrent = cast<CGameManiaAppPlaygroundCommon>(playgroundInterface.ParentApp);
    if (parrent is null) { return; }

    auto ghostMgr = cast<CGameCtnGhost>(parrent.GhostMgr);
    if (ghostMgr is null) { return; }

    auto ghost = cast<CGameGhostMgrScript>(ghostMgr);
    if (ghost is null) { return; }


}