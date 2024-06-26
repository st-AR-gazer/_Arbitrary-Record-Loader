void SaveRecordPath(const string &in overwriteFilePath = "") {
    string filePath = _IO::FileExplorer::Exports::GetExportPath();
    if (filePath.Length == 0) {
        NotifyError("Invalid file path.");
        return;
    }
    if (overwriteFilePath.Length > 0) {
        filePath = overwriteFilePath;
    }

    log("Saving ghost to URL: " + filePath, LogLevel::Info, 11, "SaveRecordPath");

    int ID = Math::Rand(0, 999999999);

    bool fromLocalFile;

    if (filePath.StartsWith("http://") || filePath.StartsWith("https://")) {
        fromLocalFile = false;
    } else {
        fromLocalFile = true;
    }

    Json::Value json = Json::Object();
    
    json["content"] = Json::Object();
    json["content"]["ID"] = ID;
    json["content"]["FileName"] = _IO::File::GetFileNameWithoutExtension(filePath);
    json["content"]["FromLocalFile"] = fromLocalFile;
    json["content"]["FilePath"] = filePath;

    string destinationPath = Server::savedFilesDirectory + _IO::File::GetFileName(filePath);
    _IO::SafeMoveFileToNonSource(filePath, destinationPath);

    string jsonPath = Server::savedJsonDirectory + _IO::File::GetFileNameWithoutExtension(filePath) + ".json";
    _IO::File::WriteJsonToFile(jsonPath, json);

    NotifyInfo("Ghost saved successfully.");
}