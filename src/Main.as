void Main() {
    startnew(MainCoro);
    startnew(GhostLoader::ClearTaskCoro);
}

void MainCoro() {
    while (true) {
        yield();
        GhostLoader::CheckHotkey();
        _UI::OpenFileDialogWindow();
    }
}