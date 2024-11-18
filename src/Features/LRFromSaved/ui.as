namespace Features {
namespace LRFromSaved {
    
    array<string> savedGhostsSelectedFiles;

    void RT_LRFromSaved() {

        UI::Separator();

        if (UI::Button(Icons::FolderOpen + " Open File Explorer")) {
            FileExplorer::fe_Start(
                "Local Files",
                true,
                "path",
                vec2(1, -1),
                IO::FromUserGameFolder("Replays/"),
                "",
                { "replay", "ghost" }
            );
        }

        auto explorer = FileExplorer::fe_GetExplorerById("Local Files");
        if (explorer !is null && explorer.exports.IsSelectionComplete()) {
            auto paths = explorer.exports.GetSelectedPaths();
            if (paths !is null) {
                savedGhostsSelectedFiles = paths;
                explorer.exports.SetSelectionComplete();
            }
        }

        UI::SameLine();
        UI::Text("Selected Files: " + savedGhostsSelectedFiles.Length);
        for (uint i = 0; i < savedGhostsSelectedFiles.Length; i++) {
            UI::PushItemWidth(1100);
            savedGhostsSelectedFiles[i] = UI::InputText("File Path " + (i + 1), savedGhostsSelectedFiles[i]);
            UI::PopItemWidth();
        }

        if (savedGhostsSelectedFiles.Length > 0) {
            if (UI::Button(Icons::Download + Icons::SnapchatGhost + " Save Record to Saved folder")) {
                for (uint i = 0; i < savedGhostsSelectedFiles.Length; i++) {
                    if (savedGhostsSelectedFiles[i] != "") {
                        // Save some data about the ghost/replay instead of the whole file (this should also be saved, but to savedFilesDirectory and referenced in the json file in savedJsonDirectory)
                        _IO::File::CopyFileTo(savedGhostsSelectedFiles[i], Server::savedFilesDirectory + Path::GetFileName(savedGhostsSelectedFiles[i]));
                    }
                }
            }
        } else {
            _UI::DisabledButton(Icons::Download + Icons::SnapchatGhost + " Save Record to Saved folder");
        }

        UI::Separator();

        // array<string>@ files = IO::IndexFolder(Server::savedJsonDirectory, true);
        // UI::Text("Saved Runs:");
        // UI::Separator();

        // for (uint i = 0; i < files.Length; i++) {
        //     string fullFilePath = files[i];
        //     string fileName = Path::GetFileName(fullFilePath);
        //     if (fileName.EndsWith(".json")) {
        //         string jsonContent = _IO::File::ReadFileToEnd(Server::savedJsonDirectory + fileName);
        //         Json::Value json = Json::Parse(jsonContent);


        //         if (json.GetType() == Json::Type::Object && json.HasKey("content")) {
        //             Json::Value content = json["content"];

        //             UI::Text("Nickname: " + string(content["Nickname"]));
        //             UI::Text("FileName: " + string(content["FileName"]));
        //             UI::Text("Trigram: " + string(content["Trigram"]));
        //             UI::Text("Time: " + int(content["Time"]));
        //             UI::Text("ReplayFilePath: " + string(content["ReplayFilePath"]));
        //             UI::Text("FullFilePath: " + string(content["FullFilePath"]));
        //             UI::Text("CountryPath: " + string(content["CountryPath"]));
        //             if (!bool(content["FromLocalFile"])) UI::Text("FromLocalFile: " + bool(content["FromLocalFile"]));
        //             UI::Text("StuntScore: " + int(content["StuntScore"]));
        //             UI::Text("MwId: " + uint(content["MwId Value"]));

        //             if (UI::Button("Load " + fileName)) {
        //                 if (bool(content["FromLocalFile"])) {
        //                     ProcessSelectedFile(string(content["FullFilePath"]));
        //                 } else {
        //                     NotifyWarn("You can only load local files...");
        //                 }
        //             }
        //             UI::SameLine();
        //             if (UI::Button("Delete " + fileName)) {
        //                 IO::Delete(Server::savedJsonDirectory + fileName);
        //                 IO::Delete(Server::savedFilesDirectory + string(content["FileName"]) + ".Replay.Gbx");
        //             }
        //             UI::Separator();
        //         } else {
        //             UI::Text("Error reading " + fileName);
        //         }
        //     }
        // }
    }
}
}