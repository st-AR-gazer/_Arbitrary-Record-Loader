namespace Features {
namespace LRFromDirectLink {
    string url;

    void RenderTab_Link() {
        UI::Separator();

        url = UI::InputText("Url", url);

        if (UI::Button("Load Record")) {
            loadRecord.LoadRecordFromUrl(url);
        }
    }
}
}