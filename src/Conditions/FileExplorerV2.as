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
        bool HideFiles = false;
        bool HideFolders = false;
        bool EnablePagination = false;
        dictionary columsToShow; 

        Config() {
            MustReturnFilePath = false;
            Path = "";
            SearchQuery = "";
            Filters = array<string>();
            RenderFlag = false;
            SelectedPaths = array<string>();

            columsToShow.Set("ico", true);
            columsToShow.Set("name", true);
            columsToShow.Set("type", true);
            columsToShow.Set("size", true);
            columsToShow.Set("lastModified", true);
            columsToShow.Set("createdDate", true);
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

    class Exports {
        string ReturnSelectedFilePath() {
            string path = explorer.CurrentSelectedElement.Path;
            explorer.CurrentSelectedElement.Path = ""; // Will be refreshed on next fe open

            return path;
        }

        array<string> ReturnFilePathForSelectedFiles() {
            array<string> paths = explorer.Config.SelectedPaths;
            explorer.Config.SelectedPaths = array<string>();
            
            return paths;
        }
    }

    class ElementInfo {
        string Name;
        string Path;
        string Size;
        string Type;
        int64 LastModifiedDate;
        int64 CreationDate; // Placeholder, to be replaced
        bool IsFolder;
        Icon Icon;
        bool IsSelected;
        uint64 LastSelectedTime;
        dictionary GbxMetadata;
        bool shouldShow;

        ElementInfo(const string &in name, const string &in path, string size, const string &in type, int64 lastModifiedDate, int64 creationDate, bool isFolder, Icon icon, bool isSelected) {
            this.Name = name;
            this.Path = path;
            this.Size = size;
            this.Type = type;
            this.LastModifiedDate = lastModifiedDate;
            this.CreationDate = lastModifiedDate; // Placeholder, to be replaced
            this.IsFolder = isFolder;
            this.Icon = icon;
            this.IsSelected = isSelected;
            this.LastSelectedTime = 0;
            this.shouldShow = true;
        }

        void SetGbxMetadata(dictionary@ metadata) {
            GbxMetadata = metadata;
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
        uint currentSelectedTab = 0; // Decided to only go with one tab for now, but might add more in the future...

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
                string search = Config.SearchQuery;

                for (uint i = 0; i < Elements.Length; i++) {
                    ElementInfo@ element = Elements[i];
                    if (element.Name.Contains(search)) {
                        element.shouldShow = true;
                    } else {
                        element.shouldShow = false;
                    }
                }
            }
            if (Config.Filters.Length > 0) {
                for (uint i = 0; i < Elements.Length; i++) {
                    ElementInfo@ element = Elements[i];
                    if (element.IsFolder) {
                        element.shouldShow = true;
                    } else {
                        bool found = false;
                        for (uint j = 0; j < Config.Filters.Length; j++) {
                            if (element.Type.ToLower() == Config.Filters[j].ToLower()) {
                                found = true;
                                break;
                            }
                        }
                        element.shouldShow = found;
                    }
                }
            }

            ApplyVisibilitySettings();

            if (Config.MustReturnFilePath && Config.RenderFlag) {
                array<string> paths;
                for (uint i = 0; i < Elements.Length; i++) {
                    paths.InsertLast(Elements[i].Path);
                }
                Config.SelectedPaths = paths;
            }

            explorer.StartIndexingFiles(path);
        }

        void ApplyVisibilitySettings() {
            for (uint i = 0; i < Elements.Length; i++) {
                ElementInfo@ element = Elements[i];
                element.shouldShow = true;
                
                if (Config.HideFiles && !element.IsFolder) {
                    element.shouldShow = false;
                }
                if (Config.HideFolders && element.IsFolder) {
                    element.shouldShow = false;
                }
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
            string path = explorer.tab[0].Navigation.GetPath();

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

            explorer.tab[0].LoadDirectory(path);
        }

        void MoveIntoSelectedDirectory() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null && selectedElement.IsFolder) {
                log("Moving into directory: " + selectedElement.Path, LogLevel::Info, 243, "MoveIntoSelectedDirectory");
                explorer.tab[0].LoadDirectory(selectedElement.Path);
            }
        }

        void RefreshCurrentDirectory() {
            string currentPath = explorer.tab[0].Navigation.GetPath();
            log("Refreshing directory: " + currentPath, LogLevel::Info, 250, "RefreshCurrentDirectory");
            explorer.tab[0].LoadDirectory(currentPath);
        }

        void OpenSelectedFolder() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null && selectedElement.IsFolder) {
                log("Opening folder: " + selectedElement.Path, LogLevel::Info, 257, "OpenSelectedFolder");
                _IO::OpenFolder(selectedElement.Path);
            } else {
                log("No folder selected or selected element is not a folder.", LogLevel::Error, 260, "OpenSelectedFolder");
            }
        }

        bool IsItemSelected() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            return selectedElement !is null;
        }

        void DeleteSelectedElement() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null) {
                if (selectedElement.IsFolder) {
                    log("Deleting folder: " + selectedElement.Path, LogLevel::Info, 273, "DeleteSelectedElement");
                    IO::DeleteFolder(selectedElement.Path);
                } else {
                    log("Deleting file: " + selectedElement.Path, LogLevel::Info, 276, "DeleteSelectedElement");
                    IO::Delete(selectedElement.Path);
                }
                explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
            }
        }

        bool RENDER_RENAME_POPUP_FLAG;
        void RenameSelectedElement(const string &in newFileName) {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null) {
                log("Renaming element: " + selectedElement.Path, LogLevel::Info, 287, "RenameSelectedElement");
                
                string fileName = _IO::File::GetFileName(selectedElement.Path);
                string fileContent = _IO::File::ReadFileToEnd(selectedElement.Path);
                string filePath = selectedElement.Path;

                string newFilePath = _IO::Folder::GetFolderPath(filePath) + newFileName;

                _IO::File::WriteToFile(newFilePath, fileContent);
            }
        }

        void PinSelectedElement() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null) {
                log("Pinning element: " + selectedElement.Path, LogLevel::Info, 302, "PinSelectedElement");
                explorer.PinnedItems.InsertLast(selectedElement.Path);
            }
        }
    }

    class FileExplorer {
        array<FileTab@> tab;
        Config@ Config;
        array<string> PinnedItems;
        UserInterface@ ui;
        Utils@ utils;
        Exports@ exports;

        bool IsIndexing = false;
        string IndexingMessage = "";
        array<ElementInfo@> CurrentElements;
        string CurrentIndexingPath;

        ElementInfo@ CurrentSelectedElement;

        FileExplorer(Config@ cfg) {
            @Config = cfg;
            tab.Resize(1);
            @tab[0] = FileTab(cfg, this);
            @ui = UserInterface(this);
            @utils = Utils(this);
            @exports = Exports();
            @CurrentSelectedElement = null;
        }

        void UpdateCurrentSelectedElement() {
            @CurrentSelectedElement = tab[0].GetSelectedElement();
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

            tab[0].LoadDirectory(Config.Path);

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

            fe.tab[0].Elements.Resize(0);
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
                        fe.tab[0].Elements.InsertLast(elementInfo);
                    }
                }

                processedFiles = end;
                fe.IndexingMessage = "Indexing element " + processedFiles + " out of " + totalFiles;

                log(fe.IndexingMessage, LogLevel::Info, 391, "StartIndexingFilesCoroutine");

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

            ElementInfo@ elementInfo = ElementInfo(name, path, size, type, lastModified, creationDate, isFolder, icon, isSelected);

            if (type.ToLower() == "gbx") {
                dictionary gbxMetadata = ReadGbxHeader(path);
                elementInfo.SetGbxMetadata(gbxMetadata);
            }

            return elementInfo;
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
            Render_ReturnBar();
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
            if (UI::Button(Icons::ArrowLeft)) { /* Handle timeline back navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ArrowRight)) { /* Handle timeline forward navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ArrowUp)) { explorer.utils.MoveUpOneDirectory(); }
            UI::SameLine();
            if (!explorer.tab[0].Elements[explorer.tab[0].SelectedElementIndex].IsFolder) {
                _UI::DisabledButton(Icons::ArrowDown); } else {
                if (UI::Button(Icons::ArrowDown)) { explorer.utils.MoveIntoSelectedDirectory(); }
                UI::SameLine();
            }
            UI::Text(explorer.tab[0].Navigation.GetPath());
            UI::SameLine();
            explorer.Config.SearchQuery = UI::InputText("Search", explorer.Config.SearchQuery);
            UI::Separator();
        }

        string newFilter = "";
        void Render_ActionBar() {
            if (UI::Button(Icons::ChevronLeft)) { /* Handle back navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::ChevronRight)) { /* Handle forward navigation */ }
            UI::SameLine();
            if (UI::Button(Icons::Refresh)) { explorer.utils.RefreshCurrentDirectory(); }
            UI::SameLine();
            if (UI::Button(Icons::FolderOpen)) { explorer.utils.OpenSelectedFolder(); }
            UI::SameLine();
            if (!explorer.utils.IsItemSelected()) {
               _UI::DisabledButton(Icons::Trash); 
                UI::SameLine();
               _UI::DisabledButton(Icons::Pencil);
                UI::SameLine();
               _UI::DisabledButton(Icons::ThumbTack);
            } else {
                if (UI::Button(Icons::Trash)) {  explorer.utils.DeleteSelectedElement(); }
                UI::SameLine();
                if (UI::Button(Icons::Pencil)) { explorer.utils.RENDER_RENAME_POPUP_FLAG = !explorer.utils.RENDER_RENAME_POPUP_FLAG; }
                UI::SameLine();
                if (UI::Button(Icons::ThumbTack)) { explorer.utils.PinSelectedElement(); }
            }
            UI::SameLine();
            if (UI::Button(Icons::Filter)) { UI::OpenPopup("filterMenu"); }


            // Filter TODO:
            // - Automatically add all filter types on new folder index (should be togglable setting)
            // - Add remove button for filters
            
            if (UI::BeginPopup("filterMenu")) {
                UI::MenuItem("All filters");
                UI::Separator();
                UI::MenuItem("Add filter");
                newFilter = UI::InputText("New Filter", newFilter);
                if (UI::Button("Add")) {
                    explorer.Config.Filters.InsertLast(newFilter);
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    UI::CloseCurrentPopup();
                }
                UI::Separator();
                UI::MenuItem("Filter length: " + explorer.Config.Filters.Length);
                for (uint i = 0; i < explorer.Config.Filters.Length; i++) {
                    UI::MenuItem(explorer.Config.Filters[i]);
                }

                UI::EndPopup();
            }


            UI::SameLine();
            UI::Dummy(vec2(UI::GetContentRegionAvail().x - 45, 0));
            UI::SameLine();
            if (UI::Button(Icons::Bars)) { UI::OpenPopup("burgerMenu"); }

            if (UI::BeginPopup("burgerMenu")) {
                if (UI::MenuItem("Hide Files", "", explorer.Config.HideFiles)) {
                    explorer.Config.HideFiles = !explorer.Config.HideFiles;
                    explorer.tab[0].ApplyVisibilitySettings();
                }
                if (UI::MenuItem("Hide Folders", "", explorer.Config.HideFolders)) {
                    explorer.Config.HideFolders = !explorer.Config.HideFolders;
                    explorer.tab[0].ApplyVisibilitySettings();
                }
                if (UI::MenuItem("Enable Pagination", "", explorer.Config.EnablePagination)) {
                    explorer.Config.EnablePagination = !explorer.Config.EnablePagination;
                    explorer.utils.RefreshCurrentDirectory();
                }
                UI::EndPopup();
            }
            UI::Separator();
        }

        void Render_RenamePopup() {
            if (explorer.utils.RENDER_RENAME_POPUP_FLAG) {
                UI::OpenPopup("RenamePopup");
            }

            if (UI::BeginPopupModal("RenamePopup", explorer.utils.RENDER_RENAME_POPUP_FLAG, UI::WindowFlags::AlwaysAutoResize)) {
                UI::Text("Rename Selected Element");
                UI::Separator();
                UI::InputText("New File Name", "NewFileName");
                if (UI::Button("Rename")) {
                    explorer.utils.RenameSelectedElement("NewFileName");
                    explorer.utils.RENDER_RENAME_POPUP_FLAG = false;
                    UI::CloseCurrentPopup();
                }
                UI::EndPopup();
            }
        }


        void Render_ReturnBar() {
            if (explorer.Config.MustReturnFilePath) {
                UI::Separator();
                if (UI::Button("Return Selected Path")) {
                    explorer.exports.ReturnSelectedFilePath();

                    explorer.Config.MustReturnFilePath = false;
                    showInterface = false;
                }
            }
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

                for (uint i = 0; i < explorer.tab[0].Elements.Length; i++) {
                    ElementInfo@ element = explorer.tab[0].Elements[i];
                    if (!element.shouldShow) continue;
                    // print("Element: " + element.Name + " " + element.shouldShow + " " + element.Type);

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
                log("Selecting element: " + element.Name, LogLevel::Info, 673, "HandleElementSelection");
                DeselectAll();
                element.IsSelected = true;
                element.LastSelectedTime = Time::Now;
                explorer.UpdateCurrentSelectedElement();
            }
        }

        void DeselectAll() {
            for (uint i = 0; i < explorer.tab[0].Elements.Length; i++) {
                explorer.tab[0].Elements[i].IsSelected = false;
            }
        }

        void Render_DetailBar() {
            ElementInfo@ selectedElement = GetSelectedElement();
            if (selectedElement !is null) {
                UI::Text("Selected Element Details");
                UI::Separator();
                UI::Text("ICO: " + explorer.GetElementIconString(selectedElement.Icon, selectedElement.IsSelected));
                UI::Text("Name: " + selectedElement.Name);
                UI::Text("Path: " + selectedElement.Path);
                UI::Text("Size: " + selectedElement.Size);
                UI::Text("Type: " + selectedElement.Type);
                UI::Text("Last Modified: " + Time::FormatString("%Y-%m-%d %H:%M:%S", selectedElement.LastModifiedDate));
                UI::Text("Selected Time: " + selectedElement.LastSelectedTime);

                if (selectedElement.Type.ToLower() == "gbx") {
                    UI::Separator();
                    UI::Text("GBX File Detected - Displaying GBX Info");

                    dictionary gbxMetadata = selectedElement.GbxMetadata;

                    string value;
                    if (gbxMetadata.Get("type", value)) UI::Text("Type: " + value);
                    if (gbxMetadata.Get("exever", value)) UI::Text("Exe Version: " + value);
                    if (gbxMetadata.Get("exebuild", value)) UI::Text("Exe Build: " + value);
                    if (gbxMetadata.Get("title", value)) UI::Text("Title: " + value);

                    if (gbxMetadata.Get("map_uid", value)) UI::Text("Map UID: " + value);
                    if (gbxMetadata.Get("map_name", value)) UI::Text("Map Name: " + Text::StripFormatCodes(value));
                    if (gbxMetadata.Get("map_author", value)) UI::Text("Map Author: " + value);
                    if (gbxMetadata.Get("map_authorzone", value)) UI::Text("Map Author Zone: " + value);

                    if (gbxMetadata.Get("desc_envir", value)) UI::Text("Environment: " + value);
                    if (gbxMetadata.Get("desc_mood", value)) UI::Text("Mood: " + value);
                    if (gbxMetadata.Get("desc_maptype", value)) UI::Text("Map Type: " + value);
                    if (gbxMetadata.Get("desc_mapstyle", value)) UI::Text("Map Style: " + value);
                    if (gbxMetadata.Get("desc_displaycost", value)) UI::Text("Display Cost: " + value);
                    if (gbxMetadata.Get("desc_mod", value)) UI::Text("Mod: " + value);

                    if (gbxMetadata.Get("times_bronze", value)) UI::Text("Bronze Time: " + value);
                    if (gbxMetadata.Get("times_silver", value)) UI::Text("Silver Time: " + value);
                    if (gbxMetadata.Get("times_gold", value)) UI::Text("Gold Time: " + value);
                    if (gbxMetadata.Get("times_authortime", value)) UI::Text("Author Time: " + value);
                    if (gbxMetadata.Get("times_authorscore", value)) UI::Text("Author Score: " + value);

                    uint depIndex = 0;
                    while (gbxMetadata.Get("dep_file_" + tostring(depIndex), value)) {
                        UI::Text("Dependency File: " + value);
                        depIndex++;
                    }
                }
            } else {
                UI::Text("No element selected.");
            }
        }


        ElementInfo@ GetSelectedElement() {
            for (uint i = 0; i < explorer.tab[0].Elements.Length; i++) {
                if (explorer.tab[0].Elements[i].IsSelected) {
                    return explorer.tab[0].Elements[i];
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
        IO::FromUserGameFolder("Replays/"), // path // Change to Maps/ when done with general gbx detection is done
        "", // searchQuery
        { "txt", "docx" } // filters
    );
    // FileExplorer::explorer.StartIndexingFiles(IO::FromUserGameFolder("Replays/"));
}

void Render() {
    FILE_EXPLORER_BASE_RENDERER();
    FILE_EXPLORER_V1_BASE_RENDERER(); // Used for comparison, should be removed on release
    
    if (UI::Begin(Icons::UserPlus + " File Explorer", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
        if (UI::Button("Open File Explorer")) {
            OpenFileExplorerExample();
        }
    }    
    UI::End();
}



/* ------------------------ GBX Parsing ------------------------ */

// TODO:
// 

// Fixme:
// - Currently only Replay type is accounted for, need to add Map (and more) types as well (but it's proving to be a bit tricky) (Reason: nothing is being added to the xmlString)

class GbxHeaderChunkInfo
{
    int ChunkId;
    int ChunkSize;
}

dictionary ReadGbxHeader(const string &in path) {
    dictionary metadata;

    string xmlString = "";

    IO::File mapFile(path);
    mapFile.Open(IO::FileMode::Read);

    mapFile.SetPos(17);
    int headerChunkCount = mapFile.Read(4).ReadInt32();

    GbxHeaderChunkInfo[] chunks = {};
    for (int i = 0; i < headerChunkCount; i++) {
        GbxHeaderChunkInfo newChunk;
        newChunk.ChunkId = mapFile.Read(4).ReadInt32();
        newChunk.ChunkSize = mapFile.Read(4).ReadInt32() & 0x7FFFFFFF;
        chunks.InsertLast(newChunk);
    }

    for (uint i = 0; i < chunks.Length; i++) {
        MemoryBuffer chunkBuffer = mapFile.Read(chunks[i].ChunkSize);
        if (
               chunks[i].ChunkId == 50933761 // Replay chunk id
            || chunks[i].ChunkId == 50606082 // Map chunk id
            ) {
            int stringLength = chunkBuffer.ReadInt32();
            xmlString = chunkBuffer.ReadString(stringLength);
            break;
        }
    }

    mapFile.Close();

    if (xmlString != "") {
        XML::Document doc;
        doc.LoadString(xmlString);
        XML::Node headerNode = doc.Root().FirstChild();

        if (headerNode) {
            string gbxType = headerNode.Attribute("type");
            metadata["type"] = gbxType;
            metadata["exever"] = headerNode.Attribute("exever");
            metadata["exebuild"] = headerNode.Attribute("exebuild");
            metadata["title"] = headerNode.Attribute("title");

            if (gbxType == "map") {
                ParseMapMetadata(headerNode, metadata);
            } else if (gbxType == "replay") {
                ParseReplayMetadata(headerNode, metadata);
            }

            XML::Node playermodelNode = headerNode.Child("playermodel");
            if (playermodelNode) {
                metadata["playermodel_id"] = playermodelNode.Attribute("id");
            }
        }
    }

    return metadata;
}

void ParseMapMetadata(XML::Node &in headerNode, dictionary &inout metadata) {
    XML::Node identNode = headerNode.Child("ident");
    if (identNode) {
        metadata["map_uid"] = identNode.Attribute("uid");
        metadata["map_name"] = identNode.Attribute("name");
        metadata["map_author"] = identNode.Attribute("author");
        metadata["map_authorzone"] = identNode.Attribute("authorzone");
    }

    XML::Node descNode = headerNode.Child("desc");
    if (descNode) {
        metadata["desc_envir"] = descNode.Attribute("envir");
        metadata["desc_mood"] = descNode.Attribute("mood");
        metadata["desc_maptype"] = descNode.Attribute("type");
        metadata["desc_mapstyle"] = descNode.Attribute("mapstyle");
        metadata["desc_displaycost"] = descNode.Attribute("displaycost");
        metadata["desc_mod"] = descNode.Attribute("mod");
        metadata["desc_validated"] = descNode.Attribute("validated");
        metadata["desc_nblaps"] = descNode.Attribute("nblaps");
        metadata["desc_hasghostblocks"] = descNode.Attribute("hasghostblocks");
    }

    XML::Node timesNode = headerNode.Child("times");
    if (timesNode) {
        metadata["times_bronze"] = timesNode.Attribute("bronze");
        metadata["times_silver"] = timesNode.Attribute("silver");
        metadata["times_gold"] = timesNode.Attribute("gold");
        metadata["times_authortime"] = timesNode.Attribute("authortime");
        metadata["times_authorscore"] = timesNode.Attribute("authorscore");
    }

    XML::Node depsNode = headerNode.Child("deps");
    if (depsNode) {
        XML::Node depNode = depsNode.FirstChild();
        int depIndex = 0;
        while (depNode) {
            metadata["dep_file_" + tostring(depIndex)] = depNode.Attribute("file");
            depNode = depNode.NextSibling();
            depIndex++;
        }
    }
}

void ParseReplayMetadata(XML::Node &in headerNode, dictionary &inout metadata) {
    XML::Node mapNode = headerNode.Child("map");
    if (mapNode) {
        metadata["map_uid"] = mapNode.Attribute("uid");
        metadata["map_name"] = mapNode.Attribute("name");
        metadata["map_author"] = mapNode.Attribute("author");
        metadata["map_authorzone"] = mapNode.Attribute("authorzone");
    }

    XML::Node descNode = headerNode.Child("desc");
    if (descNode) {
        metadata["desc_envir"] = descNode.Attribute("envir");
        metadata["desc_mood"] = descNode.Attribute("mood");
        metadata["desc_maptype"] = descNode.Attribute("maptype");
        metadata["desc_mapstyle"] = descNode.Attribute("mapstyle");
        metadata["desc_displaycost"] = descNode.Attribute("displaycost");
        metadata["desc_mod"] = descNode.Attribute("mod");
    }

    XML::Node timesNode = headerNode.Child("times");
    if (timesNode) {
        metadata["replay_best"] = timesNode.Attribute("best");
        metadata["replay_respawns"] = timesNode.Attribute("respawns");
        metadata["replay_stuntscore"] = timesNode.Attribute("stuntscore");
        metadata["replay_validable"] = timesNode.Attribute("validable");
    }

    XML::Node checkpointsNode = headerNode.Child("checkpoints");
    if (checkpointsNode) {
        metadata["replay_checkpoints"] = checkpointsNode.Attribute("cur");
    }
}

/* ------------------------ End GBX Parsing ------------------------ */





/* ------------------------ DLL ------------------------ */

namespace DLL {
    Import::Library@ lib;
    Import::Function@ getFileCreationTimeFunc;

    bool loadLibrary() {
        if (lib is null) {
            string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
            @lib = Import::GetLibrary(dllPath);
            if (lib is null) {
                log("Failed to load DLL: " + dllPath, LogLevel::Error, 917, "loadLibrary");
                return false;
            }
        }

        if (getFileCreationTimeFunc is null) {
            @getFileCreationTimeFunc = lib.GetFunction("GetFileCreationTime");
            if (getFileCreationTimeFunc is null) {
                log("Failed to get function from DLL.", LogLevel::Error, 925, "loadLibrary");
                return false;
            }
            getFileCreationTimeFunc.SetConvention(Import::CallConvention::cdecl);
        }
        return true;
    }

    string FileCreatedTime(const string &in filePath) {
        if (!loadLibrary()) { return "-301"; }
        int64 result = getFileCreationTimeFunc.CallInt64(filePath);
        return tostring(result);
    }

    void UnloadLibrary() {
        @lib = null;
        @getFileCreationTimeFunc = null;
    }
}

string FileCreatedTime(const string &in filePath) {
    log("Attempting to retrieve file creation time for: " + filePath, LogLevel::Info, 946, "FileCreatedTime");

    if (!DLL::loadLibrary()) {
        log("Failed to load library for file creation time retrieval.", LogLevel::Error, 949, "FileCreatedTime");
        return "-300";
    }

    string result = DLL::FileCreatedTime(filePath);
    if (result != "") {
        log("Error retrieving file creation time. Code: " + result, LogLevel::Warn, 955, "FileCreatedTime");
    } else {
        log("File creation time retrieved successfully: " + result, LogLevel::Info, 957, "FileCreatedTime");
    }
    return result;
}

/* ------------------------ End DLL ------------------------ */
