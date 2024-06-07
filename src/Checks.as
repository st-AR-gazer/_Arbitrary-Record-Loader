bool IsInMap() {
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app is null) return false;

    CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
    return !(playground is null || playground.Arena.Players.Length == 0);
}

