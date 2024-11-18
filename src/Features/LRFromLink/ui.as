namespace Feature {
namespace LRFromDirectLink {
    string link;

    void RenderTab_Link() {

        UI::Separator();

        link = UI::InputText("Link", link);

        if (UI::Button("Load Record")) {
            ProcessSelectedFile(link);
        }
    }
}
}