void Main() {
    startnew(Server::StartHttpServer);
    InitApi();
    InitFolders();
    InitMoveDummy();
    OfficialManager::DownloadingFiles::Init();
    OfficialManager::UI::Init();
    OtherManager::CDN::Init();

    string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
    _IO::File::SafeMoveSourceFileToNonSource("src/Conditions/CompanionDLLs/FileCreationTime.dll", dllPath);

    startnew(MapCoro);
}

void InitApi() {
    @api = NadeoApi();
}

void InitFolders() {
    _IO::Folder::SafeCreateFolder(Server::replayARL);
    _IO::Folder::SafeCreateFolder(Server::replayARLTmp);
    _IO::Folder::SafeCreateFolder(Server::replayARLDummy);
    _IO::Folder::SafeCreateFolder(Server::replayARLAutoMove);

    _IO::Folder::SafeCreateFolder(Server::serverDirectory);
    _IO::Folder::SafeCreateFolder(Server::serverDirectoryAutoMove);

    _IO::Folder::SafeCreateFolder(Server::savedFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::savedJsonDirectory);

    _IO::Folder::SafeCreateFolder(Server::currentMapRecords);
    _IO::Folder::SafeCreateFolder(Server::currentMapRecordsValidationReplay);
    _IO::Folder::SafeCreateFolder(Server::currentMapRecordsGPS);

    _IO::Folder::SafeCreateFolder(Server::specificDownloadedFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::specificDownloadedJsonFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::specificDownloadedCreatedProfilesDirectory);
    
    _IO::Folder::SafeCreateFolder(Server::officialFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::officialInfoFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::officialJsonFilesDirectory);
}

void InitMoveDummy() {
    string storagePath = IO::FromUserGameFolder("Replays/ArbitraryRecordLoader/Dummy/CTmRaceResult_VTable_Ptr.Replay.Gbx");
    _IO::File::SafeMoveSourceFileToNonSource("src/Dummy/CTmRaceResult_VTable_Ptr.Replay.Gbx", storagePath);
}