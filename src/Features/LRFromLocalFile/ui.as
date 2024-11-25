// src/Features/LoadRecordFromFile/ui.as

namespace Features {
namespace LRFromFile {
    array<string> selectedFiles;

    void RT_LRFromLocalFiles() {

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
                selectedFiles = paths;
                explorer.exports.SetSelectionComplete();
            }
        }

        UI::SameLine();
        UI::Text("Selected Files: " + selectedFiles.Length);
        for (uint i = 0; i < selectedFiles.Length; i++) {
            UI::PushItemWidth(1100);
            selectedFiles[i] = UI::InputText("File Path " + (i + 1), selectedFiles[i]);
            UI::PopItemWidth();
        }

        UI::Separator();

        bool hasValidFile = selectedFiles.Length > 0;

        if (hasValidFile) {
            if (UI::Button(Icons::Download + Icons::SnapchatGhost + " Load Ghost or Replay")) {
                for (uint i = 0; i < selectedFiles.Length; i++) {
                    if (selectedFiles[i] != "") {
                        loadRecord.LoadRecordFromLocalFile(selectedFiles[i]);
                    }
                }
            }
        } else {
            _UI::DisabledButton(Icons::Download + Icons::SnapchatGhost + " Load Ghost or Replay");
        }

        if (UI::Button(Icons::Users + Icons::EyeSlash + " Remove All Ghosts")) {
            RecordManager::RemoveAllRecords();
        }
    }
}
}