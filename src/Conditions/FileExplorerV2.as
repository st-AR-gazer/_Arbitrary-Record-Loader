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
        FileTab@ tab;
        Config@ Config;
        array<string> PinnedItems;

        bool IsIndexing = false;
        string IndexingMessage = "";
        array<FileInfo@> CurrentFiles;
        string CurrentIndexingPath;

        FileExplorer(Config@ cfg) {
            @Config = cfg;
            @tab = FileTab(@Config, this);
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

            tab.LoadDirectory(Config.Path);

            showInterface = true;

            explorer.StartIndexingFiles(IO::FromUserGameFolder("Replays/"));
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

            array<string> elements = fe.GetFiles(fe.CurrentIndexingPath);

            print("1");

            const uint batchSize = 20000;
            uint totalFiles = elements.Length;
            uint processedFiles = 0;

            for (uint i = 0; i < totalFiles; i += batchSize) {

            print("2");
                

                uint end = Math::Min(i + batchSize, totalFiles);
                for (uint j = i; j < end; j++) {
                    string path = elements[j];
                    if (path.Contains("\\/")) {
                        path = path.Replace("\\/", "/");
                    }
                    
                    FileInfo@ fileInfo = fe.GetFileInfo(path);
                    if (fileInfo !is null) {
                        fe.CurrentFiles.InsertLast(fileInfo);
                    }
                }
            print("3");

                processedFiles = end;
                fe.IndexingMessage = "Indexing file " + processedFiles + " out of " + totalFiles;

            print("4");

                yield();
            }

            fe.IsIndexing = false;
        }

        array<string> GetFiles(const string &in path) {
            print("yek yek");
            print(path);
            return IO::IndexFolder(path, false);
        }

        FileInfo@ GetFileInfo(const string &in path) {
            bool isFolder = _IO::Folder::IsDirectory(path);
            string name = _IO::File::GetFileName(path);
            string type = isFolder ? "folder" : _IO::File::GetFileExtension(path);
            uint64 size = isFolder ? 0 : IO::FileSize(path);
            int64 lastModified = IO::FileModifiedTime(path);
            int64 creationDate = IO::FileModifiedTime(path)/*IO::FileCreationTime(path)*/;

            return FileInfo(name, path, size, type, lastModified, creationDate);
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

        void Render_NavigationBar() {
            UI::Separator();
            if (UI::Button(Icons::ArrowLeft)) { /* Handle back navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ArrowRight)) { /* Handle forward navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ArrowUp)) { /* Handle up navigation */ }
            UI::SameLine();
            UI::Text(explorer.tab.Navigation.GetPath());
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
                    UI::Text(file.Type == "folder" ? "-" : "" + file.Size);
                    UI::TableSetColumnIndex(3);
                    UI::Text("" + Time::FormatString("%Y-%m-%d %H:%M:%S", file.LastModifiedDate));
                }

                UI::EndTable();
            }
        }

        void Render_DetailBar() {
            if (explorer.tab.Files.Length > 0) {
                FileInfo@ file = explorer.tab.Files[0];
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
        { "" } // filters
    );
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
