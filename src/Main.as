void Main() {
    // if(_IO::IsDirectory(IO::FromAppFolder("anzu.dll"))) print("true");

    startnew(MainCoro);
    startnew(GhostLoader::ClearTaskCoro);
}

void MainCoro() {
    while (true) {
        yield();
        GhostLoader::CheckHotkey();
        //_UI::FileExplorer::OpenFileDialogWindow();
    }
}