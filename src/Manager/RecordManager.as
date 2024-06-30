namespace RecordManager {
    void OpenGhostFileDialogWindow() {
        _IO::FileExplorer::OpenFileExplorer(true, IO::FromUserGameFolder("Replays/"), "", { "replay", "ghost" });
    }

    void RemoveAllRecords() {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_RemoveAll();
        log("All ghosts removed.", LogLevel::Info, 9, "RemoveAllRecords");
    }

    void RemoveInstanceRecord(MwId instanceId) {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_Remove(instanceId);
        log("Record with the MwID of: " + instanceId.GetName() + " .", LogLevel::Info, 15, "RemoveInstanceRecord");
    }
}

void ProcessSelectedFile(const string &in filePath) {
    if (filePath.StartsWith("https://") || filePath.StartsWith("http://")) {
        _Net::DownloadFileToDestination(filePath, Server::specificDownloadedFilesDirectory + _IO::File::GetFileName(filePath));
        return;
    }

    string fileExt = _IO::File::GetFileExtension(filePath).ToLower();

    if (fileExt == "gbx") {
        string properFileExtension = _IO::File::GetFileExtension(filePath).ToLower();
        if (properFileExtension == "gbx") {
            int secondLastDotIndex = _Text::NthLastIndexOf(filePath, ".", 2);
            int lastDotIndex = _Text::LastIndexOf(filePath, ".");
            if (secondLastDotIndex != -1 && lastDotIndex > secondLastDotIndex) {
                properFileExtension = filePath.SubStr(secondLastDotIndex + 1, lastDotIndex - secondLastDotIndex - 1);
            }
        }
        fileExt = properFileExtension.ToLower();
    }

    if (fileExt == "replay") {
        ReplayLoader::LoadReplayFromPath(filePath);
    } else if (fileExt == "ghost") {
        GhostLoader::LoadGhost(filePath);
    } else {
        log("Unsupported file type: " + fileExt + " " + "Full path: " + filePath, LogLevel::Error, 392, "ProcessSelectedFile");
        NotifyWarn("Error | Unsupported file type.");
    }
}