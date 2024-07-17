namespace FileExplorer {

    bool showInterface = false;
    FileExplorer@ explorer;

    // Store settings
    class Config {
        bool MustReturnFilePath;
        string Path;
        string SearchQuery;
        array<string> Filters;
        bool RenderFlag;
        array<string> SelectedPaths;

        Config() {
            MustReturnFilePath = false;
            Path = "";
            SearchQuery = "";
            RenderFlag = false;
        }
    }

    // Store file details
    class FileInfo {
        string Name;
        string Path;
        uint64 Size;
        string Type;
        int64 LastModifiedDate;
        int64 CreationDate;  // Placeholder for now, use LastModifiedDate

        FileInfo(const string &in name, const string &in path, uint64 size, const string &in type, int64 lastModifiedDate) {
            this.Name = name;
            this.Path = path;
            this.Size = size;
            this.Type = type;
            this.LastModifiedDate = lastModifiedDate;
            this.CreationDate = lastModifiedDate;  // Placeholder, to be replaced
        }
    }

    // Path management
    class Navigation {
        string CurrentPath;

        void SetPath(const string &in path) {
            CurrentPath = path;
        }

        string GetPath() {
            return CurrentPath;
        }
    }

    // Manage a single tab in the file explorer
    class FileTab {
        Navigation Navigation;
        array<FileInfo@> Files;
        Config@ Config;

        FileTab(Config@ cfg) {
            @Config = cfg;
            LoadDirectory(Config.Path);
        }

        void LoadDirectory(const string &in path) {
            Navigation.SetPath(path);
            Files = LoadFiles(path);

            if (Config.SearchQuery != "") {
                // Apply search query filtering logic
            }
            if (Config.Filters.Length > 0) {
                // Apply filters logic
            }

            if (Config.MustReturnFilePath && Config.RenderFlag) {
                array<string> paths;
                for (uint i = 0; i < Files.Length; i++) {
                    paths.InsertLast(Files[i].Path);
                }
                Config.SelectedPaths = paths;
            }
        }

        array<FileInfo@> LoadFiles(const string &in path) {
            array<FileInfo@> fileList;
            // Load file data here (pseudo-code)
            // Example:
            // fileList.InsertLast(FileInfo("example.txt", path + "/example.txt", 1024, "txt", 1625097600000));
            return fileList;
        }
    }

    // Main FileExplorer class
    class FileExplorer {
        array<FileTab@> Tabs;
        uint CurrentTabIndex;
        Config@ Config;
        array<string> PinnedItems;

        FileExplorer(Config@ cfg) {
            @Config = cfg;
            Tabs.InsertLast(FileTab(@Config));
            CurrentTabIndex = 0;
        }

        void OpenTab() {
            Tabs.InsertLast(FileTab(@Config));
            CurrentTabIndex = Tabs.Length - 1;
        }

        void CloseTab(uint index) {
            if (index < Tabs.Length) {
                Tabs.RemoveAt(index);
                CurrentTabIndex = index > 0 ? index - 1 : 0;
            }
        }

        FileTab@ GetCurrentTab() {
            return Tabs[CurrentTabIndex];
        }

        void OpenFileExplorer(
            bool mustReturnFilePath = false,
            const string &in path = "",
            const string &in searchQuery = "",
            array<string> filters = array<string>()
            // Add more parameters as needed or if I come up with something that can be usefull
        ) {
            Config.MustReturnFilePath = mustReturnFilePath;
            Config.Path = path;
            Config.SearchQuery = searchQuery;
            Config.Filters = filters;
            Config.RenderFlag = true;

            GetCurrentTab().LoadDirectory(Config.Path); // Load the initial directory

            showInterface = true;
        }
    }

    // Handle UI rendering
    class UserInterface {
        FileExplorer@ explorer;

        UserInterface(FileExplorer@ fe) {
            @explorer = fe;
        }

        void Render_FileExplorer() {
            Render_Rows();
            Render_Columns();
        }

        void Render_Rows() {
            Render_TabBar();
            Render_NavigationBar();
            Render_ActionBar();
        }

        void Render_Columns() {
            UI::BeginTable("FileExplorerTable", 3, UI::TableFlags::Resizable | UI::TableFlags::Borders);
            UI::TableNextColumn();
            Render_PinBar();
            UI::TableNextColumn();
            Render_MainAreaBar();
            UI::TableNextColumn();
            Render_DetailBar();
            UI::EndTable();
        }

        void Render_TabBar() {
            UI::BeginTabBar("Tabs");
            for (uint i = 0; i < explorer.Tabs.Length; i++) {
                string tabName = _IO::Folder::GetFolderName(explorer.Tabs[i].Navigation.GetPath());
                if (UI::BeginTabItem(tabName)) {
                    RenderTab(i);
                    UI::EndTabItem();
                }
            }
            UI::EndTabBar();
        }

        void RenderTab(uint index) {
            // Custom rendering logic for each tab can be implemented here
            FileTab@ tab = explorer.Tabs[index];
            // Example:
            // UI::Text("Content of " + _IO::Folder::GetFolderName(tab.Navigation.GetPath()));
        }

        void Render_NavigationBar() {
            UI::Separator();
            if (UI::Button(Icons::ArrowLeft)) { /* Handle back navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ArrowRight)) { /* Handle forward navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ArrowUp)) { /* Handle up navigation */ }
            UI::SameLine();
            UI::Text(explorer.GetCurrentTab().Navigation.GetPath());
            UI::SameLine();
            explorer.Config.SearchQuery = UI::InputText("Search", explorer.Config.SearchQuery);
            UI::Separator();
        }

        void Render_ActionBar() {
            UI::Separator();
            if (UI::Button(Icons::Refresh)) { /* Handle refresh */ }
            UI::SameLine();
            if (UI::Button(Icons::FolderOpen)) { /* Handle open folder */ }
            UI::SameLine();
            if (UI::Button(Icons::Trash)) { /* Handle delete */ }
            UI::SameLine();
            if (UI::Button(Icons::Pencil)) { /* Handle rename */ }
            UI::Separator();
        }

        void Render_PinBar() {
            // Simulating a vertical layout using selectable items
            for (uint i = 0; i < explorer.PinnedItems.Length; i++) {
                UI::Selectable(explorer.PinnedItems[i], false, UI::SelectableFlags::SpanAllColumns);
            }
        }

        void Render_MainAreaBar() {
            // Simulating a vertical layout using selectable items
            array<FileInfo@> files = explorer.GetCurrentTab().Files;
            for (uint i = 0; i < files.Length; i++) {
                UI::Selectable(files[i].Name, false, UI::SelectableFlags::SpanAllColumns);
            }
        }

        void Render_DetailBar() {
            if (explorer.GetCurrentTab().Files.Length > 0) {
                FileInfo@ file = explorer.GetCurrentTab().Files[0]; // Change logic to display selected file when that func is added
                if (file !is null) {
                    UI::Text("Name: " + file.Name);
                    UI::Text("Path: " + file.Path);
                    UI::Text("Size: " + file.Size);
                    UI::Text("Type: " + file.Type);
                    UI::Text("Last Modified: " + file.LastModifiedDate);
                }
            } else {
                UI::Text("No file selected.");
            }
        }
    }

    void RenderFileExplorer() {
        if (showInterface && explorer !is null) {
            UserInterface ui(explorer);
            ui.Render_FileExplorer();
        }
    }

    void OpenFileExplorer(
        bool mustReturnFilePath = false,
        const string &in path = "",
        const string &in searchQuery = "",
        array<string> filters = array<string>()
    ) {
        if (explorer is null) {
            Config@ config = Config();
            @explorer = FileExplorer(config);
        }
        explorer.OpenFileExplorer(mustReturnFilePath, path, searchQuery, filters);
    }
}

// Function to be called in the main render loop of the plugin
void FILE_EXPLORER_BASE_RENDERER() {
    FileExplorer::RenderFileExplorer();
}

// Example usage to open the file explorer
void OpenFileExplorerExample() {
    FileExplorer::OpenFileExplorer(
        true, // mustReturnFilePath
        Server::serverDirectory, // path
        "", // searchQuery
        { "txt", "docx" } // filters
    );
}

void Render() {
    // FILE_EXPLORER_BASE_RENDERER();
    
    if (UI::Begin(Icons::UserPlus + " File Explorer", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
        if (UI::Button("Open File Explorer")) {
            OpenFileExplorerExample();
        }
    
    }    
    UI::End();
}