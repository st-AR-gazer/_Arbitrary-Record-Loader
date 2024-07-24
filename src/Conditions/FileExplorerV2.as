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

    enum Icon {
        Folder,
        FolderOpen,
        File,
        FileText,
        FilePdf,
        FileWord,
        FileExcel,
        FilePowerpoint,
        FileImage,
        FileArchive,
        FileAudio,
        FileVideo,
        FileCode,
        FileEpub
    }

    class ElementInfo {
        string Name;
        string Path;
        string Size;
        string Type;
        int64 LastModifiedDate;
        int64 CreationDate;  // Placeholder for now, use LastModifiedDate
        bool IsFolder;
        Icon Icon;
        bool IsSelected;
        uint64 LastSelectedTime;

        ElementInfo(const string &in name, const string &in path, string size, const string &in type, int64 lastModifiedDate, int64 creationDate, bool isFolder, Icon icon, bool isSelected = false) {
            this.Name = name;
            this.Path = path;
            this.Size = size;
            this.Type = type;
            this.LastModifiedDate = lastModifiedDate;
            this.CreationDate = lastModifiedDate;  // Placeholder, to be replaced
            this.IsFolder = isFolder;
            this.Icon = icon;
            this.IsSelected = isSelected;
            this.LastSelectedTime = 0;
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
        uint SelectedElementIndex;

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

            explorer.StartIndexingFiles(path);
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

        ElementInfo@ GetSelectedElement() {
            for (uint i = 0; i < Elements.Length; i++) {
                if (Elements[i].IsSelected) {
                    print(Elements[i].IsSelected + " " + Elements[i].Path);
                    return Elements[i];
                }
                print(Elements[i].IsSelected + " " + Elements[i].Path);
            }
            return null;
        }
    }

    class Utils {
        FileExplorer@ explorer;

        Utils(FileExplorer@ fe) {
            @explorer = fe;
        }

        void MoveUpOneDirectory() {
            string path = explorer.tab.Navigation.GetPath();

            print("Original Path: " + path);
            if (path.EndsWith("/") || path.EndsWith("\\")) {
                path = path.SubStr(0, path.Length - 1);
            }

            int lastSlash = Math::Max(_Text::LastIndexOf("/", path), _Text::LastIndexOf(path, "\\"));
            if (lastSlash > 0) {
                path = path.SubStr(0, lastSlash);
            } else {
                path = "/";
            }
            path += "/";

            explorer.tab.LoadDirectory(path);
        }

        void MoveIntoSelectedDirectory() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null) {
            }
            if (selectedElement !is null && selectedElement.IsFolder) {
                log("Moving into directory: " + selectedElement.Path);
                explorer.tab.LoadDirectory(selectedElement.Path);
            }
        }
    }


    class FileExplorer {
        FileTab@ tab;
        Config@ Config;
        array<string> PinnedItems;
        UserInterface@ ui;
        Utils@ utils;

        bool IsIndexing = false;
        string IndexingMessage = "";
        array<ElementInfo@> CurrentElements;
        string CurrentIndexingPath;

        FileExplorer(Config@ cfg) {
            @Config = cfg;
            @tab = FileTab(@Config, this);
            @ui = UserInterface(this);
            @utils = Utils(this);
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

            const uint batchSize = 2000;
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

                log(fe.IndexingMessage);

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
            string size = isFolder ? "-" : ConvertFileSizeToString(IO::FileSize(path));
            int64 lastModified = IO::FileModifiedTime(path);
            int64 creationDate = lastModified;  // Placeholder, to be replaced
            Icon icon = GetElementIcon(isFolder, type);
            bool isSelected = false;

            return ElementInfo(name, path, size, type, lastModified, creationDate, isFolder, icon, isSelected);
        }

        string ConvertFileSizeToString(uint64 size) {
            if (size < 1024) {
                return size + " B";
            } else if (size < 1024 * 1024) {
                return (size / 1024) + " KB";
            } else if (size < 1024 * 1024 * 1024) {
                return (size / (1024 * 1024)) + " MB";
            } else {
                return (size / (1024 * 1024 * 1024)) + " GB";
            }
        }

        Icon GetElementIcon(bool isFolder, const string &in type) {
            if (isFolder) { 
                return Icon::Folder; 
            }

            string ext = type.ToLower();
            if (ext == "txt" || ext == "rtf" || ext == "csv" || ext == "json") return Icon::FileText;
            if (ext == "pdf") return Icon::FilePdf;
            if (ext == "doc" || ext == "docx") return Icon::FileWord;
            if (ext == "xls" || ext == "xlsx") return Icon::FileExcel;
            if (ext == "ppt" || ext == "pptx") return Icon::FilePowerpoint;
            if (ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "gif") return Icon::FileImage;
            if (ext == "rar" || ext == "zip" || ext == "7z") return Icon::FileArchive;
            if (ext == "ogg" || ext == "mp3" || ext == "wav") return Icon::FileAudio;
            if (ext == "mp4" || ext == "mov") return Icon::FileVideo;
            if (ext == "cs" || ext == "cpp" || ext == "js" || ext == "java" || ext == "py") return Icon::FileCode;
            if (ext == "epub") return Icon::FileEpub;
            return Icon::File;
        }

        string GetElementIconString(Icon icon, bool isSelected) {
            switch(icon) {
                case Icon::Folder: return isSelected ? "\\$FD4"+Icons::FolderOpenO+"\\$g" : "\\$FD4"+Icons::FolderO+"\\$g";
                case Icon::FileText: return Icons::FileTextO;
                case Icon::FilePdf: return Icons::FilePdfO;
                case Icon::FileWord: return Icons::FileWordO;
                case Icon::FileExcel: return Icons::FileExcelO;
                case Icon::FilePowerpoint: return Icons::FilePowerpointO;
                case Icon::FileImage: return Icons::FileImageO;
                case Icon::FileArchive: return Icons::FileArchiveO;
                case Icon::FileAudio: return Icons::FileAudioO;
                case Icon::FileVideo: return Icons::FileVideoO;
                case Icon::FileCode: return Icons::FileCodeO;
                case Icon::FileEpub: return Icons::FileEpub;
                default: return Icons::FileO;
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
            if (UI::Button(Icons::ArrowLeft)) { /* Handle back navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ArrowRight)) { /* Handle forward navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ArrowUp)) { explorer.utils.MoveUpOneDirectory(); }
            UI::SameLine();
            if (UI::Button(Icons::ArrowDown)) { explorer.utils.MoveIntoSelectedDirectory(); }
            UI::SameLine();
            UI::Text(explorer.tab.Navigation.GetPath());
            UI::SameLine();
            explorer.Config.SearchQuery = UI::InputText("Search", explorer.Config.SearchQuery);
            UI::Separator();
        }

        void Render_ActionBar() {
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
                UI::BeginTable("FilesTable", 6, UI::TableFlags::Resizable | UI::TableFlags::Borders | UI::TableFlags::SizingFixedSame);
                UI::TableSetupColumn("ico");
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
                    UI::Text(explorer.GetElementIconString(element.Icon, element.IsSelected));
                    UI::TableSetColumnIndex(1);
                    if (UI::Selectable(element.Name, element.IsSelected)) {
                        HandleElementSelection(element);
                    }
                    UI::TableSetColumnIndex(2);
                    UI::Text(element.IsFolder ? "Folder" : "File");
                    UI::TableSetColumnIndex(3);
                    UI::Text(element.IsFolder ? "-" : "" + element.Size);
                    UI::TableSetColumnIndex(4);
                    UI::Text("" + Time::FormatString("%Y-%m-%d %H:%M:%S", element.LastModifiedDate));
                    UI::TableSetColumnIndex(5);
                    UI::Text(Time::FormatString("%Y-%m-%d %H:%M:%S", element.CreationDate));
                }

                UI::EndTable();
            }
        }

        void HandleElementSelection(ElementInfo@ element) {
            if (!element.IsSelected) {
                log("Selecting element: " + element.Name);
                DeselectAll();
                element.IsSelected = true;
                element.LastSelectedTime = Time::Now;
            }
        }

        void DeselectAll() {
            for (uint i = 0; i < explorer.CurrentElements.Length; i++) {
                explorer.CurrentElements[i].IsSelected = false;
            }
        }

        void Render_DetailBar() {
            ElementInfo@ selectedElement = GetSelectedElement();
            if (selectedElement !is null) {
                UI::Text("ICO: " + explorer.GetElementIconString(selectedElement.Icon, selectedElement.IsSelected));
                UI::Text("Name: " + selectedElement.Name);
                UI::Text("Path: " + selectedElement.Path);
                UI::Text("Size: " + selectedElement.Size);
                UI::Text("Type: " + selectedElement.Type);
                UI::Text("Last Modified: " + Time::FormatString("%Y-%m-%d %H:%M:%S", selectedElement.LastModifiedDate));
                UI::Text("Selected Time: " + selectedElement.LastSelectedTime);
            } else {
                UI::Text("No element selected.");
            }
        }

        ElementInfo@ GetSelectedElement() {
            for (uint i = 0; i < explorer.CurrentElements.Length; i++) {
                if (explorer.CurrentElements[i].IsSelected) {
                    return explorer.CurrentElements[i];
                }
            }
            return null;
        }
    }

    void RenderFileExplorer() {
        if (showInterface && explorer !is null) {
            UserInterface ui(explorer);
            explorer.ui.Render_FileExplorer();
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
