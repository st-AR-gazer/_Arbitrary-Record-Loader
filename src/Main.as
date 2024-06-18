void Main() {
    // if(_IO::IsDirectory(IO::FromAppFolder("anzu.dll"))) print("true");

    startnew(MainCoro);
    startnew(GhostLoader::ClearTaskCoro);
}

void MainCoro() {
    string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
    _IO::SafeMoveSourceFileToNonSource("src/Conditions/CompanionDLLs/FileCreationTime.dll", dllPath, true);


    while (true) {
        yield();
        GhostLoader::CheckHotkey();
        //_UI::FileExplorer::OpenFileDialogWindow();
    }
}