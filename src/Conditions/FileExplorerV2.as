namespace FileExplorer {

    bool showInterface = false;
    FileExplorer@ explorer;

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

    class Navigation {
        string CurrentPath;

        void SetPath(const string &in path) {
            CurrentPath = path;
        }

        string GetPath() {
            return CurrentPath;
        }
    }

    class FileTab {
        Navigation Navigation;
        array<FileInfo@> Files;
        Config@ Config;
        FileExplorer@ explorer;

        FileTab(Config@ cfg, FileExplorer@ fe) {
            @Config = cfg;
            @explorer = fe;
            LoadDirectory(Config.Path);
        }

        void LoadDirectory(const string &in path) {
            Navigation.SetPath(path);
            Files = LoadFiles(path);

            print(Files.Length);

            if (Config.SearchQuery != "") {
                // Apply search query filtering logic later at some point
            }
            if (Config.Filters.Length > 0) {
                // Apply filters logic later at some point
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
            array<string> fileNames = explorer.GetFiles(path);
            for (uint i = 0; i < fileNames.Length; i++) {
                FileInfo@ fileInfo = explorer.GetFileInfo(fileNames[i]);
                if (fileInfo !is null) {
                    fileList.InsertLast(fileInfo);
                }
            }
            return fileList;
        }
    }

    class FileExplorer {
        array<FileTab@> Tabs;
        uint CurrentTabIndex;
        Config@ Config;
        array<string> PinnedItems;

        bool IsIndexing = false;
        string IndexingMessage = "";
        array<FileInfo@> CurrentFiles;
        string CurrentIndexingPath;

        FileExplorer(Config@ cfg) {
            @Config = cfg;
            Tabs.InsertLast(FileTab(@Config, this));
            CurrentTabIndex = 0;
        }

        void OpenTab() {
            Tabs.InsertLast(FileTab(@Config, this));
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
        ) {
            Config.MustReturnFilePath = mustReturnFilePath;
            Config.Path = path;
            Config.SearchQuery = searchQuery;
            Config.Filters = filters;
            Config.RenderFlag = true;

            GetCurrentTab().LoadDirectory(Config.Path);

            showInterface = true;
        }

        void StartIndexingFiles(const string &in path) {
            IsIndexing = true;
            IndexingMessage = "Folder is being indexed...";
            CurrentIndexingPath = path;
            startnew(CoroutineFuncUserdata(StartIndexingFilesCoroutine), this);
        }

        void StartIndexingFilesCoroutine(ref@ r) {
            FileExplorer@ fe = cast<FileExplorer@>(r);
            if (fe is null) return;

            fe.CurrentFiles.Resize(0);
            fe.IndexingMessage = "Folder is being indexed...";

            array<string> fileNames = fe.GetFiles(fe.CurrentIndexingPath);
            const uint batchSize = 20000;
            uint totalFiles = fileNames.Length;
            uint processedFiles = 0;

            for (uint i = 0; i < totalFiles; i += batchSize) {
                uint end = Math::Min(i + batchSize, totalFiles);
                for (uint j = i; j < end; j++) {
                    FileInfo@ fileInfo = fe.GetFileInfo(fileNames[j]);
                    if (fileInfo !is null) {
                        fe.CurrentFiles.InsertLast(fileInfo);
                    }
                }

                processedFiles = end;
                fe.IndexingMessage = "Indexing file " + processedFiles + " out of " + totalFiles;

                yield();
            }

            fe.IsIndexing = false;
        }

        array<string> GetFiles(const string &in path) {
            return IO::IndexFolder(path, false);
        }

        FileInfo@ GetFileInfo(const string &in path) {
            if (_IO::File::IsFile(path)) {
                string name = _IO::File::GetFileName(path);
                uint64 size = IO::FileSize(path);
                string type = _IO::File::GetFileExtension(path);
                int64 lastModified = IO::FileModifiedTime(path);
                return FileInfo(name, path, size, type, lastModified);
            } else {
                string name = _IO::File::GetFileName(path);
                string type = "folder";
                int64 lastModified = IO::FileModifiedTime(path);
                return FileInfo(name, path, 0, type, lastModified);
            }
        }
    }

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
            // UI::Text("Content of Tab " + _IO::Folder::GetFolderName(tab.Navigation.GetPath()));
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
            for (uint i = 0; i < explorer.PinnedItems.Length; i++) {
                UI::Selectable(explorer.PinnedItems[i], false, UI::SelectableFlags::SpanAllColumns);
            }
        }

        void Render_MainAreaBar() {
            if (explorer.IsIndexing) {
                UI::Text(explorer.IndexingMessage);
            } else {
                UI::BeginTable("FilesTable", 4, UI::TableFlags::Resizable | UI::TableFlags::Borders);
                UI::TableSetupColumn("Name");
                UI::TableSetupColumn("Type");
                UI::TableSetupColumn("Size");
                UI::TableSetupColumn("Last Modified");
                UI::TableHeadersRow();

                for (uint i = 0; i < explorer.CurrentFiles.Length; i++) {
                    FileInfo@ file = explorer.CurrentFiles[i];
                    UI::TableNextRow();
                    UI::TableSetColumnIndex(0);
                    UI::Text(file.Name);
                    UI::TableSetColumnIndex(1);
                    UI::Text(file.Type == "folder" ? "Folder" : "File");
                    UI::TableSetColumnIndex(2);
                    UI::Text("" + file.Size);
                    UI::TableSetColumnIndex(3);
                    UI::Text("" + file.LastModifiedDate);
                }

                UI::EndTable();
            }
        }

        void Render_DetailBar() {
            if (explorer.GetCurrentTab().Files.Length > 0) {
                FileInfo@ file = explorer.GetCurrentTab().Files[0];
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

void FILE_EXPLORER_BASE_RENDERER() {
    FileExplorer::RenderFileExplorer();
}

void OpenFileExplorerExample() {
    FileExplorer::OpenFileExplorer(
        true, // mustReturnFilePath
        IO::FromUserGameFolder("Replays/"), // path
        "", // searchQuery
        { "txt", "docx" } // filters
    );
    FileExplorer::explorer.StartIndexingFiles(Server::serverDirectory);
}

void Render() {
    FILE_EXPLORER_BASE_RENDERER();
    
    if (UI::Begin(Icons::UserPlus + " File Explorer", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
        if (UI::Button("Open File Explorer")) {
            OpenFileExplorerExample();
        }
    
    }    
    UI::End();
}