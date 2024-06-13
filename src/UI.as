void RenderInterface() {
    if (UI::Begin("Load Ghost Plugin")) {
        if (UI::Button("Load Ghost from File")) {
            // _UI::FileExplorer::OpenFileExplorerWindow();
            GhostLoader::LoadGhostFromDialog();
        }
        UI::End();
    }
}