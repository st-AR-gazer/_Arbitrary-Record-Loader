void Main() {
    HotkeyManager::InitHotkeys();

    startnew(Server::StartHttpServer);
    InitApi();
    InitFolders();
    // InitMoveDummy();
    OfficialManager::DownloadingFiles::Init();
    OfficialManager::UI::Init();
    OtherManager::CDN::Init();

    startnew(MapTracker::MapMonitor);
}

void InitApi() {
    @api = NadeoApi();
}

void InitFolders() {
    IO::CreateFolder(Server::replayARL, true);
    IO::CreateFolder(Server::replayARLTmp, true);
    IO::CreateFolder(Server::replayARLDummy, true);
    IO::CreateFolder(Server::replayARLAutoMove, true);

    IO::CreateFolder(Server::serverDirectory, true);
    IO::CreateFolder(Server::serverDirectoryAutoMove, true);

    IO::CreateFolder(Server::savedFilesDirectory, true);
    IO::CreateFolder(Server::savedJsonDirectory, true);

    IO::CreateFolder(Server::currentMapRecords, true);
    IO::CreateFolder(Server::currentMapRecordsValidationReplay, true);
    IO::CreateFolder(Server::currentMapRecordsGPS, true);

    IO::CreateFolder(Server::serverDirectoryMedal, true);

    IO::CreateFolder(Server::linksDirectory, true);
    IO::CreateFolder(Server::linksFilesDirectory, true);

    IO::CreateFolder(Server::specificDownloadedFilesDirectory, true);
    IO::CreateFolder(Server::specificDownloadedJsonFilesDirectory, true);
    IO::CreateFolder(Server::specificDownloadedCreatedProfilesDirectory, true);
        
    IO::CreateFolder(Server::officialFilesDirectory, true);
    IO::CreateFolder(Server::officialInfoFilesDirectory, true);
    IO::CreateFolder(Server::officialJsonFilesDirectory, true);
}

// void InitMoveDummy() {
//     string storagePath = IO::FromUserGameFolder("Replays/ArbitraryRecordLoader/Dummy/CTmRaceResult_VTable_Ptr.Replay.Gbx");
//     _IO::File::MoveSourceFileToNonSource("src/Dummy/CTmRaceResult_VTable_Ptr.Replay.Gbx", storagePath);
// }
