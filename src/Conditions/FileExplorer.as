void Render() {
    if (_IO::FileExplorer::showInterface) {
        _IO::FileExplorer::RenderFileExplorer();
    }

    //_IO::FileExplorer::OpenFileExplorer(bool mustReturnFilePath = true, string path, string searchQuery = "");
}

namespace _IO {
    namespace FileExplorer {
        // Render 
        bool showInterface = false;

        // Per element info structure
        enum FileInfoIcon { Folder, File, Text, Pdf, Word, Excel, Powerpoint, Image, Archive, Audio, Video, Code, Epub };
        class FileInfo {
            bool isFolder;
            int clickCount = 0;

            FileInfoIcon icon = FileInfoIcon::File;

            string name;
            string fileExtention; //
            string lastChangedDate;
            string size;
            string creationDate;
            string creator;
        }

        // Search and navigation
        string currentDirectory = "~";
        string currentSearchQuery = "";
        
        array<string> directoryHistory;

        bool reloadDirectory = false;
        bool goToDefaultDirectory = false;

        // Tools
        bool copyFileNameToClipboard = false;
        bool copyFullFilePathToClipboard = false;
        bool deleteFile = false;
        // Sorting
        enum SortElementsBasedOnType { Name, Date, Type, Size };
        SortElementsBasedOnType elementTypeSorting = SortElementsBasedOnType::Type;

        // Main view
        uint currentPage = 0;
        uint itemsPerPage = 100;

        // Filter
        string currentSelectedElement = "";
        string selectedElementPath = "";
        string selectedFileName = "";

        // General        
        bool shouldFilterFileType = false;

        enum DefaultDirectoryOrigin { None, Storage, Data, App, UserGame, Replays }
        DefaultDirectoryOrigin currentDirectoryOption = DefaultDirectoryOrigin::None;

        // States
        // SS = Shold Show; SO = Show Only
        bool SO_Files = false;
        bool SO_Folders = false;

        bool SS_ICON = true;
        bool SS_FileOrFolderName = true;
        bool SS_LastChangedDate = true;
        bool SS_FileType = true;
        bool SS_Size = true;
        bool SS_CreationDate = true;


        array<FileInfo> fileInfos;

        void OpenFileExplorer(bool mustReturnFilePath = false, const string &in _path, const string &in _searchQuery) {
            showInterface = true;
            currentDirectory = _path;
            currentSearchQuery = _searchQuery;
            directoryHistory.Resize(0);
            reloadDirectory = false;
            goToDefaultDirectory = true;
            IndexCurrentDirectory();
        }

        void RenderFileExplorer() {
            if (UI::Begin("File Dialog", showInterface, UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoCollapse)) {
                Render_Structure();
                UI::End();
            }
        }

        void Render_Structure() {
            Render_NavBar();
            Render_MainView();
            Render_SideBar();
        }

        void Render_NavBar() {
            Render_NavBar_Top();
            UI::Separator();
            Render_NavBar_Bottom();
        }

        void Render_NavBar_Top() {
            float totalWidth = UI::GetContentRegionAvail().x; // Get the total available width
            float buttonWidth = 40.0f; // Smallest width for buttons
            float searchWidth = totalWidth * 0.20f; // 20% width for search bar
            float currentDirectoryWidth = totalWidth - (4 * buttonWidth) - searchWidth; // Rest of the width for file path
            
            if (UI::Button("ARROW_LEFT", vec2(buttonWidth, 0))) { Hidden::FE_GoToPreviousDirectory(); }
            UI::SameLine();
            if (UI::Button("ARROW_RIGHT", vec2(buttonWidth, 0))) { Hidden::FE_GoToNextDirectory(); }
            UI::SameLine();
            if (UI::Button("ARROW_UP", vec2(buttonWidth, 0))) { Hidden::FE_GoToParentDirectory(); }
            UI::SameLine();
            if (UI::Button("ARROW_DOWN", vec2(buttonWidth, 0))) { Hidden::FE_GoToChildDirectory(); }

            UI::SameLine();

            UI::PushItemWidth(currentDirectoryWidth);
            currentDirectory = UI::InputText("##CurrentDirectory", currentDirectory);
            UI::PopItemWidth();

            UI::SameLine();
            
            UI::PushItemWidth(searchWidth);
            currentSearchQuery = UI::InputText("##Search", currentSearchQuery);
            UI::PopItemWidth();

        }
        namespace Hidden {
            void FE_GoToPreviousDirectory() {
                if (directoryHistory.Length > 0) {
                    currentDirectory = directoryHistory[directoryHistory.Length - 1];
                    directoryHistory.RemoveLast();
                    currentPage = 0;
                    reloadDirectory = true;
                }
            }
            void FE_GoToNextDirectory() {
                if (IsDirectory(currentSelectedElement)) { 
                    currentDirectory = currentSelectedElement; 
                    IndexCurrentDirectory();
                } else {
                    NotifyWarn("Cannot set the current directory to a file path, it has to be a folder"); 
                }
            }
            void FE_GoToParentDirectory() {
                if (currentDirectory.Length <= 0) return;

                if (currentDirectory.EndsWith("/") || currentDirectory.EndsWith("\\")) {
                    currentDirectory = currentDirectory.SubStr(0, currentDirectory.Length - 1);
                }

                int posSlash = _Text::LastIndexOf(currentDirectory, "/");
                int posBackslash = _Text::LastIndexOf(currentDirectory, "\\");
                int pos = Math::Max(posSlash, posBackslash);

                if (pos != -1) {
                    string newDir = currentDirectory.SubStr(0, pos);
                    directoryHistory.InsertLast(currentDirectory);
                    currentDirectory = newDir;
                    currentPage = 0;
                    reloadDirectory = true;
                }
            }
            void FE_GoToChildDirectory() {
                if (currentSelectedElement.Length <= 0) return;
                if (currentSelectedElement == "..") return;

                string newDir = currentDirectory + "/" + currentSelectedElement;
                if (_IO::IsDirectory(newDir)) {
                    directoryHistory.InsertLast(currentDirectory);
                    currentDirectory = newDir;
                    currentPage = 0;
                    reloadDirectory = true;
                }
            }
        }

        void Render_NavBar_Bottom() {
            if (UI::Button("Hide Folders")) { SO_Folders = false; }
            UI::SameLine();
            if (UI::Button("Hide Files")) { SO_Files = false; }
            UI::SameLine();
            if (UI::Button("Show Elements")) { SO_Folders = true; SO_Files = true; }
            UI::SameLine();
            
        }


        void renderplaceholderfornow() {


                

                if (UI::BeginCombo("Sorting", Hidden::GetSortingName(sorting), UI::ComboFlags::HeightRegular)) {
                    if (UI::Selectable("Name", sorting == Sorting::Name)) sorting = Sorting::Name;
                    if (UI::Selectable("Date", sorting == Sorting::Date)) sorting = Sorting::Date;
                    if (UI::Selectable("Type", sorting == Sorting::Type)) sorting = Sorting::Type;
                    if (UI::Selectable("Size", sorting == Sorting::Size)) sorting = Sorting::Size;
                    UI::EndCombo();
                }

                UI::SameLine();

                if (UI::BeginCombo("Directory", Hidden::GetDirectoryName(currentDirectoryOption), UI::ComboFlags::HeightRegular)) {
                    if (UI::Selectable("PluginStorage", currentDirectoryOption == DirectoryOption::Storage)) Hidden::SetCurrentDirectory(DirectoryOption::Storage);
                    if (UI::Selectable("OpenplanetNext", currentDirectoryOption == DirectoryOption::Data)) Hidden::SetCurrentDirectory(DirectoryOption::Data);
                    if (UI::Selectable("\\games\\Trackmania", currentDirectoryOption == DirectoryOption::App)) Hidden::SetCurrentDirectory(DirectoryOption::App);
                    if (UI::Selectable("\\Documents\\Trackmania", currentDirectoryOption == DirectoryOption::UserGame)) Hidden::SetCurrentDirectory(DirectoryOption::UserGame);
                    UI::EndCombo();
                }

                UI::SameLine();

                UI::Checkbox("Filter File Type", FilterFileType);
                if (FilterFileType) {
                    FileTypeFilter = UI::InputText("File Type Filter", FileTypeFilter);
                }

                currentDir = UI::InputText("Current Directory", currentDir);

                if (UI::Button("Submit current selected path and close")) {
                    showInterface = false; // It's already submitted when the path is selected :xpp:
                }

                UI::Separator();

                ShowFileTable();

                UI::Separator();

                if (UI::Button("Copy Path to Clipboard")) {
                    Hidden::CopyToClipboard(selectedElementPath);
                }

                UI::Text("Selected File: " + selectedElementPath);

                UI::End();
            }
        }

        void IndexCurrentDirectory() {
            if (currentDir != lastIndexedDir) {
                Hidden::UpdateFileInfos();
                lastIndexedDir = currentDir;
            }
        }

        void ShowFileTable() {
            double lastClickTime = 0;
            string lastClickedItem = "";
            double clickThreshold = 0.5;

            if (UI::BeginTable("FileTable", 6, UI::TableFlags::Resizable | UI::TableFlags::Reorderable | UI::TableFlags::Hideable | UI::TableFlags::Sortable)) {
                UI::TableSetupColumn("ICO", UI::TableColumnFlags::WidthFixed, 40.0f);
                UI::TableSetupColumn("File / Folder Name");
                UI::TableSetupColumn("Last Change Date");
                UI::TableSetupColumn("Type");
                UI::TableSetupColumn("Size");
                UI::TableSetupColumn("Creation Date");
                UI::TableHeadersRow();

                array<FileInfo> pageInfos = Hidden::GetFilesForCurrentPage();
                if (pageInfos.IsEmpty()) {
                    UI::Text("No elements in this directory.");
                } else {
                    for (uint i = 0; i < pageInfos.Length; i++) {
                        FileInfo info = pageInfos[i];
                        UI::TableNextRow();
                        if (UI::TableSetColumnIndex(0) && SS_ICON) {
                            UI::Text(Hidden::GetFileIcon(info));
                        }
                        if (UI::TableSetColumnIndex(1) && SS_FileOrFolderName) {
                            if (UI::Selectable(info.name, currentSelectedElement == info.name)) {
                                info.clickCount++;
                                if (info.clickCount == 2 && info.isFolder) {
                                    dirHistory.InsertLast(currentDir);
                                    currentDir = info.name;
                                    currentPage = 0;
                                    info.clickCount = 0;
                                    IndexCurrentDirectory();
                                }
                                currentSelectedElement = info.name;
                                selectedElementPath = info.name;
                            }
                        }
                        if (UI::TableSetColumnIndex(2) && SS_LastChangedDate) {
                            UI::Text(info.lastChangedDate);
                        }
                        if (UI::TableSetColumnIndex(3) && SS_FileType) {
                            UI::Text(info.isFolder ? "Folder" : "File");
                        }
                        if (UI::TableSetColumnIndex(4) && SS_Size) {
                            UI::Text(info.size);
                        }
                        if (UI::TableSetColumnIndex(5) && SS_CreationDate) {
                            UI::Text(info.creationDate);
                        }
                    }
                }
                UI::EndTable();
            }
        }

        namespace Hidden {
            array<FileInfo> GetFilesForCurrentPage() {
                uint start = currentPage * itemsPerPage;
                uint end = Math::Min(start + itemsPerPage, fileInfos.Length);
                array<FileInfo> pageItems;
                for (uint i = start; i < end; i++) {
                    pageItems.InsertLast(fileInfos[i]);
                }
                return pageItems;
            }

            void UpdateFileInfos() {
                array<string> elements = IO::IndexFolder(currentDir, false);
                fileInfos.Resize(elements.Length);

                for (uint i = 0; i < elements.Length; i++) {
                    string path = elements[i];
                    bool isFolder = _IO::IsDirectory(path);

                    fileInfos[i].name = elements[i];
                    fileInfos[i].isFolder = isFolder;
                    fileInfos[i].lastChangedDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                    fileInfos[i].size = isFolder ? "-" : Hidden::FormatSize(IO::FileSize(path));
                    fileInfos[i].creationDate = Time::FormatString("%Y-%m-%d %H:%M:%S", _IO::FileCreatedTime(path));
                    fileInfos[i].clickCount = 0;
                }
                SortFileInfos(fileInfos, sorting);
            }

            string GetSortingName(Sorting sorting) {
                switch (sorting) {
                    case Sorting::Name: return "Name";
                    case Sorting::Date: return "Date";
                    case Sorting::Type: return "Type";
                    case Sorting::Size: return "Size";
                }
                return "Unknown";
            }

            string GetDirectoryName(DirectoryOption option) {
                switch (option) {
                    case DirectoryOption::Storage: return "Storage";
                    case DirectoryOption::Data: return "Data";
                    case DirectoryOption::App: return "App";
                    case DirectoryOption::UserGame: return "User Game";
                    case DirectoryOption::None: return "";
                }
                return "";
            }

            void SetCurrentDirectory(DirectoryOption option) {
                currentDirectoryOption = option;
                switch (option) {
                    case DirectoryOption::Storage:
                        if (!IO::FolderExists(IO::FromStorageFolder(""))) { IO::CreateFolder(IO::FromStorageFolder("")); }
                        currentDir = IO::FromStorageFolder("");
                        break;
                    case DirectoryOption::Data:
                        currentDir = IO::FromDataFolder("");
                        break;
                    case DirectoryOption::App:
                        currentDir = IO::FromAppFolder("");
                        break;
                    case DirectoryOption::UserGame:
                        currentDir = IO::FromUserGameFolder("");
                        break;
                    case DirectoryOption::None:
                        break;
                }
                IndexCurrentDirectory();
            }

            string GetFileIcon(FileInfo@ info) {
                if (info.isFolder) {
                    return (info.name == currentSelectedElement) ? "\\$FD4"+Icons::FolderOpenO+"\\$g" : "\\$FD4"+Icons::FolderO+"\\$g";
                }

                string ext = _IO::GetFileExtension(info.name).ToLower();
                if (ext == "txt" || ext == "rtf" || ext == "csv" || ext == "json") return Icons::FileTextO;
                if (ext == "pdf") return Icons::FilePdfO;
                if (ext == "doc" || ext == "docx") return Icons::FileWordO;
                if (ext == "xls" || ext == "xlsx") return Icons::FileExcelO;
                if (ext == "ppt" || ext == "pptx") return Icons::FilePowerpointO;
                if (ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "gif") return Icons::FileImageO;
                if (ext == "rar" || ext == "zip" || ext == "7z") return Icons::FileArchiveO;
                if (ext == "ogg" || ext == "mp3" || ext == "wav") return Icons::FileAudioO;
                if (ext == "mp4" || ext == "mov") return Icons::FileVideoO;
                if (ext == "cs" || ext == "cpp" || ext == "js" || ext == "java" || ext == "py") return Icons::FileCodeO;
                if (ext == "epub") return Icons::FileEpub;
                return (info.name == currentSelectedElement) ? "\\$bcd"+Icons::File+"\\$g" : "\\$bcd"+Icons::FileO+"\\$g";
            }

            void SortFileInfos(array<FileInfo>@ fileInfos, Sorting sorting) {
                if (fileInfos.Length == 0) return;
                for (uint i = 0; i < fileInfos.Length - 1; i++) {
                    for (uint j = i + 1; j < fileInfos.Length; j++) {
                        bool swap = false;
                        switch (sorting) {
                            case Sorting::Name:
                                swap = fileInfos[i].name.ToLower() > fileInfos[j].name.ToLower();
                                break;
                            case Sorting::Date:
                                swap = fileInfos[i].lastChangedDate > fileInfos[j].lastChangedDate;
                                break;
                            case Sorting::Type:
                                if (fileInfos[i].isFolder && !fileInfos[j].isFolder) {
                                } else if (!fileInfos[i].isFolder && fileInfos[j].isFolder) {
                                    swap = true;
                                }
                                break;
                            case Sorting::Size:
                                if (!fileInfos[i].isFolder && !fileInfos[j].isFolder) {
                                    swap = fileInfos[i].size > fileInfos[j].size;
                                }
                                break;
                        }
                        if (swap) {
                            FileInfo temp = fileInfos[i];
                            fileInfos[i] = fileInfos[j];
                            fileInfos[j] = temp;
                        }
                    }
                }
            }

            string FormatSize(uint64 size) {
                if (size < 1024) return size + " B";
                size /= 1024;
                if (size < 1024) return size + " KB";
                size /= 1024;
                if (size < 1024) return size + " MB";
                size /= 1024;
                return size + " GB";
            }

            void CopyToClipboard(const string &in text) {
                IO::SetClipboard(text);
            }
        }
    }
}

namespace _IO {
    int64 FileCreatedTime(const string &in filePath) {
        string dllPath = "/src/Conditions/CompanionDLLs/FileCreationTime.dll";

        if (!IO::FileExists(dllPath)) {
            log("DLL does not exist: " + dllPath, LogLevel::Error);
            return -1;
        }

        Import::Library@ lib = Import::GetLibrary(dllPath);
        if (lib is null) {
            log("Failed to load DLL: " + dllPath, LogLevel::Error);
            return -1;
        }

        Import::Function@ func = lib.GetFunction("GetFileCreationTime");
        if (func is null) {
            log("Failed to get function from DLL: " + dllPath, LogLevel::Error);
            return -1;
        }

        func.SetConvention(Import::CallConvention::cdecl);

        int64 result = func.CallInt64(filePath);
        return result;
    }
}