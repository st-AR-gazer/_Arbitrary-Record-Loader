void Main() {
    InitApi();
    InitFolders();

    string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
    _IO::File::SafeMoveSourceFileToNonSource("src/Conditions/CompanionDLLs/FileCreationTime.dll", dllPath);

    OfficialManager::DownloadingFiles::Init();
    OfficialManager::UI::Init();

    startnew(Server::StartHttpServer);
    startnew(MapCoro);
}

void InitApi() {
    @api = NadeoApi();
}

void InitFolders() {
    _IO::Folder::SafeCreateFolder(Server::serverDirectory);
    _IO::Folder::SafeCreateFolder(Server::serverDirectoryAutoMove);

    _IO::Folder::SafeCreateFolder(Server::savedFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::savedJsonDirectory);

    _IO::Folder::SafeCreateFolder(Server::currentMapRecords);
    _IO::Folder::SafeCreateFolder(Server::currentMapRecordsValidationReplay);
    _IO::Folder::SafeCreateFolder(Server::currentMapRecordsGPS);

    _IO::Folder::SafeCreateFolder(Server::specificDownloadedFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::specificDownloadedJsonFilesDirectory);
    
    _IO::Folder::SafeCreateFolder(Server::officialFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::officialInfoFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::officialJsonFilesDirectory);
}