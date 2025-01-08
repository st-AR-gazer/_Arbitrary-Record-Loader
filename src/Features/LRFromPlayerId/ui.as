// src/Features/LoadRecordFromUrl/ui.as

namespace Features {
namespace LRFromPlayerId {
    string pid;

    void RT_LRFromPlayerID() {
        UI::Separator();

        pid = UI::InputText("Player Id", pid);

        if (UI::Button("Load Record")) {
            loadRecord.LoadRecordFromPlayerId(pid);
        }
    }
}
}