void SaveRecordPath() {
    string filePath = _IO::FileExplorer::Exports::GetExportPath();
    if (filePath.Length == 0) {
        NotifyError("Invalid file path.");
        return;
    }

    log("Saving ghost to URL: " + filePath, LogLevel::Info, 28, "SaveGhost");

    auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
    string ID = gm.IdName;

    bool fromLocalFile;

    if (filePath.StartsWith("http://") || filePath.StartsWith("https://")) {
        fromLocalFile = false;
    } else {
        fromLocalFile = true;
    }

    Json::Value json;
    json["content"] = Json::Object();
    json["content"]["ID"] = ID;
    json["content"]["FromLocalFile"] = fromLocalFile;
    json["content"]["FilePath"] = filePath;

    string destinationPath = Server::savedFilesDirectory + _IO::File::GetFileName(filePath);
    _IO::SafeMoveFileToNonSource(filePath, destinationPath);

    string jsonPath = Server::savedJsonDirectory + _IO::File::GetFileNameWithoutExtension(filePath) + ".json";
    _IO::File::WriteJsonToFile(jsonPath, json);

    NotifyInfo("Ghost saved successfully.");
}