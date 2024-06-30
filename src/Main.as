void Main() {
    InitApi();

    string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
    _IO::File::SafeMoveSourceFileToNonSource("src/Conditions/CompanionDLLs/FileCreationTime.dll", dllPath);

    _IO::Folder::SafeCreateFolder(Server::serverDirectory);
    _IO::Folder::SafeCreateFolder(Server::serverDirectoryAutoMove);
    _IO::Folder::SafeCreateFolder(Server::savedFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::savedJsonDirectory);
    _IO::Folder::SafeCreateFolder(Server::validationFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::specificDownloadedFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::specificDownloadedJsonFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::officialFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::officialInfoFilesDirectory);
    _IO::Folder::SafeCreateFolder(Server::officialJsonFilesDirectory);

    OfficialManager::DownloadingFiles::Init();
    OfficialManager::UI::Init();

    startnew(Server::StartHttpServer);
    startnew(MapCoro);
}

void InitApi() {
    @api = NadeoApi();
}