void FILE_EXPLORER_BASE_RENDERER() { // MUST BE CALLED IN THE MAIN RENDER LOOP OF YOUR PLUGIN
    if (_IO::FileExplorer::showInterface) {
        _IO::FileExplorer::RenderFileExplorer();
    }
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
            string fileExtension; //
            string lastChangedDate;
            string size;
            string creationDate;
            string creator;

            string fileType;
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
        bool SO_Files = true;
        bool SO_Folders = true;

        bool SS_ICON = true;
        bool SS_FileOrFolderName = true;
        bool SS_LastChangedDate = true;
        bool SS_fileExtension = true;
        bool SS_FileType = true;
        bool SS_Size = true;
        bool SS_CreationDate = true;

        bool hidePathFromFilePath = false;

        // Optimization
        const uint MAX_ELEMENTS_PER_PAGE = 30;

        string lastIndexedDirectory = "";
        uint currentPage = 0;
        uint itemsPerPage = MAX_ELEMENTS_PER_PAGE;
        bool usePaigination = true;

        // Export
        string exportElementPath = "";

        // File/folder dings
        bool showRenameOption = false;
        string newFileName = "";
        bool showDeleteFile = false;
        bool showMakeFolder = false;
        string newFolderName = "";
        bool showDeleteDir = false;

        array<FileInfo> fileInfos;

        namespace Exports {
            string GetFileName() {
                currentSelectedFileName = _IO::File::GetFileExtension(currentSelectedElement);
                return currentSelectedFileName;
            }

            string GetFilePath() {
                currentSelectedElementPath = currentDirectory + GetFileName();
                return currentSelectedElementPath;
            }

            string GetExportPath() {
                return exportElementPath;
            }

            string GetExportPathFileExt() {
                string properFileExtension = _IO::File::GetFileExtension(GetExportPath()).ToLower();
                if (properFileExtension == "gbx") {
                    int secondLastDotIndex = _Text::NthLastIndexOf(GetExportPath(), ".", 2);
                    int lastDotIndex = _Text::LastIndexOf(GetExportPath(), ".");
                    if (secondLastDotIndex != -1 && lastDotIndex > secondLastDotIndex) {
                        properFileExtension = GetExportPath().SubStr(secondLastDotIndex + 1, lastDotIndex - secondLastDotIndex - 1);
                    }
                }
                return properFileExtension;
            }

            void ClearExportPath() {
                exportElementPath = "";
            }
        }

        void OpenFileExplorer(bool _mustReturnFilePath = false, const string &in _path = "", const string &in _searchQuery = "", array<string> _filters = {}) {
            mustReturnFilePath = _mustReturnFilePath;
            showInterface = true;
            currentDirectory = _path;
            currentSearchQuery = _searchQuery;
            directoryHistory.Resize(0);
            reloadDirectory = false;
            goToDefaultDirectory = true;

            if (_filters.Length == 1) {
                shouldFilterFileType = true;
                currentFilter = _filters[0];
            } else if (_filters.Length > 1) {
                shouldFilterFileType = true;
                currentFilter = string::Join(_filters, "|");
            }

            IndexCurrentDirectory();
        }

        void RenderFileExplorer() {
            if (UI::Begin("File Explorer", showInterface, UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoCollapse)) {
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
            if (!_IO::Folder::IsDirectory(currentSelectedElement)) {
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
            UI::Text(Icons::Search);
            UI::SameLine();
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
                if (_IO::Folder::IsDirectory(newDir)) {
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
            if (UI::Button(Icons::ChevronLeft, vec2(buttonWidth, 0))) {    // the icon here CANNOT be Icons::ArrowLeft, it has to be something else since the history arrow is blocking it (they cannot have the same
                if (currentPage > 0) { currentPage--; IndexCurrentDirectory(); } // label). I could just add an invisible space, but having different icons is probably better anyways :COPIUM:
            }                                                                    // NOTE TO SELF: I should make an issue about this.
            UI::SameLine();

            if (UI::Button(Icons::ChevronRight, vec2(buttonWidth, 0))) {
                float maxPage = Math::Ceil(float(fileInfos.Length) / float(itemsPerPage)) - 1;
                if (int(currentPage) < int(maxPage)) { currentPage++; IndexCurrentDirectory(); }
            }

            UI::SameLine();

            if (UI::Button(Icons::Folder, vec2(buttonWidth, 0))) {
                _IO::OpenFolder(currentDirectory);
            }

            UI::SameLine();
            if (UI::Button(!hidePathFromFilePath ? "Hide Path" : "Show Path")) { hidePathFromFilePath = !hidePathFromFilePath; }
            UI::SameLine();
            if (UI::Button(SO_Folders ? "Hide Folders" : "Show Folders")) { SO_Folders = !SO_Folders; }
            UI::SameLine();
            if (UI::Button(SO_Files ? "Hide Files" : "Show Files")) { SO_Files = !SO_Files; }
            UI::SameLine();
            if (UI::Button(usePaigination ? "Disable Pagination" : "Enable Pagination")) { usePaigination = !usePaigination; }
            if (!usePaigination) { itemsPerPage = fileInfos.Length; }
            if (usePaigination) { itemsPerPage = MAX_ELEMENTS_PER_PAGE; }
            UI::SameLine();
            if (UI::Button(showRenameOption ? "Rename File" : "Rename File")) { showRenameOption = !showRenameOption; }
            UI::SameLine();
            if (UI::Button("Delete File")) { showDeleteFile = !showDeleteFile; }
            UI::SameLine();
            if (UI::Button("Make Directory")) { showMakeFolder = !showMakeFolder; }
            UI::SameLine();
            if (UI::Button("Delete Directory")) { showDeleteDir = !showDeleteDir; }
            
            if (showDeleteDir) {
                if (UI::Button("Confirm Deletion")) {
                    IO::DeleteFolder(currentSelectedElementPath);
                    IndexCurrentDirectory();
                }
            }

            if (showMakeFolder) {
                newFolderName = UI::InputText("New Folder Name", newFolderName);
                UI::SameLine();
                if (UI::Button("Create Folder")) {
                    IO::CreateFolder(currentDirectory + newFolderName);
                    IndexCurrentDirectory();
                }
            }

            if (showDeleteFile) {
                if (UI::Button("Confirm Deletion")) {
                    IO::Delete(currentSelectedElementPath);
                    IndexCurrentDirectory();
                }
            }

            if (showRenameOption) {
                newFileName = UI::InputText("+ ." + _IO::File::GetFileExtension(currentSelectedElementPath) +  " | New File Name", newFileName);
                UI::SameLine();
                if (!_IO::File::IsFile(currentSelectedElementPath)) 
                { _UI::DisabledButton("Complete the renaming"); } else {
                    if (UI::Button("Complete the renaming")) { 
                        _IO::File::RenameFile(currentSelectedElementPath, newFileName); 
                        IndexCurrentDirectory();
                } }
            }

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

            shouldFilterFileType = UI::Checkbox("Filter File Extention", shouldFilterFileType);
            if (shouldFilterFileType) { UI::SameLine(); currentFilter = UI::InputText("File Extention Filter", currentFilter); }
        }

        void Render_NavBar_Bottom() {
            if (mustReturnFilePath) {
                if (UI::Button("Cancel and close")) {
                    showInterface = false;
                }
                UI::SameLine();
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
            UI::Text("Selected File: ");
            if (currentSelectedElementPath != "") { UI::Text(currentSelectedElementPath); }
        }

        void Render_MainView() {
            if (UI::BeginTable("FileTable", 7, UI::TableFlags::Resizable | UI::TableFlags::Reorderable | UI::TableFlags::Hideable | UI::TableFlags::Sortable)) {
                UI::TableSetupColumn("ICO", UI::TableColumnFlags::WidthFixed, 30.0f);
                UI::TableSetupColumn("File / Folder Name");
                UI::TableSetupColumn("Last Change Date");
                UI::TableSetupColumn("Ext");
                UI::TableSetupColumn("Type");
                UI::TableSetupColumn("Size");
                UI::TableSetupColumn("Creation Date");
                UI::TableHeadersRow();

                array<FileInfo> pageInfos = Hidden::GetFilesForCurrentPage();
                if (pageInfos.IsEmpty()) {
                    UI::Text("No elements in this directory.");
                } else {
                    Hidden::SortFileInfos(pageInfos, currentSortingOption);

                    array<string> filters = currentFilter.Split('|');
                    for (uint i = 0; i < pageInfos.Length; i++) {
                        FileInfo info = pageInfos[i];
                        string displayName = info.name;

                        bool isVisible = info.isFolder;
                        if (!info.isFolder && shouldFilterFileType) {
                            string fileExtLower = info.fileExtension.ToLower();
                            isVisible = false;
                            for (uint j = 0; j < filters.Length; j++) {
                                string trimmedFilter = filters[j].Trim();
                                if (fileExtLower == trimmedFilter.ToLower()) {
                                    isVisible = true;
                                    break;
                                }
                            }
                        }

                        if (currentFilter == "") isVisible = true;
                        if (!isVisible) continue;

                        if (hidePathFromFilePath) {
                            int x = currentDirectory.Length;
                            if (displayName.SubStr(0, x) == currentDirectory) {
                                displayName = displayName.SubStr(x);
                            }
                        }

                        if (info.isFolder && !SO_Folders) continue;
                        if (!info.isFolder && !SO_Files) continue;

                        UI::TableNextRow();
                        if (UI::TableSetColumnIndex(0) && SS_ICON) {
                            UI::Text(Hidden::GetFileIcon(info));
                        }
                        if (UI::TableSetColumnIndex(1) && SS_FileOrFolderName) {
                            if (UI::Selectable(displayName, currentSelectedElement == Text::StripFormatCodes(info.name))) {
                                currentSelectedElement = info.name;
                                currentSelectedElementPath = info.name;
                                IndexCurrentDirectory();
                            }
                        }
                        if (UI::TableSetColumnIndex(2) && SS_LastChangedDate) {
                            UI::Text(info.lastChangedDate);
                        }
                        if (UI::TableSetColumnIndex(3) && SS_fileExtension) {
                            UI::Text(info.fileExtension);
                        }
                        if (UI::TableSetColumnIndex(4) && SS_FileType) {
                            UI::Text(info.isFolder ? "Folder" : "File");
                        }
                        if (UI::TableSetColumnIndex(5) && SS_Size) {
                            UI::Text(info.size);
                        }
                        if (UI::TableSetColumnIndex(6) && SS_CreationDate) {
                            UI::Text(info.creationDate);
                        }
                    }
                }
                UI::EndTable();
                
            }
            if (usePaigination) UI::Text("Current Page: " + currentPage);
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
                    bool isFolder = _IO::Folder::IsDirectory(path);

                    fileInfos[i].name = elements[i];
                    fileInfos[i].isFolder = isFolder;
                    fileInfos[i].lastChangedDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                    fileInfos[i].size = isFolder ? "-" : Hidden::FormatSize(IO::FileSize(path));
                    fileInfos[i].creationDate = Time::FormatString("%Y-%m-%d %H:%M:%S", _IO::FileCreatedTime(path)); // the reason it is formatted with the current timestamp might be because of Time::FormatString, not sure though, will have to check at some point... Make a test plugin as they say :xdd:, or maybe -1 represents current time... idk xdd
                    fileInfos[i].clickCount = 0;

                    string fullFileExtension = _IO::File::GetFileExtension(path).ToLower();
                    if (fullFileExtension == "gbx") {
                        int secondLastDotIndex = _Text::NthLastIndexOf(path, ".", 2);
                        int lastDotIndex = _Text::LastIndexOf(path, ".");
                        if (secondLastDotIndex != -1 && lastDotIndex > secondLastDotIndex) {
                            fullFileExtension = path.SubStr(secondLastDotIndex + 1, lastDotIndex - secondLastDotIndex - 1);
                        }
                    }
                    fileInfos[i].fileExtension = fullFileExtension;
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

                string ext = _IO::File::GetFileExtension(info.name).ToLower();
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
        if (verbose) log("Moving the file content", LogLevel::Info, 643, "SafeMoveSourceFileToNonSource");
        // IO::FileSource originalFile(originalPath);
        // string fileContents = originalFile.ReadToEnd();
        
        string fileContents = _IO::File::ReadSourceFileToEnd(originalPath);
        
        _IO::Folder::SafeCreateFolder(_IO::File::StripFileNameFromFilePath(storagePath), true);

        _IO::File::WriteToFile(storagePath, fileContents);
        /*IO::File targetFile;
        targetFile.Open(storagePath, IO::FileMode::Write);
        targetFile.Write(fileContents);
        targetFile.Close();*/

        if (verbose) log("Finished moving the file", LogLevel::Info, 652, "SafeMoveSourceFileToNonSource");
    }

    void SafeMoveFileToNonSource(const string &in originalPath, const string &in storagePath, bool verbose = false) {
        if (verbose) log("Moving the file content", LogLevel::Info, 663, "SafeMoveFileToNonSource");
        
        /*IO::File originalFile;
        originalFile.Open(originalPath, IO::FileMode::Read);
        string fileContents = originalFile.ReadToEnd();
        originalFile.Close();*/

        string fileContents = _IO::File::ReadFileToEnd(originalPath);

        _IO::Folder::SafeCreateFolder(_IO::File::StripFileNameFromFilePath(storagePath), true);

        _IO::File::WriteToFile(storagePath, fileContents);
        /*IO::File targetFile;
        targetFile.Open(storagePath, IO::FileMode::Write);
        targetFile.Write(fileContents);
        targetFile.Close();*/

        if (verbose) log("Finished moving the file", LogLevel::Info, 672, "SafeMoveFileToNonSource");
    }

    namespace DLL {
        Import::Library@ g_lib;
        Import::Function@ g_getFileCreationTimeFunc;

        bool loadLibrary() {
            if (g_lib is null) {
                string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
                @g_lib = Import::GetLibrary(dllPath);
                if (g_lib is null) {
                    log("Failed to load DLL: " + dllPath, LogLevel::Error, 684, "loadLibrary");
                    return false;
                }
            }

            if (g_getFileCreationTimeFunc is null) {
                @g_getFileCreationTimeFunc = g_lib.GetFunction("GetFileCreationTime");
                if (g_getFileCreationTimeFunc is null) {
                    log("Failed to get function from DLL.", LogLevel::Error, 692, "loadLibrary");
                    return false;
                }
                g_getFileCreationTimeFunc.SetConvention(Import::CallConvention::cdecl);
            }
            return true;
        }

        int64 FileCreatedTime(const string &in filePath) {
            if (!loadLibrary()) { return -301; }
            int64 result = g_getFileCreationTimeFunc.CallInt64(filePath);
            return result;
        }

        void UnloadLibrary() {
            @g_lib = null;
            @g_getFileCreationTimeFunc = null;
        }
    }

    int64 FileCreatedTime(const string &in filePath) {
        log("Attempting to retrieve file creation time for: " + filePath, LogLevel::Info, 713, "FileCreatedTime");

        if (!DLL::loadLibrary()) {
            log("Failed to load library for file creation time retrieval.", LogLevel::Error, 716, "FileCreatedTime");
            return -300;
        }

        int64 result = DLL::FileCreatedTime(filePath);
        if (result < 0) {
            log("Error retrieving file creation time. Code: " + result, LogLevel::Warn, 722, "FileCreatedTime");
        } else {
            log("File creation time retrieved successfully: " + result, LogLevel::Info, 724, "FileCreatedTime");
        }
        return result;
    }
}