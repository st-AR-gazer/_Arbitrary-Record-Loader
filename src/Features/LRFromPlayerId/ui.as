// src/Features/LoadRecordFromUrl/ui.as

namespace Features {
namespace LRFromDirectLink {
    string pid;

    void RenderTab_Link() {
        UI::Separator();

        pid = UI::InputText("Player Id", pid);

        if (UI::Button("Load Record")) {
            loadRecord.LoadRecordFromPlayerId(pid);
        }
    }
}
}