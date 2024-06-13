void Render() {
    if (_IO::FileExplorer::showInterface) {
        _IO::FileExplorer::ShowFileDialog();
    }
}

namespace _IO {
    namespace FileExplorer {
        bool ShowOnlyFiles = false;
        bool ShowOnlyFolders = false;
        bool FilterFileType = false;

        string FileTypeFilter = "";

        string currentDir = "";
        array<string> dirHistory;

        string currentSelectedElement = "";
        string selectedElementPath = "";
        string selectedFileName = "";

        enum Sorting { Name, Date, Type, Size };
        Sorting sorting = Sorting::Type;

        enum DirectoryOption { None, Storage, Data, App, UserGame }
        DirectoryOption currentDirectoryOption = DirectoryOption::None;

        bool ShouldShow_ICON = true;
        bool ShouldShow_FileOrFolderName = true;
        bool ShouldShow_LastChangedDate = true;
        bool ShouldShow_FileType = true;
        bool ShouldShow_Size = true;
        bool ShouldShow_CreationDate = true;

        uint currentPage = 0;
        uint itemsPerPage = 100;

        bool showInterface = false;

        array<FileInfo> fileInfos;
        string lastCheckedDir = "";
        
        namespace FileDialogWindow_FileName {
            string GetFileName() {
                return currentSelectedElement;
            }
        }
        void OpenFileExplorerWindow(const string &in fileExplorerStartingDirectory = IO::FromAppFolder("")) {
            currentDir = fileExplorerStartingDirectory;
            showInterface = true;
        }

        class FileInfo {
            string name;
            bool isFolder;
            string lastChangedDate;
            string size;
            string creationDate;

            int clickCount = 0;
        }

        void ShowFileDialog() {
            if (UI::Begin("File Dialog", showInterface, UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoCollapse)) {
                if (UI::Button("Up One Level") && currentDir.Length > 0) {
                    int posSlash = _Text::LastIndexOf(currentDir, "/");
                    int posBackslash = _Text::LastIndexOf(currentDir, "\\");
                    int pos = Math::Max(posSlash, posBackslash);
                    if (pos != -1) {
                        string newDir = currentDir.SubStr(0, pos);
                        dirHistory.InsertLast(currentDir);
                        currentDir = newDir;
                    }
                    currentPage = 0;
                }
                UI::SameLine();
                if (UI::Button("Back to Previous Directory") && dirHistory.Length > 0) {
                    currentDir = dirHistory[dirHistory.Length - 1];
                    dirHistory.RemoveLast();
                    currentPage = 0;
                }
                UI::SameLine();
                ShowOnlyFiles = UI::Checkbox("Show Only Files", ShowOnlyFiles);
                UI::SameLine();
                ShowOnlyFolders = UI::Checkbox("Show Only Folders", ShowOnlyFolders);
                UI::SameLine();
                if (UI::Button("Set Path to Current Directory")) {
                    if (IsDirectory(currentSelectedElement)) { currentDir = currentSelectedElement; }
                    else { NotifyWarn("Cannot set the current directory a file path, it has to be a folder"); }
                }

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
                    // showAddedInterface = true; // Should show a new window that says: Added Ghost, this should show for 3 seconds
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

                array<string> elements = Hidden::GetFilesForCurrentPage();
                if (elements.IsEmpty()) {
                    UI::Text("No elements in this directory.");
                } else {
                    if (fileInfos.Length != elements.Length) {
                        fileInfos.Resize(elements.Length);
                    }

                    for (uint i = 0; i < elements.Length; i++) {
                        string path = elements[i];

                        bool isFolder = _IO::IsDirectory(path);
            
            if (fileInfos[i].name != elements[i]) {
                fileInfos[i].name = elements[i];
                fileInfos[i].isFolder = isFolder;
                fileInfos[i].lastChangedDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                fileInfos[i].size = isFolder ? "-" : Hidden::FormatSize(IO::FileSize(path));
                fileInfos[i].creationDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                fileInfos[i].clickCount = 0;
            }
                    }
                    Hidden::SortFileInfos(fileInfos, sorting);

                    for (uint i = 0; i < fileInfos.Length; i++) {
                        FileInfo info = fileInfos[i];
                        string path = elements[i];


                        UI::TableNextRow();
                        if (UI::TableSetColumnIndex(0) && ShouldShow_ICON) {
                            UI::Text(Hidden::GetFileIcon(info));
                        }
if (UI::TableSetColumnIndex(1) && ShouldShow_FileOrFolderName) {
    if (UI::Selectable(info.name, currentSelectedElement == info.name)) {
        info.clickCount++;
        if (info.clickCount == 2 && info.isFolder) {
            dirHistory.InsertLast(currentDir);
            currentDir = elements[i];
            currentPage = 0;
            info.clickCount = 0;
        }
        currentSelectedElement = info.name;
        selectedElementPath = elements[i];
    }
}
                        if (UI::TableSetColumnIndex(2) && ShouldShow_LastChangedDate) {
                            UI::Text(info.lastChangedDate);
                        }
                        if (UI::TableSetColumnIndex(3) && ShouldShow_FileType) {
                            UI::Text(info.isFolder ? "Folder" : "File");
                        }
                        if (UI::TableSetColumnIndex(4) && ShouldShow_Size) {
                            UI::Text(info.size);
                        }
                        if (UI::TableSetColumnIndex(5) && ShouldShow_CreationDate) {
                            UI::Text(info.creationDate);
                        }
                    }
                }
                UI::EndTable();
            }
        }

        namespace Hidden {
            array<string> GetFilesForCurrentPage() {
                string sanetized_CurrentDir = currentDir;

                if (currentDir.EndsWith("/") || currentDir.EndsWith("\\")) {
                    sanetized_CurrentDir = currentDir.SubStr(0, currentDir.Length - 1);
                }

                array<string> allItems = IO::IndexFolder(sanetized_CurrentDir, false);
                array<string> pageItems;
                uint start = currentPage * itemsPerPage;
                uint end = start + itemsPerPage < allItems.Length ? start + itemsPerPage : allItems.Length;

                for (uint i = start; i < end; i++) {
                    pageItems.InsertLast(allItems[i]);
                }
                return pageItems;
            }

            void UpdateFileInfos() {
                array<string> elements = Hidden::GetFilesForCurrentPage();
                fileInfos.Resize(elements.Length);

                for (uint i = 0; i < elements.Length; i++) {
                    string path = elements[i];
                    bool isFolder = _IO::IsDirectory(path);

                    fileInfos[i].name = elements[i];
                    fileInfos[i].isFolder = isFolder;
                    fileInfos[i].lastChangedDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                    fileInfos[i].size = isFolder ? "-" : Hidden::FormatSize(IO::FileSize(path));
                    fileInfos[i].creationDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                    fileInfos[i].clickCount = 0;
                }
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