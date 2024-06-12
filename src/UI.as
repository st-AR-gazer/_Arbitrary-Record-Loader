namespace UI {
    void Render() {
        if (UI::Begin("Load Ghost Plugin")) {
            if (UI::Button("Load Ghost from File")) {
                GhostLoader::LoadGhostFromDialog();
            }
            UI::End();
        }
    }
}