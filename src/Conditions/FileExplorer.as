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
        int currentHistoryPosition = 0;

        bool reloadDirectory = false;
        bool goToDefaultDirectory = false;

        string currentSelectedElement = "";
        string currentSelectedElementPath = "";
        string currentSelectedFileName = "";

        // Tools
        bool copyFileNameToClipboard = false;
        bool copyFullFilePathToClipboard = false;
        bool deleteFile = false;
        // Sorting
        enum SortElementsBasedOnType { Alphabetical, Date, Type, Size };
        SortElementsBasedOnType currentSortingOption = SortElementsBasedOnType::Type;

        // Filter
        bool shouldFilterFileType = false;
        string currentFilter = "";

        // General
        bool mustReturnFilePath = false;
        enum DefaultDirectoryOrigin { None, Storage, Data, App, UserGame, Replays }
        DefaultDirectoryOrigin currentDefaultDirectoryOrigin = DefaultDirectoryOrigin::Replays;

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

        bool hidePathFromFilePath = false;

        // Optimization
        string lastIndexedDirectory = "";
        uint currentPage = 0;
        uint itemsPerPage = 30;

        // Export
        string exportElementPath = "";


        array<FileInfo> fileInfos;

        namespace Exports {
            string GetFileName() {
                currentSelectedFileName = _IO::GetFileExtension(currentSelectedElement);
                return currentSelectedFileName;
            }

            string GetFilePath() {
                currentSelectedElementPath = currentDirectory + GetFileName();
                return currentSelectedElementPath;
            }

            string GetExportPath() {
                return exportElementPath;
            }
        }

        void OpenFileExplorer(bool _mustReturnFilePath = false, const string &in _path = "", const string &in _searchQuery = "") {
            if (!_mustReturnFilePath) { mustReturnFilePath = true; } else { mustReturnFilePath = false; }
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
            // Render_SideBar();
            Render_MainView();
        }

        void Render_NavBar() {
            Render_NavBar_Top();
            UI::Separator();
            Render_NavBar_Middle();
            UI::Separator();
            Render_NavBar_Bottom();
        }

        void Render_NavBar_Top() {
            float totalWidth = UI::GetContentRegionAvail().x;
            float buttonWidth = 30.0f;
            float searchWidth = totalWidth * 0.20f;
            float currentDirectoryWidth = totalWidth - (7 * buttonWidth) - searchWidth;
            
            if (directoryHistory.IsEmpty()) 
                { _UI::DisabledButton(Icons::ArrowLeft, vec2(buttonWidth, 0)); } else {
                if (UI::Button(Icons::ArrowLeft, vec2(buttonWidth, 0))) { Hidden::FE_GoToPreviousDirectory(); } }
        UI::SameLine();
            // if (UI::Button(Icons::ArrowRight, vec2(buttonWidth, 0))) { Hidden::FE_GoToNextDirectory(); }
            // UI::SameLine();
            if (currentDirectory.EndsWith(":") || currentDirectory == "~" || currentDirectory == "" || currentDirectory == "/") {
                _UI::DisabledButton(Icons::ArrowUp, vec2(buttonWidth, 0)); } else {
                if (UI::Button(Icons::ArrowUp, vec2(buttonWidth, 0))) { Hidden::FE_GoToParentDirectory(); } }
        UI::SameLine();
            if (!_IO::IsDirectory(currentSelectedElement)) {
                _UI::DisabledButton(Icons::ArrowDown, vec2(buttonWidth, 0)); } else { 
                if (UI::Button(Icons::ArrowDown, vec2(buttonWidth, 0))) { Hidden::FE_GoToChildDirectory(); } }
        UI::SameLine();
            if (UI::Button(Icons::Refresh, vec2(buttonWidth, 0))) { IndexCurrentDirectory(); }
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
                if (directoryHistory.Length == 0) return;
                currentDirectory = directoryHistory[directoryHistory.Length - 1];
                directoryHistory.RemoveLast();
                currentPage = 0;
                IndexCurrentDirectory();
            }

            // void FE_GoToNextDirectory() {
                
            //     if (currentHistoryPosition < directoryHistory.Length) {
            //         currentHistoryPosition++;
            //         currentDirectory = directoryHistory[currentHistoryPosition];
            //         currentPage = 0;
            //         IndexCurrentDirectory();
            //     }
            // }

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
                    IndexCurrentDirectory();
                }
            }
            void FE_GoToChildDirectory() {
                string childFullPath = currentSelectedElement;

                if (childFullPath.Length <= 0) return;

                string newDir = childFullPath;
                if (_IO::IsDirectory(newDir)) {
                    directoryHistory.InsertLast(currentDirectory);
                    currentDirectory = newDir;
                    currentPage = 0;
                    IndexCurrentDirectory();
                } else {
                    NotifyWarn("Cannot move to a file. Please select a directory.");
                }
            }
        }

        void Render_NavBar_Middle() {
            float buttonWidth = 30.0f;

            if (UI::Button(Icons::ArrowLeft + " aa ")) {
                print("ArrowLeft button pressed");
            }
            UI::SameLine();

            if (UI::Button(Icons::ArrowRight + " bb ")) {
                print("ArrowRight button pressed");
            }

            UI::SameLine();
            if (UI::Button("Hide Path")) { hidePathFromFilePath = false; }
            UI::SameLine();
            if (UI::Button("Hide Folders")) { SO_Folders = false; }
            UI::SameLine();
            if (UI::Button("Hide Files")) { SO_Files = false; }
            UI::SameLine();
            if (UI::Button("Show Elements")) { SO_Folders = true; SO_Files = true; }
            
            UI::SameLine();

            if (UI::BeginCombo("Sorting", Hidden::GetSortingName(currentSortingOption), UI::ComboFlags::HeightRegular)) {
                if (UI::Selectable("Alphabetical", currentSortingOption == SortElementsBasedOnType::Alphabetical)) currentSortingOption = SortElementsBasedOnType::Alphabetical;
                if (UI::Selectable("Date", currentSortingOption == SortElementsBasedOnType::Date)) currentSortingOption = SortElementsBasedOnType::Date;
                if (UI::Selectable("Type", currentSortingOption == SortElementsBasedOnType::Type)) currentSortingOption = SortElementsBasedOnType::Type;
                if (UI::Selectable("Size", currentSortingOption == SortElementsBasedOnType::Size)) currentSortingOption = SortElementsBasedOnType::Size;
                UI::EndCombo();
            }
            
            UI::SameLine();

            if (UI::BeginCombo("Directory", Hidden::GetDirectoryName(currentDefaultDirectoryOrigin), UI::ComboFlags::HeightRegular)) {
                if (UI::Selectable("Replays", currentDefaultDirectoryOrigin == DefaultDirectoryOrigin::Replays)) Hidden::SetCurrentDirectory(DefaultDirectoryOrigin::Replays);
                if (UI::Selectable("PluginStorage", currentDefaultDirectoryOrigin == DefaultDirectoryOrigin::Storage)) Hidden::SetCurrentDirectory(DefaultDirectoryOrigin::Storage);
                if (UI::Selectable("OpenplanetNext", currentDefaultDirectoryOrigin == DefaultDirectoryOrigin::Data)) Hidden::SetCurrentDirectory(DefaultDirectoryOrigin::Data);
                if (UI::Selectable("\\games\\Trackmania", currentDefaultDirectoryOrigin == DefaultDirectoryOrigin::App)) Hidden::SetCurrentDirectory(DefaultDirectoryOrigin::App);
                if (UI::Selectable("\\Documents\\Trackmania", currentDefaultDirectoryOrigin == DefaultDirectoryOrigin::UserGame)) Hidden::SetCurrentDirectory(DefaultDirectoryOrigin::UserGame);
                UI::EndCombo();
            }

            UI::SameLine();

            shouldFilterFileType = UI::Checkbox("Filter File Type", shouldFilterFileType);
            // UI::BeginCombo("File Type", currentFilter, UI::ComboFlags::HeightRegular) {
            //     if (UI::Selectable("All", currentFilter == "")) currentFilter = "";
            //     if (UI::Selectable("Text", currentFilter == "txt")) currentFilter = "txt";
            //     if (UI::Selectable("PDF", currentFilter == "pdf")) currentFilter = "pdf";
            //     if (UI::Selectable("Word", currentFilter == "doc")) currentFilter = "doc";
            //     if (UI::Selectable("Excel", currentFilter == "xls")) currentFilter = "xls";
            //     if (UI::Selectable("Powerpoint", currentFilter == "ppt")) currentFilter = "ppt";
            //     if (UI::Selectable("Image", currentFilter == "jpg")) currentFilter = "jpg";
            //     if (UI::Selectable("Archive", currentFilter == "rar")) currentFilter = "rar";
            //     if (UI::Selectable("Audio", currentFilter == "ogg")) currentFilter = "ogg";
            //     if (UI::Selectable("Video", currentFilter == "mp4")) currentFilter = "mp4";
            //     if (UI::Selectable("Code", currentFilter == "cs")) currentFilter = "cs";
            //     if (UI::Selectable("Epub", currentFilter == "epub")) currentFilter = "epub";
            //     UI::EndCombo();
            // }
            
            if (shouldFilterFileType) {
                currentFilter = UI::InputText("File Type Filter", currentFilter);
            }
        }

        void Render_NavBar_Bottom() {
            if (mustReturnFilePath) {
                if (UI::Button("Cancel and close")) {
                    showInterface = false;
                }
                if (UI::Button("Submit current selected path and close")) {
                    exportElementPath = currentSelectedElementPath;
                    showInterface = false;
                }
            } else {
                if (UI::Button("Close")) {
                    showInterface = false;
                }
            }
            UI::SameLine();
            if (UI::Button("Copy Path to Clipboard")) {
                Hidden::CopyToClipboard(currentSelectedElementPath);
            }
            UI::SameLine();
            UI::Text("Selected File: " + currentSelectedElementPath);
        }

        void Render_MainView() {
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
                    Hidden::SortFileInfos(pageInfos, currentSortingOption);

                    for (uint i = 0; i < pageInfos.Length; i++) {
                        FileInfo info = pageInfos[i];
                        UI::TableNextRow();
                        if (UI::TableSetColumnIndex(0) && SS_ICON) {
                            UI::Text(Hidden::GetFileIcon(info));
                        }
                        if (UI::TableSetColumnIndex(1) && SS_FileOrFolderName) {
                            if (UI::Selectable(info.name, currentSelectedElement == info.name)) {
                                currentSelectedElement = info.name;
                                currentSelectedElementPath = info.name;
                                IndexCurrentDirectory();
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


        void IndexCurrentDirectory() {
            if (currentDirectory != lastIndexedDirectory) {
                Hidden::UpdateFileInfos();
                lastIndexedDirectory = currentDirectory;
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
                array<string> elements = IO::IndexFolder(currentDirectory, false);
                fileInfos.Resize(elements.Length);

                for (uint i = 0; i < elements.Length; i++) {
                    if (elements[i].Contains("\\/")) {
                        elements[i] = elements[i].Replace("\\/", "/");
                    }

                    string path = elements[i];
                    bool isFolder = _IO::IsDirectory(path);

                    fileInfos[i].name = elements[i];
                    fileInfos[i].isFolder = isFolder;
                    fileInfos[i].lastChangedDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                    fileInfos[i].size = isFolder ? "-" : Hidden::FormatSize(IO::FileSize(path));
                    fileInfos[i].creationDate = Time::FormatString("%Y-%m-%d %H:%M:%S", _IO::FileCreatedTime(path)); // the reason it is formatted with the current timestamp might be because of Time::FormatString, not sure though, will have to check at some point... Make a test plugin as they say :xdd:, or maybe -1 represents current time... idk xdd
                    fileInfos[i].clickCount = 0;
                }

                SortFileInfos(fileInfos, currentSortingOption);
            }

            string GetSortingName(SortElementsBasedOnType sorting) {
                switch (sorting) {
                    case SortElementsBasedOnType::Alphabetical: return "Alphabetical";
                    case SortElementsBasedOnType::Date: return "Date";
                    case SortElementsBasedOnType::Type: return "Type";
                    case SortElementsBasedOnType::Size: return "Size";
                }
                return "Unknown";
            }

            string GetDirectoryName(DefaultDirectoryOrigin option) {
                switch (option) {
                    case DefaultDirectoryOrigin::Storage: return "Storage";
                    case DefaultDirectoryOrigin::Data: return "Data";
                    case DefaultDirectoryOrigin::App: return "App";
                    case DefaultDirectoryOrigin::UserGame: return "User Game";
                    case DefaultDirectoryOrigin::Replays: return "Replays";
                    case DefaultDirectoryOrigin::None: return "";
                }
                return "";
            }

            void SetCurrentDirectory(DefaultDirectoryOrigin option) {
                currentDefaultDirectoryOrigin = option;
                switch (option) {
                    case DefaultDirectoryOrigin::Replays:
                        currentDirectory = IO::FromUserGameFolder("Replays/");
                        break;
                    case DefaultDirectoryOrigin::Storage:
                        if (!IO::FolderExists(IO::FromStorageFolder(""))) { IO::CreateFolder(IO::FromStorageFolder("")); }
                        currentDirectory = IO::FromStorageFolder("");
                        break;
                    case DefaultDirectoryOrigin::Data:
                        currentDirectory = IO::FromDataFolder("");
                        break;
                    case DefaultDirectoryOrigin::App:
                        currentDirectory = IO::FromAppFolder("");
                        break;
                    case DefaultDirectoryOrigin::UserGame:
                        currentDirectory = IO::FromUserGameFolder("");
                        break;
                    case DefaultDirectoryOrigin::None:
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

            void SortFileInfos(array<FileInfo>@ fileInfos, SortElementsBasedOnType sorting) {
                if (fileInfos.Length == 0) return;
                for (uint i = 0; i < fileInfos.Length - 1; i++) {
                    for (uint j = i + 1; j < fileInfos.Length; j++) {
                        bool swap = false;
                        switch (sorting) {
                            case SortElementsBasedOnType::Alphabetical:
                                swap = fileInfos[i].name.ToLower() > fileInfos[j].name.ToLower();
                                break;
                            case SortElementsBasedOnType::Date:
                                swap = fileInfos[i].lastChangedDate > fileInfos[j].lastChangedDate;
                                break;
                            case SortElementsBasedOnType::Type:
                                if (fileInfos[i].isFolder != fileInfos[j].isFolder) {
                                    swap = !fileInfos[i].isFolder && fileInfos[j].isFolder;
                                } else {
                                    swap = fileInfos[i].name.ToLower() > fileInfos[j].name.ToLower();
                                }
                                break;
                            case SortElementsBasedOnType::Size:
                                if (fileInfos[i].isFolder != fileInfos[j].isFolder) {
                                    swap = !fileInfos[i].isFolder && fileInfos[j].isFolder;
                                } else if (fileInfos[i].size != fileInfos[j].size) {
                                    swap = fileInfos[i].size < fileInfos[j].size;
                                } else {
                                    swap = fileInfos[i].name.ToLower() > fileInfos[j].name.ToLower();
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
    void SafeMoveSourceFileToNonSource(const string &in originalPath, const string &in storagePath, bool verbose = false) {
        string fileContents = _IO::ReadSourceFileToEnd(originalPath);
        if (verbose) log("Moving the file content", LogLevel::Info, 24, "MoveFileToPluginStorage");

        SafeCreateFolder(StripFileNameFromPath(storagePath), true);

        _IO::SafeSaveToFile(storagePath, fileContents, true);
        if (verbose) log("Finished moving the file", LogLevel::Info, 33, "MoveFileToPluginStorage");
    }

    namespace DLL { // Had to do it like this because of the automatic garbage collection :xdd:
    /*
        Import::Library@ g_lib;
        Import::Function@ g_getFileCreationTimeFunc;

        bool loadLibrary() {
            if (g_lib is null) {
                string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
                @g_lib = Import::GetLibrary(dllPath);
                if (g_lib is null) { log("Failed to load DLL: " + dllPath, LogLevel::Error); return false; }
            }

            if (g_getFileCreationTimeFunc is null) {
                @g_getFileCreationTimeFunc = g_lib.GetFunction("GetFileCreationTime");
                if (g_getFileCreationTimeFunc is null) { log("Failed to get function from DLL.", LogLevel::Error); return false; }
                g_getFileCreationTimeFunc.SetConvention(Import::CallConvention::cdecl);
            }
            return true;
        }

        int64 FileCreatedTime(const string &in filePath) {
            if (!loadLibrary()) { return -1; }
            int64 result = g_getFileCreationTimeFunc.CallInt64(filePath);
            return result;
        }

        void UnloadLibrary() {
            @g_lib = null;
            @g_getFileCreationTimeFunc = null;
        }*/
    }

    int64 FileCreatedTime(const string &in filePath) {
        // return /*DLL::FileCreatedTime*/(filePath);
        return -1;
    }
}