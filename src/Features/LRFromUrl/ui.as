// src/Features/LoadRecordFromUrl/ui.as

namespace Features {
namespace LRFromUrl {
    string url;

    void RT_LRFromUrl() {
        UI::Separator();

        url = UI::InputText("Url", url);

        if (UI::Button("Load Record")) {
            loadRecord.LoadRecordFromUrl(url);
        }
    }
}
}