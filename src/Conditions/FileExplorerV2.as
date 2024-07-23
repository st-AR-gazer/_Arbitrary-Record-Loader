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

    class ElementInfo {
        string Name;
        string Path;
        uint64 Size;
        string Type;
        int64 LastModifiedDate;
        int64 CreationDate;  // Placeholder for now, use LastModifiedDate
        bool IsFolder;

        ElementInfo(const string &in name, const string &in path, uint64 size, const string &in type, int64 lastModifiedDate, bool isFolder) {
            this.Name = name;
            this.Path = path;
            this.Size = size;
            this.Type = type;
            this.LastModifiedDate = lastModifiedDate;
            this.CreationDate = lastModifiedDate;  // Placeholder, to be replaced
            this.IsFolder = isFolder;
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
        array<ElementInfo@> Elements;
        Config@ Config;
        FileExplorer@ explorer;

        FileTab(Config@ cfg, FileExplorer@ fe) {
            @Config = cfg;
            @explorer = fe;
            LoadDirectory(Config.Path);
        }

        void LoadDirectory(const string &in path) {
            Navigation.SetPath(path);
            Elements = LoadElements(path);

            if (Config.SearchQuery != "") {
                // Apply search query filtering logic later at some point
            }
            if (Config.Filters.Length > 0) {
                // Apply filters logic later at some point
            }

            if (Config.MustReturnFilePath && Config.RenderFlag) {
                array<string> paths;
                for (uint i = 0; i < Elements.Length; i++) {
                    paths.InsertLast(Elements[i].Path);
                }
                Config.SelectedPaths = paths;
            }
        }

        array<ElementInfo@> LoadElements(const string &in path) {
            array<ElementInfo@> elementList;
            array<string> elementNames = explorer.GetFiles(path);
            for (uint i = 0; i < elementNames.Length; i++) {
                ElementInfo@ elementInfo = explorer.GetElementInfo(elementNames[i]);
                if (elementInfo !is null) {
                    elementList.InsertLast(elementInfo);
                }
            }
            return elementList;
        }
    }

    class FileExplorer {
        FileTab@ tab;
        Config@ Config;
        array<string> PinnedItems;

        bool IsIndexing = false;
        string IndexingMessage = "";
        array<ElementInfo@> CurrentElements;
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

            fe.CurrentElements.Resize(0);
            fe.IndexingMessage = "Folder is being indexed...";

            array<string> elements = fe.GetFiles(fe.CurrentIndexingPath);

            const uint batchSize = 20000;
            uint totalFiles = elements.Length;
            uint processedFiles = 0;

            for (uint i = 0; i < totalFiles; i += batchSize) {
                uint end = Math::Min(i + batchSize, totalFiles);
                for (uint j = i; j < end; j++) {
                    string path = elements[j];
                    if (path.Contains("\\/")) {
                        path = path.Replace("\\/", "/");
                    }
                    
                    ElementInfo@ elementInfo = fe.GetElementInfo(path);
                    if (elementInfo !is null) {
                        fe.CurrentElements.InsertLast(elementInfo);
                    }
                }

                processedFiles = end;
                fe.IndexingMessage = "Indexing element " + processedFiles + " out of " + totalFiles;

                print(fe.IndexingMessage);

                yield();
            }

            fe.IsIndexing = false;
        }

        array<string> GetFiles(const string &in path) {
            return IO::IndexFolder(path, false);
        }

        ElementInfo@ GetElementInfo(const string &in path) {
            bool isFolder = _IO::Folder::IsDirectory(path);
            
            string name;
            if (isFolder) { name = _IO::Folder::GetFolderName(path); } 
            else          { name = _IO::File::GetFileName(path); }

            string type = isFolder ? "folder" : _IO::File::GetFileExtension(path);
            uint64 size = isFolder ? 0 : IO::FileSize(path);
            int64 lastModified = IO::FileModifiedTime(path);

            return ElementInfo(name, path, size, type, lastModified, isFolder);
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
                UI::TableSetupColumn("Created Date");
                UI::TableHeadersRow();

                for (uint i = 0; i < explorer.CurrentElements.Length; i++) {
                    ElementInfo@ element = explorer.CurrentElements[i];
                    UI::TableNextRow();
                    UI::TableSetColumnIndex(0);
                    UI::Text(element.Name);
                    UI::TableSetColumnIndex(1);
                    UI::Text(element.IsFolder ? "Folder" : "File");
                    UI::TableSetColumnIndex(2);
                    UI::Text(element.IsFolder ? "-" : "" + element.Size);
                    UI::TableSetColumnIndex(3);
                    UI::Text("" + Time::FormatString("%Y-%m-%d %H:%M:%S", element.LastModifiedDate));
                    UI::TableSetColumnIndex(4);
                    UI::Text(Time::FormatString("%Y-%m-%d %H:%M:%S", element.CreationDate));
                }

                UI::EndTable();
            }
        }

        void Render_DetailBar() {
            if (explorer.tab.Elements.Length > 0) {
                ElementInfo@ element = explorer.tab.Elements[0];
                if (element !is null) {
                    UI::Text("Name: " + element.Name);
                    UI::Text("Path: " + element.Path);
                    UI::Text("Size: " + element.Size);
                    UI::Text("Type: " + element.Type);
                    UI::Text("Last Modified: " + element.LastModifiedDate);
                }
            } else {
                UI::Text("No element selected.");
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
    // FileExplorer::explorer.StartIndexingFiles(IO::FromUserGameFolder("Replays/"));
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
