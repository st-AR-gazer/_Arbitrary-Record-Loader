namespace _UI {
    bool ShowOnlyFiles = false;
    bool ShowOnlyFolders = false;
    enum Sorting { Name, Date, Type, Size };
    Sorting sorting = Sorting::Name;
    bool FilterFileType = false;
    string FileTypeFilter = "";
    string currentDir = IO::FromStorageFolder("");
    string currentSelectedFile = "";

    enum DirectoryOption { None, Storage, Data, App, UserGame }
    DirectoryOption currentDirectoryOption = DirectoryOption::None;

    bool ShouldShow_ICON = true;
    bool ShouldShow_FileOrFolderName = true;
    bool ShouldShow_LastChangedDate = true;
    bool ShouldShow_FileType = true;
    bool ShouldShow_Size = true;
    bool ShouldShow_CreationDate = true;

    void OpenFileDialogWindow() {
        if (UI::Begin("File Dialog")) {
            UI::Checkbox("Show Only Files", ShowOnlyFiles);
            UI::Checkbox("Show Only Folders", ShowOnlyFolders);

            if (UI::BeginCombo("Sorting", GetSortingName(sorting), UI::ComboFlags::HeightRegular)) {
                if (UI::Selectable("Name", sorting == Sorting::Name)) sorting = Sorting::Name;
                if (UI::Selectable("Date", sorting == Sorting::Date)) sorting = Sorting::Date;
                if (UI::Selectable("Type", sorting == Sorting::Type)) sorting = Sorting::Type;
                if (UI::Selectable("Size", sorting == Sorting::Size)) sorting = Sorting::Size;
                UI::EndCombo();
            }

            if (UI::BeginCombo("Directory", GetDirectoryName(currentDirectoryOption), UI::ComboFlags::HeightRegular)) {
                if (UI::Selectable("Storage", currentDirectoryOption == DirectoryOption::Storage)) SetCurrentDirectory(DirectoryOption::Storage);
                if (UI::Selectable("Data", currentDirectoryOption == DirectoryOption::Data)) SetCurrentDirectory(DirectoryOption::Data);
                if (UI::Selectable("App", currentDirectoryOption == DirectoryOption::App)) SetCurrentDirectory(DirectoryOption::App);
                if (UI::Selectable("User Game", currentDirectoryOption == DirectoryOption::UserGame)) SetCurrentDirectory(DirectoryOption::UserGame);
                UI::EndCombo();
            }

            UI::Checkbox("Filter File Type", FilterFileType);
            if (FilterFileType) {
                FileTypeFilter = UI::InputText("File Type Filter", FileTypeFilter);
            }

            UI::Separator();
            
            if (UI::BeginTable("FileTable", 6, UI::TableFlags::Resizable | UI::TableFlags::Reorderable | UI::TableFlags::Hideable | UI::TableFlags::Sortable)) {
                UI::TableSetupColumn("ICON", UI::TableColumnFlags::WidthFixed, 40.0f);
                UI::TableSetupColumn("File / Folder Name");
                UI::TableSetupColumn("Last Change Date");
                UI::TableSetupColumn("Type");
                UI::TableSetupColumn("Size");
                UI::TableSetupColumn("Creation Date");
                UI::TableHeadersRow();

                array<string> items = IO::IndexFolder(currentDir, false);
                array<FileInfo> fileInfos;

                for (uint i = 0; i < items.Length; i++) {
                    string path = currentDir + "/" + items[i];
                    bool isFolder = IO::FolderExists(path);
                    if ((ShowOnlyFiles && isFolder) || (ShowOnlyFolders && !isFolder)) {
                        continue;
                    }
                    if (FilterFileType && !isFolder && !items[i].ToLower().EndsWith(FileTypeFilter.ToLower())) {
                        continue;
                    }

                    FileInfo info;
                    info.name = items[i];
                    info.isFolder = isFolder;
                    info.lastChangedDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                    info.size = isFolder ? "-" : FormatSize(IO::FileSize(path));
                    info.creationDate = Time::FormatString("%Y-%m-%d %H:%M:%S", IO::FileModifiedTime(path));
                    fileInfos.InsertLast(info);
                }

                SortFileInfos(fileInfos, sorting);

                for (uint i = 0; i < fileInfos.Length; i++) {
                    FileInfo info = fileInfos[i];
                    UI::TableNextRow();
                    if (UI::TableSetColumnIndex(0) && ShouldShow_ICON) {
                        UI::Text(GetFileIcon(info));
                    }
                    if (UI::TableSetColumnIndex(1) && ShouldShow_FileOrFolderName) {
                        UI::Text(info.name);
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

                UI::EndTable();
            }

            UI::Separator();
            currentDir = UI::InputText("Current Directory", currentDir);
            currentSelectedFile = UI::InputText("Current Selected File", currentSelectedFile);

            if (UI::Button("Copy File Path")) {
                CopyToClipboard(currentDir + "/" + currentSelectedFile);
            }

            UI::End();
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
            return (info.name == currentSelectedFile) ? Icons::FolderOpenO : Icons::FolderO;
        }

        // yes all of them are very nessesary :xdd:
        string ext = _IO::GetFileExtension(info.name).ToLower();
        if (ext == "txt" || ext == "rtf" || ext == "csv" || ext == "json") return Icons::FileTextO;
        return Icons::FileO;
    }

    void SortFileInfos(array<FileInfo>@ fileInfos, Sorting sorting) {
        for (uint i = 0; i < fileInfos.Length - 1; i++) {
            for (uint j = i + 1; j < fileInfos.Length; j++) {
                bool swap = false;
                switch (sorting) {
                    case Sorting::Name:
                        swap = fileInfos[i].name > fileInfos[j].name;
                        break;
                    case Sorting::Date:
                        swap = fileInfos[i].lastChangedDate > fileInfos[j].lastChangedDate;
                        break;
                    case Sorting::Type:
                        swap = fileInfos[i].isFolder > fileInfos[j].isFolder;
                        break;
                    case Sorting::Size:
                        swap = fileInfos[i].size > fileInfos[j].size;
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

    class FileInfo {
        string name;
        bool isFolder;
        string lastChangedDate;
        string size;
        string creationDate;
    }
}
