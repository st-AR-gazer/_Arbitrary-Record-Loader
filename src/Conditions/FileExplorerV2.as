// :Yayy: FileExplorerV2 go brrrrr

/** 
 * IMPORTANT:
 * This file is meant to be used together with "logging.as" as this contains that logging functionality needed to make 
 * custom log messages work properly. If you do not want to include this, please ctrl + h (or ctrl + f and click the 
 * dropdown) and add ` log\(([^,]+),.*\); ` to find, and and ` print($1); ` to replace, this will convert all the fancy 
 * log messages to normal print messages. You must also enable 'regex search' for this to work. (In vscode this can be 
 * done by pressing ctrl + f and selecting the |.*| icon in the search bar)
 */

/**
 * How to Integrate and Use the FileExplorer:
 * 
 * To integrate the FileExplorer into your plugin, follow the steps below:
 * 
 * 1. **Include the FileExplorer Script:**
 *    Add the FileExplorer script file to your plugin's folder. This script will handle all the file exploration 
 *    functionalities required in your plugin.
 * 
 * 2. **Render the FileExplorer:**
 *    To ensure the FileExplorer renders correctly, you must add the `FILE_EXPLORER_BASE_RENDERER()` function to your 
 *    plugin's main render loop. This function should be included in either the `Render()` or `RenderInterface()` 
 *    method of your plugin.
 *    
 *    Example:
 *    ```angelscript
 *    void RenderInterface() {
 *        FILE_EXPLORER_BASE_RENDERER();  // This ensures the FileExplorer is rendered properly.
 *    }
 *    ```
 * 
 * 3. **Open the FileExplorer:**
 *    To display the FileExplorer UI and allow users to select files, you should call the `FileExplorer::fe_Start()` 
 *    function. This function configures and opens the FileExplorer based on the parameters you provide.
 *    
 *    Example:
 *    ```angelscript
 *    void OpenFileExplorerExample() {
 *        FileExplorer::fe_Start(
 *            true,                               // _mustReturn: Require the user to select and return files.
 *            vec2(1, 99999),                     // _minmaxReturnAmount: Minimum and maximum number of files to return.
 *            IO::FromUserGameFolder("Replays/"), // _path: The initial folder path to open.
 *            "",                                 // _searchQuery: Optional search query to filter files.
 *            { "replay" }                        // _filters: File type filters (e.g., "replay" to show only replay files).
 *        );
 *    }
 *    ```
 *    This example opens the FileExplorer in the "Replays/" folder and filters to show only replay files.
 *    
 *    **Note:** The FileExplorer will close itself automatically when the user has selected the required files and 
 *    clicks the "Return Selected Paths" button.
 * 
 * 4. **Handle KeyPresses:**
 *    The FileExplorer requires certain key press events to function correctly. If your plugin uses key press 
 *    functionality, you must integrate the `FILE_EXPLORER_KEYPRESS_HANDLER()` into your `OnKeyPress()` function. 
 *    This ensures that the FileExplorer can detect and respond to key presses.
 *    
 *    Example:
 *    ```angelscript
 *    void OnKeyPress(bool down, VirtualKey key) {
 *        FILE_EXPLORER_KEYPRESS_HANDLER(down, key);  // Ensures FileExplorer handles key presses.
 *        // Add your own key handling logic here if needed.
 *    }
 *    ```
 * 
 * 5. **Retrieve Selected File Paths:**
 *    Once the user has selected files and clicked "Return Selected Paths," you can retrieve the selected file paths 
 *    from `FileExplorer::exports.GetSelectedPaths()` in your plugin's main loop or event handler.
 *    
 *    Example:
 *    ```angelscript
 *    void MonitorFileExplorerSelection() {
 *        if (FileExplorer::exports.IsSelectionComplete()) {
 *            array<string> selectedPaths = FileExplorer::exports.GetSelectedPaths();
 *            // Handle the selected file paths here.
 *            for (uint i = 0; i < selectedPaths.Length; i++) {
 *                print("Selected Path: " + selectedPaths[i]);
 *            }
 *        }
 *    }
 *    ```
 *    This function checks if the selection process is complete and then processes the selected file paths.
 * 
 * **Summary:**
 * - **Rendering:** Add `FILE_EXPLORER_BASE_RENDERER()` to your `Render()` or `RenderInterface()` method.
 * - **Opening:** Use `FileExplorer::fe_Start()` to open the FileExplorer.
 * - **KeyPress Handling:** Integrate `FILE_EXPLORER_KEYPRESS_HANDLER()` into your `OnKeyPress()` function.
 * - **File Selection:** Retrieve the selected paths using `FileExplorer::exports.GetSelectedPaths()` after the user 
 *   has made their selection.
 * 
 * With these steps, the FileExplorer will be fully integrated into your plugin, and it should allow users easily 
 * navigate directories and select and return different paths with relative ease files.
 */


/*
    TODO: 
        - Add support for multiple tabs (not planned)

        - Add pagination

        - Add support for multiple file return
            - Add support for multiple file selection (should maybe be it's own point?)
            - Keep track of selected files in a UI element (maybe on the left side under the pin bar)
            - Add a button to return all selected files (shuold be optional from the OpenFileExplorer function)
            - Returning should happen in the 3rd row of the UI. (this should open based on the inputs in 
              OpenFileExplorer function)
        
        - Add support for returning paths in general

        - Add three main areas to the left UI.
            1. Hardcoded paths, e.g same as home, desktop, documents, downloads, etc, but TM related so it would be
               like Maps, Replays, Openplanet, StorageFolder, GameFolder etc.
            2. Pinned items, items that the user has have pinned from the main area, should be displayed in the second 
               area in the left UI.
            3. Selected items, items that the user has selected from the main area, should be displayed in the third
               area in the left UI.

        - Add a custom location for settings so that the user can set custom PINs, and so that they are enabled cross 
          sessions and plugins.

        - Add minmaxreturnamount as somthing that limits the amount of returnable elementes.


    FIXME: 
        - GBX parsing currently only works for .Replay.Gbx files, this should work for all GBX files 
          (only .replay .map and .challenge should be supported)

        - Recursive search is not fully working as intended, it is very hard to explain what is wrong, but it's just 
          not working as intended, it needs to be looked into more. Normal search works just fine though.
          (recursive search is also not in a coroutine)

        - KeyPresses for "Left mouse button" and "Right mouse button" do not work, this is needed for the context menu
          to work.
            - As a makeshift solution I have set left mouse button to always be true as a click is still needed for other 
              reasons, but the same cannot be done for right clicking...

        - Add Renaming functionality
            - this is 99% done, I just need miss to add IO::Rename(path, name) and IO::RenameFolder(path, name) to Openplanet, 
              then this can be added to the FileExplorer. (:Prayge: she does)
            - UPDATE: Renaming will probably not be added, but Move() can be used as a rename, Move can take a path and a target
              so 'renaming' should be possible by moving the file/folder to the same locatoin, but changing the name.

    
    WAIT NEEDED:
        - Add FileCreatedTime properly using an OP method.

*/
namespace FileExplorer {
    bool showInterface = false;
    FileExplorer@ explorer;

    class Config {
        bool MustReturn;
        vec2 MinMaxReturnAmount;

        string Path;
        string SearchQuery;
        array<string> Filters;
        bool RenderFlag;
        array<string> SelectedPaths;
        bool HideFiles = false;
        bool HideFolders = false;
        bool EnablePagination = false;
        dictionary columsToShow;
        int FileNameDisplayOption = 0; // 0: Default, 1: No Formatting, 2: ManiaPlanet Formatting
        bool RecursiveSearch = false;

        Config() {
            MustReturn = false;
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
        bool selectionComplete = false;
        array<string> selectedPaths;

        void SetSelectionComplete(array<string>@ paths) {
            selectedPaths = paths;
            selectionComplete = true;
        }

        bool IsSelectionComplete() {
            return selectionComplete;
        }

        array<string>@ GetSelectedPaths() {
            selectionComplete = false;
            return selectedPaths;
        }
        
        // void MarkSelectionComplete() {
        //     selectionComplete = true;
        // }
    }

    class ElementInfo {
        string Name;
        string Path;
        string Size;
        string Type;
        int64 LastModifiedDate;
        int64 CreationDate;
        bool IsFolder;
        Icon Icon;
        bool IsSelected;
        uint64 LastSelectedTime;
        dictionary GbxMetadata;
        bool shouldShow;

        uint64 LastClickTime;

        ElementInfo(const string &in name, const string &in path, string size, const string &in type, int64 lastModifiedDate, int64 creationDate, bool isFolder, Icon icon, bool isSelected) {
            this.Name = name;
            this.Path = path;
            this.Size = size;
            this.Type = type;
            this.LastModifiedDate = lastModifiedDate;
            this.CreationDate = lastModifiedDate; // Placeholder for actual creation date
            this.IsFolder = isFolder;
            this.Icon = icon;
            this.IsSelected = isSelected;
            this.LastSelectedTime = 0;
            this.shouldShow = true;
            this.LastClickTime = 0;
        }

        void SetGbxMetadata(dictionary@ metadata) {
            GbxMetadata = metadata;
        }
    }


    class Navigation {
        string CurrentPath;
        FileExplorer@ explorer;

        Navigation(FileExplorer@ fe) {
            @explorer = fe;
            CurrentPath = fe.Config.Path;
        }

        void SetPath(const string &in path) {
            CurrentPath = path;
        }

        string GetPath() {
            return CurrentPath;
        }

        bool IsInRootDirectory() {
            return CurrentPath == "/" || CurrentPath == "\\";
        }

        void MoveUpOneDirectory() {
            string path = explorer.tab[0].Navigation.GetPath();
            log("Current path before moving up: " + path, LogLevel::Info, 184, "MoveUpOneDirectory");

            UpdateHistory(path);

            if (path.EndsWith("/") || path.EndsWith("\\")) {
                path = path.SubStr(0, path.Length - 1);
            }
            
            int lastSlash = Math::Max(_Text::LastIndexOf(path, "/"), _Text::LastIndexOf(path, "\\"));
            if (lastSlash > 0) {
                path = path.SubStr(0, lastSlash);
            } else {
                path = "/";
            }

            if (!path.EndsWith("/") && !path.EndsWith("\\")) {
                path += "/";
            }

            log("New path after moving up: " + path, LogLevel::Info, 203, "MoveUpOneDirectory");

            explorer.tab[0].LoadDirectory(path);
        }

        void MoveIntoSelectedDirectory() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null && selectedElement.IsFolder) {
                UpdateHistory(selectedElement.Path);
                explorer.tab[0].LoadDirectory(selectedElement.Path);
            } else {
                log("No folder selected or selected element is not a folder.", LogLevel::Warn, 214, "MoveIntoSelectedDirectory");
            }
        }

        bool CanMoveUpDirectory() {
            string path = explorer.tab[0].Navigation.GetPath();
            if (IsInRootDirectory() || path == "" || path.Length == 3) { return false; }
                                                     // Used since C:/ D:/ E:/ etc. is three characteres long
            return true;
        }

        // History management
        array<string> History;
        int HistoryIndex = -1;
        bool NavigatingHistory = false;

        void UpdateHistory(const string &in path) {
            if (!NavigatingHistory && path != "") {
                if (HistoryIndex == -1 || History[HistoryIndex] != path) {
                    if (HistoryIndex < int(History.Length) - 1) {
                        History.Resize(HistoryIndex + 1);
                    }
                    History.InsertLast(path);
                    HistoryIndex = History.Length - 1;
                }
            }
            NavigatingHistory = false;
        }

        void NavigateBack() {
            if (HistoryIndex > 0) {
                NavigatingHistory = true;
                HistoryIndex--;
                string path = History[HistoryIndex];
                explorer.tab[0].LoadDirectory(path);
            }
        }

        void NavigateForward() {
            if (HistoryIndex < int(History.Length) - 1) {
                NavigatingHistory = true;
                HistoryIndex++;
                string path = History[HistoryIndex];
                explorer.tab[0].LoadDirectory(path);
            }
        }
    }

    class FileTab {
        uint currentSelectedTab = 0; // Decided to only go with one tab for now, but might add more in the future...

        Navigation@ Navigation;
        array<ElementInfo@> Elements;
        Config@ Config;
        FileExplorer@ explorer;
        uint SelectedElementIndex;

        FileTab(Config@ cfg, FileExplorer@ fe) {
            @Config = cfg;
            @explorer = fe;
            @Navigation = fe.nav;
            
            LoadDirectory(Config.Path);
        }

        void LoadDirectory(const string &in path) {
            explorer.nav.UpdateHistory(path);
            explorer.nav.SetPath(path);

            StartIndexingFiles(path);
        }

        void StartIndexingFiles(const string &in path) {
            explorer.IsIndexing = true;
            explorer.IndexingMessage = "Folder is being indexed...";
            explorer.CurrentIndexingPath = path;
            startnew(CoroutineFuncUserdata(IndexFilesCoroutine), this);
        }

        // FIXME: Search currently only updates if you refresh the directory, it should update on the fly
        // FIXME: Recursive is also a bit weird, will need to look into this tomorrow...
        // TODO: Integrate this coroutine loading into the main explorer coroutine loading to avoid duplicate code (this works for now tho)

        void IndexFilesCoroutine(ref@ r) {
            FileTab@ tab = cast<FileTab@>(r);
            if (tab is null) return;

            tab.Elements.Resize(0);
            tab.explorer.IndexingMessage = "Folder is being indexed...";
            log("Indexing started for path: " + tab.Navigation.GetPath(), LogLevel::Info, 303, "IndexFilesCoroutine");

            array<string> elements = tab.explorer.GetFiles(tab.Navigation.GetPath(), tab.Config.RecursiveSearch);

            if (elements.Length == 0) {
                log("No files found in directory: " + tab.Navigation.GetPath(), LogLevel::Info, 308, "IndexFilesCoroutine");
            }

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

                    ElementInfo@ elementInfo = tab.explorer.GetElementInfo(path);
                    if (elementInfo !is null) {
                        tab.Elements.InsertLast(elementInfo);
                    }
                }

                processedFiles = end;
                tab.explorer.IndexingMessage = "Indexing element " + processedFiles + " out of " + totalFiles;
                log(tab.explorer.IndexingMessage, LogLevel::Info, 331, "IndexFilesCoroutine");
                yield();
            }

            tab.ApplyFiltersAndSearch();
            tab.ApplyVisibilitySettings();
            tab.explorer.IsIndexing = false;

            log("Indexing completed. Number of elements: " + tab.Elements.Length, LogLevel::Info, 339, "IndexFilesCoroutine");
        }

        void ApplyFiltersAndSearch() {
            if (explorer.Config.RecursiveSearch) {
                ApplyRecursiveSearch();
            } else {
                ApplyNonRecursiveSearch();
            }

            ApplyFilters();
        }

        void ApplyNonRecursiveSearch() {
            array<ElementInfo@> tempElements = Elements;
            Elements.Resize(0);

            for (uint i = 0; i < tempElements.Length; i++) {
                if (Config.SearchQuery == "" || tempElements[i].Name.ToLower().Contains(Config.SearchQuery.ToLower())) {
                    Elements.InsertLast(tempElements[i]);
                }
            }
        }

        void ApplyRecursiveSearch() {
            array<ElementInfo@> tempElements = LoadAllElementsRecursively(Navigation.GetPath());
            Elements.Resize(0);

            for (uint i = 0; i < tempElements.Length; i++) {
                if (Config.SearchQuery == "" || tempElements[i].Name.ToLower().Contains(Config.SearchQuery.ToLower())) {
                    Elements.InsertLast(tempElements[i]);
                }
            }
        }

        array<ElementInfo@> LoadAllElementsRecursively(const string &in path) {
            array<ElementInfo@> elementList;
            array<string> elementNames = explorer.GetFiles(path, true);
            for (uint i = 0; i < elementNames.Length; i++) {
                ElementInfo@ elementInfo = explorer.GetElementInfo(elementNames[i]);
                if (elementInfo !is null) {
                    elementList.InsertLast(elementInfo);
                }
                if (elementInfo.IsFolder) {
                    array<ElementInfo@> subElements = LoadAllElementsRecursively(elementInfo.Path);
                    for (uint j = 0; j < subElements.Length; j++) {
                        elementList.InsertLast(subElements[j]);
                    }
                }
            }
            return elementList;
        }

        void ApplyFilters() {
            for (uint i = 0; i < Elements.Length; i++) {
                ElementInfo@ element = Elements[i];
                element.shouldShow = true;

                if (Config.Filters.Length > 0 && !element.IsFolder) {
                    bool found = false;
                    for (uint j = 0; j < Config.Filters.Length; j++) {
                        if (element.Type.ToLower() == Config.Filters[j].ToLower()) {
                            found = true;
                            break;
                        } else if (Config.Filters[j].ToLower() == "replay" && element.Path.ToLower().Contains(".replay.gbx")) {
                            found = true;
                            break;
                        }
                    }
                    element.shouldShow = found;
                }
            }
        }

        void ApplyVisibilitySettings() {
            for (uint i = 0; i < Elements.Length; i++) {
                ElementInfo@ element = Elements[i];
                if (Config.HideFiles && !element.IsFolder) {
                    element.shouldShow = false;
                }
                if (Config.HideFolders && element.IsFolder) {
                    element.shouldShow = false;
                }
            }
        }

        ElementInfo@ GetSelectedElement() {
            for (uint i = 0; i < Elements.Length; i++) {
                if (Elements[i].IsSelected) {
                    return Elements[i];
                }
            }
            return null;
        }
    }

    class Utils {
        FileExplorer@ explorer;

        Utils(FileExplorer@ fe) {
            @explorer = fe;
        }

        void RefreshCurrentDirectory() {
            string currentPath = explorer.tab[0].Navigation.GetPath();
            log("Refreshing directory: " + currentPath, LogLevel::Info, 444, "RefreshCurrentDirectory");
            explorer.tab[0].LoadDirectory(currentPath);
        }

        void OpenSelectedFolderInNativeFileExplorer() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null && selectedElement.IsFolder) {
                log("Opening folder: " + selectedElement.Path, LogLevel::Info, 451, "OpenSelectedFolderInNativeFileExplorer");
                _IO::OpenFolder(selectedElement.Path);
            } else {
                log("No folder selected or selected element is not a folder.", LogLevel::Error, 454, "OpenSelectedFolderInNativeFileExplorer");
            }
        }

        void OpenCurrentFolderInNativeFileExplorer() {
            string currentPath = explorer.tab[0].Navigation.GetPath();
            log("Opening folder: " + currentPath, LogLevel::Info, 460, "OpenCurrentFolderInNativeFileExplorer");
            _IO::OpenFolder(currentPath);
        }

        bool IsItemSelected() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            return selectedElement !is null;
        }

        bool RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
        void DeleteSelectedElement() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null) {
                if (selectedElement.IsFolder) {
                    array<string> folderContents = IO::IndexFolder(selectedElement.Path, false);
                    if (folderContents.Length > 0) {
                        explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = true;
                    } else {
                        log("Deleting empty folder: " + selectedElement.Path, LogLevel::Info, 473, "DeleteSelectedElement");
                        IO::DeleteFolder(selectedElement.Path);
                        explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    }
                } else {
                    log("Deleting file: " + selectedElement.Path, LogLevel::Info, 476, "DeleteSelectedElement");
                    IO::Delete(selectedElement.Path);
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
            }
        }

        bool RENDER_RENAME_POPUP_FLAG;
            void RenameSelectedElement(const string &in newFileName) {
                ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
                if (selectedElement !is null) {
                    log("Renaming element: " + selectedElement.Path + " to " + newFileName, LogLevel::Info, 487, "RenameSelectedElement");

                    string oldPath = selectedElement.Path;
                    string parentDirectory = _IO::Folder::GetFolderPath(oldPath);
                    string newFilePath = parentDirectory + newFileName;

                    if (selectedElement.IsFolder) {
                        // Waiting for miss to add this to Openplanet
                        // IO::RenameFolder(oldPath, newFileName);
                    } else {
                        // IO::Rename(oldPath, newFileName);
                    }

                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
            }

        void PinSelectedElement() {
            ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();
            if (selectedElement !is null) {
                log("Pinning element: " + selectedElement.Path, LogLevel::Info, 502, "PinSelectedElement");
                explorer.PinnedItems.InsertLast(selectedElement.Path);
            }
        }
    }

    class FileExplorer {
        KeyPresses@ keyPress;

        array<FileTab@> tab;
        Config@ Config;
        array<string> PinnedItems;
        UserInterface@ ui;
        Utils@ utils;
        Exports@ exports;
        Navigation@ nav;

        bool IsIndexing = false;
        string IndexingMessage = "";
        array<ElementInfo@> CurrentElements;
        string CurrentIndexingPath;

        ElementInfo@ CurrentSelectedElement;

        FileExplorer(Config@ cfg) {
            @keyPress = KeyPresses();

            @Config = cfg;
            @nav = Navigation(this);
            tab.Resize(1);
            @tab[0] = FileTab(cfg, this);
            @ui = UserInterface(this);
            @utils = Utils(this);
            @exports = Exports();

            @CurrentSelectedElement = null;

            nav.UpdateHistory(cfg.Path);
        }

        void UpdateCurrentSelectedElement() {
            @CurrentSelectedElement = tab[0].GetSelectedElement();
        }

        void Open(Config@ config) {
            @Config = config;

            nav.SetPath(Config.Path);
            StartIndexingFiles(Config.Path);
            
            showInterface = true;
            explorer.exports.selectionComplete = false;
        }

        void StartIndexingFiles(const string &in path) {
            IsIndexing = true;
            IndexingMessage = "Folder is being indexed...";
            CurrentIndexingPath = path;
            tab[0].StartIndexingFiles(path);
        }

        array<string> GetFiles(const string &in path, bool recursive) {
            return IO::IndexFolder(path, recursive);
        }

        ElementInfo@ GetElementInfo(const string &in path) {
            bool isFolder = _IO::Folder::IsDirectory(path);
            string name = isFolder ? _IO::Folder::GetFolderName(path) : _IO::File::GetFileName(path);
            string type = isFolder ? "folder" : _IO::File::GetFileExtension(path);
            string size = isFolder ? "-" : ConvertFileSizeToString(IO::FileSize(path));
            int64 lastModified = IO::FileModifiedTime(path);
            int64 creationDate = lastModified; // Placeholder for actual creation date
            Icon icon = GetElementIcon(isFolder, type);
            ElementInfo@ elementInfo = ElementInfo(name, path, size, type, lastModified, creationDate, isFolder, icon, false);

            if (type.ToLower() == "gbx") {
                dictionary gbxMetadata = ReadGbxHeader(path);
                elementInfo.SetGbxMetadata(gbxMetadata);
            }
            return elementInfo;
        }

        string ConvertFileSizeToString(uint64 size) {
            if (size < 1024) return size + " B";
            else if (size < 1024 * 1024) return (size / 1024) + " KB";
            else if (size < 1024 * 1024 * 1024) return (size / (1024 * 1024)) + " MB";
            else return (size / (1024 * 1024 * 1024)) + " GB";
        }

        Icon GetElementIcon(bool isFolder, const string &in type) {
            if (isFolder) return Icon::Folder;
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

            Render_Misc();
        }

        void Render_Misc() {
            Render_RenamePopup();
            Render_ElementContextMenu();
            Render_DeleteConfirmationPopup();
        }

        void Render_Rows() {
            Render_NavigationBar();
            Render_ActionBar();
            Render_ReturnBar();
        }

        void Render_Columns() {
            UI::BeginTable("FileExplorerTable", 3, UI::TableFlags::Resizable | UI::TableFlags::Borders);
            UI::TableNextColumn();
            Render_LeftSidebar();
            UI::TableNextColumn();
            Render_MainAreaBar();
            UI::TableNextColumn();
            Render_DetailBar();
            UI::EndTable();
        }

        void Render_NavigationBar() {
            if (explorer.tab[0].Navigation.HistoryIndex > 0) {
                if (UI::Button(Icons::ArrowLeft)) { explorer.tab[0].Navigation.NavigateBack(); }
            } else {
                _UI::DisabledButton(Icons::ArrowLeft);
            }
            UI::SameLine();
            if (explorer.tab[0].Navigation.HistoryIndex < int(explorer.tab[0].Navigation.History.Length) - 1) {
                if (UI::Button(Icons::ArrowRight)) { explorer.tab[0].Navigation.NavigateForward(); }
            } else {
                _UI::DisabledButton(Icons::ArrowRight);
            }
            UI::SameLine();
            if (explorer.tab[0].Navigation.CanMoveUpDirectory()) {
                if (UI::Button(Icons::ArrowUp)) { explorer.tab[0].Navigation.MoveUpOneDirectory(); }
            } else {
                _UI::DisabledButton(Icons::ArrowUp);
            }
            UI::SameLine();

            if (explorer.tab[0].Elements.Length > 0 && !explorer.tab[0].Elements[explorer.tab[0].SelectedElementIndex].IsFolder) {
                _UI::DisabledButton(Icons::ArrowDown); 
            } else if (explorer.tab[0].Elements.Length > 0) {
                if (UI::Button(Icons::ArrowDown)) { explorer.tab[0].Navigation.MoveIntoSelectedDirectory(); }
                UI::SameLine();
            } else {
                _UI::DisabledButton(Icons::ArrowDown);
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
            if (UI::Button(Icons::FolderOpen)) { explorer.utils.OpenCurrentFolderInNativeFileExplorer(); }
            UI::SameLine();
            if (!explorer.utils.IsItemSelected()) {
                _UI::DisabledButton(Icons::Trash); 
                UI::SameLine();
                _UI::DisabledButton(Icons::Pencil);
                UI::SameLine();
                _UI::DisabledButton(Icons::ThumbTack);
            } else {
                if (UI::Button(Icons::Trash)) { explorer.utils.DeleteSelectedElement(); }
                UI::SameLine();
                if (UI::Button(Icons::Pencil)) { explorer.utils.RENDER_RENAME_POPUP_FLAG = !explorer.utils.RENDER_RENAME_POPUP_FLAG; }
                UI::SameLine();
                if (UI::Button(Icons::ThumbTack)) { explorer.utils.PinSelectedElement(); }
            }
            UI::SameLine();
            if (UI::Button(Icons::Filter)) { UI::OpenPopup("filterMenu"); }

            if (UI::BeginPopup("filterMenu")) {
                UI::Text("All filters");
                UI::Separator();
                UI::Text("Add filter");
                newFilter = UI::InputText("New Filter", newFilter);
                if (UI::Button("Add")) {
                    explorer.Config.Filters.InsertLast(newFilter.ToLower());
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
                UI::Separator();
                UI::Text("Filter length: " + explorer.Config.Filters.Length);

                if (UI::Button("Remove All Filters")) {
                    explorer.Config.Filters.Resize(0);
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }

                for (uint i = 0; i < explorer.Config.Filters.Length; i++) {
                    string filter = explorer.Config.Filters[i];
                    if (UI::BeginMenu(filter)) {
                        // TODO: Add filter selection, you should be able to select a filter instead of just removing or adding a filter.
                        
                        // if (UI::MenuItem("Select Filter")) {
                        //     SelectFilter(filter);
                        // }
                        if (UI::MenuItem("Remove Filter")) {
                            explorer.Config.Filters.RemoveAt(i);
                            explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                            // FIXME: It currenly closes the popup regardless of it UI::CloseCurrentPopup(); is commented out or not
                            // UI::CloseCurrentPopup();
                        }
                        UI::EndMenu();
                    }
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
                if (UI::MenuItem("Recursive Search", "", explorer.Config.RecursiveSearch)) {
                    explorer.Config.RecursiveSearch = !explorer.Config.RecursiveSearch;
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
                UI::Separator();
                
                if (UI::BeginMenu("File Name Display Options")) {
                    if (UI::MenuItem("Default File Name", "", explorer.Config.FileNameDisplayOption == 0)) {
                        explorer.Config.FileNameDisplayOption = 0;
                    }
                    if (UI::MenuItem("No Formatting", "", explorer.Config.FileNameDisplayOption == 1)) {
                        explorer.Config.FileNameDisplayOption = 1;
                    }
                    if (UI::MenuItem("ManiaPlanet Formatting", "", explorer.Config.FileNameDisplayOption == 2)) {
                        explorer.Config.FileNameDisplayOption = 2;
                    }
                    UI::EndMenu();
                }
                
                UI::EndPopup();
            }
            UI::Separator();
        }

        string newFileName = "";
        void Render_RenamePopup() {
            // TODO: Will wait untill renaming is added to openplanet proper instead of adding a makeshift solution here..
            /*
            if (explorer.utils.RENDER_RENAME_POPUP_FLAG) {
                UI::OpenPopup("RenamePopup");
                explorer.ui.newFileName = explorer.ui.GetSelectedElement().Name;
            }

            if (UI::BeginPopupModal("RenamePopup", explorer.utils.RENDER_RENAME_POPUP_FLAG, UI::WindowFlags::AlwaysAutoResize)) {
                UI::Text("Rename Selected Element");
                UI::Separator();
                explorer.ui.newFileName = UI::InputText("New File Name", explorer.ui.newFileName);
                if (UI::Button("Rename")) {
                    explorer.utils.RenameSelectedElement(explorer.ui.newFileName);
                    explorer.utils.RENDER_RENAME_POPUP_FLAG = false;
                    UI::CloseCurrentPopup();
                }
                UI::SameLine();
                if (UI::Button("Cancel")) {
                    explorer.utils.RENDER_RENAME_POPUP_FLAG = false;
                    UI::CloseCurrentPopup();
                }
                UI::EndPopup();
            }
            */
        }

        void Render_DeleteConfirmationPopup() {
            if (explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG) {
                UI::OpenPopup("DeleteConfirmationPopup");
            }

            if (UI::BeginPopupModal("DeleteConfirmationPopup", explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG, UI::WindowFlags::AlwaysAutoResize)) {
                ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();

                UI::Text("Are you sure you want to delete this folder and all its contents?");
                UI::Separator();
                if (UI::Button("Yes, delete all")) {
                    if (selectedElement !is null && selectedElement.IsFolder) {
                        log("Deleting folder with contents: " + selectedElement.Path, LogLevel::Info, 487, "Render_DeleteConfirmationPopup");
                        IO::DeleteFolder(selectedElement.Path, true);
                        explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
                        explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    } else {
                        log("No selected element or element is not a folder.", LogLevel::Error, 491, "Render_DeleteConfirmationPopup");
                    }
                    UI::CloseCurrentPopup();
                }
                UI::SameLine();
                if (UI::Button("Cancel")) {
                    explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
                    UI::CloseCurrentPopup();
                }
                UI::EndPopup();
            }
        }


        void Render_ReturnBar() {
            if (explorer.Config.MustReturn) {
                UI::Separator();
                if (UI::Button("Return Selected Paths")) {
                    if (explorer.Config.SelectedPaths.Length >= explorer.Config.MinMaxReturnAmount.x &&
                        (explorer.Config.SelectedPaths.Length <= explorer.Config.MinMaxReturnAmount.y || explorer.Config.MinMaxReturnAmount.y == -1)) {
                        
                        explorer.exports.SetSelectionComplete(explorer.Config.SelectedPaths);
                        
                        explorer.exports.selectionComplete = true;
                        showInterface = false;
                    } else {
                        log("Selection count not within the required range.", LogLevel::Warn);
                    }
                }
            }
        }

        void Render_LeftSidebar() {
            UI::Text("Hardcoded Paths");
            UI::Separator();
            Render_HardcodedPaths();
            UI::Separator();

            UI::Text("Pinned Items");
            UI::Separator();
            Render_PinnedItems();
            UI::Separator();

            UI::Text("Selected Items");
            UI::Separator();
            Render_SelectedItems();
            UI::Separator();
        }

        void Render_HardcodedPaths() {
            if (UI::Selectable(Icons::Home + " Trackmania Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromUserGameFolder(""));
            }
            if (UI::Selectable(Icons::Map + " Trackmania Maps Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromUserGameFolder("Maps/"));
            }
            if (UI::Selectable(Icons::SnapchatGhost + " Trackmania Replays Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromUserGameFolder("Replays/"));
            }
            if (UI::Selectable(Icons::Trademark + " Trackmania App Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromAppFolder(""));
            }
            if (UI::Selectable(Icons::Heartbeat + " Openplanet Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromDataFolder(""));
            }
            if (UI::Selectable(Icons::Inbox + " Openplanet Storage Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromStorageFolder(""));
            }
            // if (UI::Selectable()) {
            //     explorer.tab[0].LoadDirectory();
            // }
        }

        void Render_PinnedItems() {
            for (uint i = 0; i < explorer.PinnedItems.Length; i++) {
                if (UI::Selectable(explorer.PinnedItems[i], false)) {
                    explorer.tab[0].LoadDirectory(explorer.PinnedItems[i]);
                }
            }
        }

        void Render_SelectedItems() {
            for (uint i = 0; i < explorer.Config.SelectedPaths.Length; i++) {
                string path = explorer.Config.SelectedPaths[i];
                if (_IO::Folder::IsDirectory(path)) {
                    UI::Text(_IO::Folder::GetFolderName(path));
                } else {
                    UI::Text(_IO::File::GetFileNameWithoutExtension(path));
                }
            }
        }

        void Render_MainAreaBar() {
            if (explorer.IsIndexing) {
                UI::Text(explorer.IndexingMessage);
            } else if (explorer.tab[0].Elements.Length == 0) {
                UI::Text("No elements to display.");
                log("No elements found in the directory.", LogLevel::Warn, 904, "Render_MainAreaBar");
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

                    UI::TableNextRow();
                    UI::TableSetColumnIndex(0);
                    UI::Text(explorer.GetElementIconString(element.Icon, element.IsSelected));
                    UI::TableSetColumnIndex(1);

                    string displayName;
                    switch (explorer.Config.FileNameDisplayOption) {
                        case 1:
                            displayName = Text::StripFormatCodes(element.Name);
                            break;
                        case 2:
                            displayName = element.Name.Replace("$", "\\$");
                            break;
                        default:
                            displayName = element.Name;
                    }

                    if (UI::Selectable(displayName, element.IsSelected)) {
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

        bool openContextMenu = false;

        void HandleElementSelection(ElementInfo@ element) {
            uint64 currentTime = Time::Now;
            const uint64 doubleClickThreshold = 600; // 0.6 seconds

            explorer.keyPress.isLMouseButtonPressed = true; // Shuold be kept for reason under

            // Should be kept til I figure out if VirtualKey::L/RButton is L and R mouse button
            // print("IsItemHovered " + UI::IsItemHovered());
            // print("is RMouse down " + explorer..isRMouseButtonPressed);
            // print("is LMouse down " + explorer..isLMouseButtonPressed);
            // print("is control down " + explorer..isControlPressed);

            // Control- / Right click check
            if (UI::IsItemHovered() && (explorer.keyPress.isRMouseButtonPressed || (explorer.keyPress.isLMouseButtonPressed && explorer.keyPress.isControlPressed))) {
                openContextMenu = true;
                explorer.UpdateCurrentSelectedElement();
            // Double click check
            } else if (element.IsSelected) {
                if (currentTime - element.LastClickTime <= doubleClickThreshold) {
                    if (element.IsFolder) {
                        explorer.tab[0].Navigation.MoveIntoSelectedDirectory();
                    } else {
                        if (explorer.Config.SelectedPaths.Find(element.Path) == -1) {
                            explorer.Config.SelectedPaths.InsertLast(element.Path);
                        }
                        explorer.UpdateCurrentSelectedElement();
                    }
                } else {
                    element.LastClickTime = currentTime;
                }
            // Normal click check
            } else {
                for (uint i = 0; i < explorer.tab[0].Elements.Length; i++) {
                    explorer.tab[0].Elements[i].IsSelected = false;
                }
                element.IsSelected = true;
                element.LastSelectedTime = currentTime;
                element.LastClickTime = currentTime;
                explorer.UpdateCurrentSelectedElement();
            }
        }

        void Render_ElementContextMenu() {
            if (openContextMenu) {
                UI::OpenPopup("ElementContextMenu");
                openContextMenu = false;
            }

            if (UI::BeginPopup("ElementContextMenu")) {
                ElementInfo@ element = explorer.ui.GetSelectedElement();
                if (element !is null) {
                    if (UI::MenuItem("Add to Selected Items")) {
                        if (explorer.Config.SelectedPaths.Find(element.Path) == -1) {
                            explorer.Config.SelectedPaths.InsertLast(element.Path);
                        }
                    }

                    if (UI::MenuItem("Remove from Selected Items")) {
                        int index = explorer.Config.SelectedPaths.Find(element.Path);
                        if (index != -1) {
                            explorer.Config.SelectedPaths.RemoveAt(index);
                        }
                    }

                    if (UI::MenuItem("Pin Item")) {
                        explorer.utils.PinSelectedElement();
                    }

                    if (UI::MenuItem("Delete Item")) {
                        explorer.utils.DeleteSelectedElement();
                    }

                    explorer.keyPress.isControlPressed = false; 
                    // I hate this solution so fucking much, but I've been going crazy over the 'sticky'
                    // ctrl issue, and I can't take it anymore...
                    // This doesn't even fix the issue properly, but I'm just over it as this point...
                    // Hours wasted: 4
                }
                UI::EndPopup();
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

/* ------------------------ Handle Button Clicks ------------------------ */
// FIXME: After clicking ctrl it 'sticks' to you, you have to click ctrl again to remove the stickyness...
//        Some custom functionality needs to be added to avoid this...
    class KeyPresses {
        bool isControlPressed = false;
        bool isLMouseButtonPressed = false;
        bool isRMouseButtonPressed = false;        
    }

    void fe_HandleKeyPresses(bool down, VirtualKey key) {
        if (key == VirtualKey::Control) {
            explorer.keyPress.isControlPressed = down;
        }
        if (key == VirtualKey::LButton) {
            explorer.keyPress.isLMouseButtonPressed = down;
        }
        if (key == VirtualKey::RButton) {
            explorer.keyPress.isRMouseButtonPressed = down;
        }
    }
/* ------------------------ End Handle Button Clicks ------------------------ */

    void RenderFileExplorer() {
        if (showInterface && explorer !is null) {
            UserInterface ui(explorer);
            explorer.ui.Render_FileExplorer();
        }
    }

    void fe_Start(
        bool _mustReturn = true,
        vec2 _minmaxReturnAmount = vec2(1, -1),
        string _path = "",
        string _searchQuery = "",
        string[] _filters = array<string>()
    ) {
        Config config;
        config.MustReturn = _mustReturn;
        config.MinMaxReturnAmount = _minmaxReturnAmount;
        config.Path = _path;
        config.SearchQuery = _searchQuery;
        config.Filters = _filters;

        if (explorer is null) {
            @explorer = FileExplorer(config);
        } else {
            @explorer.Config = config;
        }
        
        explorer.Open(config);
    }

    void fe_ForceClose() {
        showInterface = false;
    }
}

/* ------------------------ GBX Parsing ------------------------ */

// TODO:
// 

// Fixme:
// - Currently only Replay type is accounted for, need to add Map (and more) types as well 
// (but it's proving to be a bit tricky) (Reason: nothing is being added to the xmlString)

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
        if (    chunks[i].ChunkId == 50606082 // Maps /*50933761*/
             || chunks[i].ChunkId == 50606082 // Replays
             || chunks[i].ChunkId == 50606082 // Challenges
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
            } else if (gbxType == "challenge") {
                ParseChallengeMetadata(headerNode, metadata);
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

void ParseChallengeMetadata(XML::Node &in headerNode, dictionary &inout metadata) {
    XML::Node identNode = headerNode.Child("ident");
    if (identNode) {
        metadata["map_uid"] = identNode.Attribute("uid");
        metadata["map_name"] = identNode.Attribute("name");
        metadata["map_author"] = identNode.Attribute("author");
    }

    XML::Node descNode = headerNode.Child("desc");
    if (descNode) {
        metadata["desc_envir"] = descNode.Attribute("envir");
        metadata["desc_mood"] = descNode.Attribute("mood");
        metadata["desc_maptype"] = descNode.Attribute("type");
        metadata["desc_nblaps"] = descNode.Attribute("nblaps");
        metadata["desc_price"] = descNode.Attribute("price");
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

/* ------------------------ End GBX Parsing ------------------------ */


/* ------------------------ DLL ------------------------ */
/* ------------------------ File Creation Time ------------------------ */
namespace DLL {
    Import::Library@ lib;
    Import::Function@ getFileCreationTimeFunc;

    bool loadLibrary() {
        if (lib is null) {
            string dllPath = IO::FromStorageFolder("DLLs/FileCreationTime.dll");
            @lib = Import::GetLibrary(dllPath);
            if (lib is null) {
                log("Failed to load DLL: " + dllPath, LogLevel::Error, 1379, "loadLibrary");
                return false;
            }
        }

        if (getFileCreationTimeFunc is null) {
            @getFileCreationTimeFunc = lib.GetFunction("GetFileCreationTime");
            if (getFileCreationTimeFunc is null) {
                log("Failed to get function from DLL.", LogLevel::Error, 1387, "loadLibrary");
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
    log("Attempting to retrieve file creation time for: " + filePath, LogLevel::Info, 1408, "FileCreatedTime");

    if (!DLL::loadLibrary()) {
        log("Failed to load library for file creation time retrieval.", LogLevel::Error, 1411, "FileCreatedTime");
        return "-300";
    }

    string result = DLL::FileCreatedTime(filePath);
    if (result != "") {
        log("Error retrieving file creation time. Code: " + result, LogLevel::Warn, 1417, "FileCreatedTime");
    } else {
        log("File creation time retrieved successfully: " + result, LogLevel::Info, 1419, "FileCreatedTime");
    }
    return result;
}

/* ------------------------ End File Creation Time ------------------------ */
/* ------------------------ End DLL ------------------------ */


/* ------------------------ Functions / Variables that have to be in the global namespace ------------------------ */

// Sorry, but all inline variables have to be in the global namespace.
array<string>@ FILE_EXPLORER_selectedPaths;

// Sorry, due to limitations in Openplanet the "OnKeyPress" function has to be in the global namespace.
// If you are using this funciton in you own project please add: ` FILE_EXPLORER_KEYPRESS_HANDLER(down, key); `
// to your own "OnKeyPress" function. 
// If this is not done, the File Explorer will not work as intended.

// ----- REMOVE THIS IF YOU HANDLE KEYPRESSES IN YOUR OWN CODE (also read the comment above) ----- //
void OnKeyPress(bool down, VirtualKey key) {
    FILE_EXPLORER_KEYPRESS_HANDLER(down, key);
}
// ----- REMOVE THIS IF YOU HANDLE KEYPRESSES IN YOUR OWN CODE (also read the comment above) ----- //

void FILE_EXPLORER_KEYPRESS_HANDLER(bool down, VirtualKey key) {
    FileExplorer::fe_HandleKeyPresses(down, key);
}

// Sorry, but again, due to limitations in Openplanet the "Render" function has to be in the global namespace.
// If you are using this function in your own project please add ` FILE_EXPLORER_BASE_RENDERER ` to your own 
// render pipeline, usually one of the "Render", or "RenderInterface" functions.
// If this is not done, the File Explorer will not work as intended.

// ----- REMOVE THIS IF YOU HAVE ANY RENDER FUNCTION IN YOUR OWN CODE (also read the comment above) ----- //
/**
 * RELEASE:
 * Currently hidden when testing, please remove the comment when this is done.

void RenderInterface() {
    FILE_EXPLORER_BASE_RENDERER();
}
*/
// ----- REMOVE THIS IF YOU HAVE ANY RENDER FUNCTION IN YOUR OWN CODE (also read the comment above) ----- //

void FILE_EXPLORER_BASE_RENDERER() {
    FileExplorer::RenderFileExplorer();
}

void OpenFileExplorerExample() {
    FileExplorer::fe_Start(
        true, // _mustReturn
        vec2(1, 99999), // _minmaxReturnAmount
        IO::FromUserGameFolder("Replays/"), // path // Change to Maps/ when done with general gbx detection is done
        "", // searchQuery
        { "replay" } // filters
    );
}

// Remove after testing
void Render() {
    FILE_EXPLORER_BASE_RENDERER();
    FILE_EXPLORER_V1_BASE_RENDERER(); // Used for comparison, should be removed on release
    
    if (UI::Begin(Icons::UserPlus + " File Explorer", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
        if (UI::Button("Open File Explorer")) {
            OpenFileExplorerExample();
        }
        if (FileExplorer::explorer !is null) UI::Text(tostring(FileExplorer::explorer.keyPress.isControlPressed));
        if (FileExplorer::explorer !is null) UI::Text(tostring(FileExplorer::explorer.keyPress.isLMouseButtonPressed));
        if (FileExplorer::explorer !is null) UI::Text(tostring(FileExplorer::explorer.keyPress.isRMouseButtonPressed));
    }
    UI::End();
}