void Main() {
    string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
    _IO::SafeMoveSourceFileToNonSource("src/Conditions/CompanionDLLs/FileCreationTime.dll", dllPath, true);
}
