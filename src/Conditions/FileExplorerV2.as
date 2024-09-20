//    ______ _ _         ______              _
//   |  ___(_) |        |  ____\            | |
//   | |_   _| | ___    | |___ __  __ _____ | | ___  _ __  ___  _ __ 
//   |  _| | | |/ _ \   |  __| \ \/ /| ___ \| |/ _ \| '__|/ _ \| '__|
//   | |   | | |  __/   | |____ >  < | |_/ /| | (_) | |  |  __/| | 
//   \_|   |_|_|\___|   \_____ /_/\_\| ___/ |_|\___/|_|   \___||_|
//                                   | |
//                                   |_|
//                                                                     
//   FILE EXPLORER for AngelScript
//   Version 0.1.0
//   https://github.com/st-AR-gazer/_file-explorer
//
//   Made for use in Trackmania Plugins using Openplanet and AngelScript

// Required Openplanet version 1.26.32

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
 *    **NOTE**: The `FILE_EXPLORER_BASE_RENDERER()` function should be called at the start of your render loop.
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
 * 4. **Retrieve Selected File Paths:**
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
 *    For a full example implementation see NOTE 1.
 * 
 * 
 * **Summary:**
 * - **Rendering:** Add `FILE_EXPLORER_BASE_RENDERER()` to your `Render()` or `RenderInterface()` method.
 * - **Opening:** Use `FileExplorer::fe_Start()` to open the FileExplorer.
 * - **File Selection:** Retrieve the selected paths using `FileExplorer::exports.GetSelectedPaths()` after the user 
 *   has made their selection.
 * 
 * With these steps, the FileExplorer will be fully integrated into your plugin, and it should allow users easily 
 * navigate directories and select and return different paths with relative ease files.
 * 
 * 
 * **NOTE 1:**
 *
 * This is a full example implementation of how to use the FileExplorer in your plugin. This example includes all the
 * necessary steps to integrate the FileExplorer and handle the selected file paths.
 * 
 *  ```angelscript
    string[] selectedFiles;

    void RenderInterface() {
        FILE_EXPLORER_BASE_RENDERER();  // This ensures the FileExplorer is rendered properly.

        if (UI::Begin("Path explorer", true, UI::WindowFlags::AlwaysAutoResize)) {
            if (UI::Button(Icons::FolderOpen + " Open File Explorer")) {
                FileExplorer::fe_Start(                                                                                 // Required for the file explorer to work 
                    true,                                   // Require the user to select and return files              // Required for the file explorer to work
                    vec2(1, 14),                            // Minimum 1, no effective upper limit on files             // Optional requirement for the file explorer
                    IO::FromUserGameFolder("Replays/"),     // Initial folder path to open                              // Optional requirement for the file explorer
                    "",                                     // Optional search query                                    // Optional requirement for the file explorer
                    { "replay", "ghost" },                  // File type filters                                        // Optional requirement for the file explorer
                    { "replay" },                           // The exported file must be of this type                   // Optional requirement for the file explorer
                    2                                       // The exported file/folder can only be both/file/folder    // Optional requirement for the file explorer
                );
            }

            if (FileExplorer::explorer !is null && FileExplorer::explorer.exports.IsSelectionComplete()) {              // Required for checking the file explorer selection
                array<string> paths = FileExplorer::explorer.exports.GetSelectedPaths();                                // Required for getting the selected paths
                selectedFiles = paths;                                                                                  // Optional requirement for handling the selected paths
            }

            
            // This is just an example, you can use the selected files in any way you want
            // Here I just display them in the UI
            UI::Text("Selected Files: " + selectedFiles.Length);                            
            for (uint i = 0; i < selectedFiles.Length; i++) {                               
                selectedFiles[i] = UI::InputText("File Path " + (i + 1), selectedFiles[i]);
            }
        }
 *  ```
 */


/*

    TODO: 
        - Add support for multiple tabs (not planned)

        - Add support for sorting by name, size, date, etc., both ascending and descending

        - Add a starting ID to each opened instance of the file explorer window, so that multiple 
          instances can be opened at the same time by different plugins (or the same plugin for that matter)

    FIXME: 
        - GBX parsing currently only works for .Replay.Gbx files, this should work for all GBX files 
          (only .replay .map and .challenge should be supported)

        - Re-do the recursive search functionality, it's not working properly...

        - Game crashes when 'minimize' buttons are clicked...

        - When closing the file explorer we shold only close the correct instance (currently it just closes all instances which is not ideal...)

*/

namespace FileExplorer {
    // bool showInterface = false;
    // FileExplorer@ explorer;
    Utils@ utils;

    // ONLY CHANGE THIS IF A DESTRUCTIVE CHANGE IS MADE TO THE FILE EXPLORER SAVE FILE FORMAT, IDEALY 
    // THIS SHOULD NEVER 'CHANGE', JUST BE ADDED TOO, BUT FOR SOME FUTURE PROOFING, THIS WAS ADDED...
    const int FILE_EXPLORER_SETTINGS_VERSION = 1;
    
    class Config {
        // FileExplorer settings
        string id;

        // Passed to Config
        bool mustReturn;
        vec2 minMaxReturnAmount;
        string path;
        string searchQuery;
        array<string> filters;
        array<string> canOnlyReturn;

        // Internal settings
        dictionary activeFilters;
        array<string> selectedPaths;
        array<string> pinnedElements;
        // Internal color
        vec4 validFileColor = vec4(1, 1, 1, 1);       // Default: White
        vec4 invalidFileColor = vec4(1, 1, 1, 0.4);   // Default: Gray
        vec4 validFolderColor = vec4(1, 1, 1, 1);     // Default: White
        vec4 invalidFolderColor = vec4(1, 1, 1, 0.4); // Default: Gray


        // UI-related settings
        int maxElementsPerPage = 30;
        int fileNameDisplayOption = 0; // 0: Default, 1: No Formatting, 2: ManiaPlanet Formatting
        int searchBarPadding = 0;
        bool hideFiles = false;
        bool hideFolders = false;
        bool enablePagination = false;
        bool recursiveSearch = false;
        bool useExtraWarningWhenDeleting = true;
        bool enableSearchBar = true;
        bool sortingAscending = true;
        bool sortFilesBeforeFolders = false;
        dictionary columnsToShow;

        SortingCriteria sortingCriteria = SortingCriteria::name;

        /*const*/ string settingsDirectory = IO::FromDataFolder("Plugin_FileExplorer_Settings");
        /*const*/ string settingsFilePath = Path::Join(settingsDirectory, "FileExplorerSettings.json");

        Config() {
            mustReturn = false;
            id = "";
            path = "";
            searchQuery = "";
            filters = array<string>();
            selectedPaths = array<string>();
            pinnedElements = array<string>();

            columnsToShow.Set("ico", true);
            columnsToShow.Set("name", true);
            columnsToShow.Set("type", true);
            columnsToShow.Set("size", true);
            columnsToShow.Set("lastModified", true);
            columnsToShow.Set("createdDate", true);
        }

        void LoadSettings(string sessionId) {
            FileExplorer@ explorer = fe_GetExplorerById(sessionId);
            if (explorer is null) return;

            if (!IO::FolderExists(settingsDirectory)) {
                IO::CreateFolder(settingsDirectory);
            }

            if (IO::FileExists(settingsFilePath)) {
                string jsonString = utils.ReadFileToEnd(settingsFilePath);
                Json::Value settings = Json::Parse(jsonString);

                bool foundVersion = false;

                for (uint i = 0; i < settings.Length; i++) {
                    Json::Value versionedSettings = settings[i];

                    if (versionedSettings.HasKey("version") && versionedSettings["version"] == FILE_EXPLORER_SETTINGS_VERSION) {
                        foundVersion = true;
                        Json::Value explorerSettings = versionedSettings["settings"];

                        if (explorerSettings.HasKey("PinnedElements")) {
                            Json::Value pins = explorerSettings["PinnedElements"];
                            pinnedElements.Resize(pins.Length);
                            for (uint i = 0; i < pins.Length; i++) {
                                pinnedElements[i] = pins[i];
                            }
                        }
                        if (explorerSettings.HasKey("HideFiles")) {
                            hideFiles = explorerSettings["HideFiles"];
                        }
                        if (explorerSettings.HasKey("HideFolders")) {
                            hideFolders = explorerSettings["HideFolders"];
                        }
                        if (explorerSettings.HasKey("EnablePagination")) {
                            enablePagination = explorerSettings["EnablePagination"];
                        }
                        if (explorerSettings.HasKey("UseExtraWarningWhenDeleting")) {
                            useExtraWarningWhenDeleting = explorerSettings["UseExtraWarningWhenDeleting"];
                        }
                        if (explorerSettings.HasKey("RecursiveSearch")) {
                            recursiveSearch = explorerSettings["RecursiveSearch"];
                        }
                        if (explorerSettings.HasKey("FileNameDisplayOption")) {
                            fileNameDisplayOption = explorerSettings["FileNameDisplayOption"];
                        }
                        if (explorerSettings.HasKey("ColumnsToShow")) {
                            Json::Value cols = explorerSettings["ColumnsToShow"];
                            for (uint i = 0; i < cols.GetKeys().Length; i++) {
                                string col = cols.GetKeys()[i];
                                columnsToShow.Set(col, bool(cols[col]));
                            }
                        }
                        if (explorerSettings.HasKey("MaxElementsPerPage")) {
                            maxElementsPerPage = explorerSettings["MaxElementsPerPage"];
                        }
                        if (explorerSettings.HasKey("SearchBarPadding")) {
                            searchBarPadding = explorerSettings["SearchBarPadding"];
                        }
                        if (explorerSettings.HasKey("EnableSearchBar")) {
                            enableSearchBar = explorerSettings["EnableSearchBar"];
                        }
                        if (explorerSettings.HasKey("SortingCriteria")) {
                            sortingCriteria = utils.StringToSortingCriteria(explorerSettings["SortingCriteria"]);
                        }
                        if (explorerSettings.HasKey("SortingAscending")) {
                            sortingAscending = explorerSettings["SortingAscending"];
                        }
                        if (explorerSettings.HasKey("SortFilesBeforeFolders")) {
                            sortFilesBeforeFolders = explorerSettings["SortFilesBeforeFolders"];
                        }
                        if (explorerSettings.HasKey("ValidFileColor")) {
                            validFileColor = StringToVec4(explorerSettings["ValidFileColor"]);
                        }
                        if (explorerSettings.HasKey("InvalidFileColor")) {
                            invalidFileColor = StringToVec4(explorerSettings["InvalidFileColor"]);
                        }
                        if (explorerSettings.HasKey("ValidFolderColor")) {
                            validFolderColor = StringToVec4(explorerSettings["ValidFolderColor"]);
                        }
                        if (explorerSettings.HasKey("InvalidFolderColor")) {
                            invalidFolderColor = StringToVec4(explorerSettings["InvalidFolderColor"]);
                        }

                        break;
                    }
                }

                if (!foundVersion) {
                    log("Settings version mismatch or not found. Settings cannot be loaded.", LogLevel::Error, 321, "LoadSettings");
                }
            }
        }

        void SaveSettings() {
            if (!IO::FolderExists(settingsDirectory)) {
                IO::CreateFolder(settingsDirectory);
            }

            Json::Value settings = Json::Array();
            if (IO::FileExists(settingsFilePath)) {
                string jsonString = utils.ReadFileToEnd(settingsFilePath);
                settings = Json::Parse(jsonString);
            }

            bool versionExists = false;
            for (uint i = 0; i < settings.Length; i++) {
                if (settings[i].HasKey("version") && settings[i]["version"] == FILE_EXPLORER_SETTINGS_VERSION) {
                    versionExists = true;

                    Json::Value explorerSettings = settings[i]["settings"];
                    explorerSettings = GetCurrentSettings();
                    settings[i]["settings"] = explorerSettings;
                    break;
                }
            }

            if (!versionExists) {
                Json::Value newVersion = Json::Object();
                newVersion["version"] = FILE_EXPLORER_SETTINGS_VERSION;
                newVersion["settings"] = GetCurrentSettings();
                settings.Add(newVersion);
            }

            utils.WriteFile(settingsFilePath, Json::Write(settings));

            // log("Settings saved to: " + settingsFilePath, LogLevel::Info, 358, "SaveSettings");
        }

        Json::Value GetCurrentSettings() {
            Json::Value explorerSettings = Json::Object();

            Json::Value pins = Json::Array();
            for (uint i = 0; i < pinnedElements.Length; i++) {
                pins.Add(pinnedElements[i]);
            }
            explorerSettings["PinnedElements"] = pins;

            explorerSettings["HideFiles"] = hideFiles;
            explorerSettings["HideFolders"] = hideFolders;
            explorerSettings["EnablePagination"] = enablePagination;
            explorerSettings["UseExtraWarningWhenDeleting"] = useExtraWarningWhenDeleting;
            explorerSettings["RecursiveSearch"] = recursiveSearch;
            explorerSettings["FileNameDisplayOption"] = fileNameDisplayOption;

            Json::Value cols = Json::Object();
            array<string> colKeys = columnsToShow.GetKeys();
            for (uint i = 0; i < colKeys.Length; i++) {
                string col = colKeys[i];
                bool value = false;
                columnsToShow.Get(col, value);
                cols[col] = value;
            }
            explorerSettings["ColumnsToShow"] = cols;
            explorerSettings["MaxElementsPerPage"] = maxElementsPerPage;
            explorerSettings["SearchBarPadding"] = searchBarPadding;
            explorerSettings["EnableSearchBar"] = enableSearchBar;
            explorerSettings["SortingCriteria"] = utils.SortingCriteriaToString(sortingCriteria);
            explorerSettings["SortingAscending"] = sortingAscending;
            explorerSettings["SortFilesBeforeFolders"] = sortFilesBeforeFolders;

            explorerSettings["ValidFileColor"] = Vec4ToString(validFileColor);
            explorerSettings["InvalidFileColor"] = Vec4ToString(invalidFileColor);
            explorerSettings["ValidFolderColor"] = Vec4ToString(validFolderColor);
            explorerSettings["InvalidFolderColor"] = Vec4ToString(invalidFolderColor);

            return explorerSettings;
        }

        void ResetSettings() {
            IO::Delete(settingsFilePath);
        }

        void ToggleColumnVisibility(const string &in columnName) {
            if (columnsToShow.Exists(columnName)) {
                bool isVisible;
                columnsToShow.Get(columnName, isVisible);
                columnsToShow.Set(columnName, !isVisible);
            }
        }

        bool IsColumnVisible(const string &in columnName) const {
            if (columnsToShow.Exists(columnName)) {
                bool isVisible;
                columnsToShow.Get(columnName, isVisible);
                return isVisible;
            }
            return false;
        }

        bool IsFilterActive(const string &in filter) const {
            bool isActive = true;
            if (activeFilters.Exists(filter)) {
                activeFilters.Get(filter, isActive);
            }
            return isActive;
        }

        void ToggleFilterActive(const string &in filter) {
            bool isActive = IsFilterActive(filter);
            activeFilters.Set(filter, !isActive);
        }

        string Vec4ToString(vec4 color) {
            return color.x + "," + color.y + "," + color.z + "," + color.w;
        }

        vec4 StringToVec4(const string &in colorStr) {
            array<string> parts = colorStr.Split(",");
            if (parts.Length == 4) {
                return vec4(Text::ParseFloat(parts[0]), Text::ParseFloat(parts[1]), Text::ParseFloat(parts[2]), Text::ParseFloat(parts[3]));
            }
            return vec4(1, 1, 1, 1);
        }
    }

    enum SortingCriteria {
        nameIgnoreFileFolder,
        name,
        size,
        lastModified,
        createdDate
    }

    enum _Icon {
        folder,
        folderOpen,
        file,
        fileText,
        filePdf,
        fileWord,
        fileExcel,
        filePowerpoint,
        fileImage,
        fileArchive,
        fileAudio,
        fileVideo,
        fileCode,
        fileEpub
    }

    class Exports {
        bool selectionComplete = false;
        array<string> selectedPaths;

        FileExplorer@ explorer;

        Exports(FileExplorer@ fe) {
            @explorer = fe;
        }

        void SetSelectionComplete(array<string>@ paths) {
            selectedPaths = paths;
            selectionComplete = true;
        }

        bool IsSelectionComplete() {
            return selectionComplete;
        }

        array<string>@ GetSelectedPaths() {
            selectionComplete = false;
            utils.TruncateSelectedPathsIfNeeded();
            
            explorer.MarkForDeletion();
            
            return selectedPaths;
        }
    }
    
    // Element info is set in "GetElementInfo" in the FE class
    class ElementInfo {
        string name;
        string path;
        string size;
        int64 sizeBytes;
        string type;
        string gbxType;
        int64 lastModifiedDate;
        int64 creationDate;
        bool isFolder;
        _Icon icon;
        bool isSelected;
        uint64 lastSelectedTime;
        dictionary gbxMetadata;
        bool shouldShow;

        uint64 lastClickTime;

        ElementInfo(
                const string &in _name, 
                const string &in _path, 
                const string &in _size, 
                int64 _sizeBytes, 
                const string &in _type, 
                const string &in _gbxType,
                int64 _lastModifiedDate, 
                int64 _creationDate, 
                bool _isFolder, 
                _Icon _icon, bool _isSelected) {
            this.name = _name;
            this.path = _path;
            this.size = _size;
            this.sizeBytes = _sizeBytes;
            this.type = _type;
            this.gbxType = _gbxType;
            this.lastModifiedDate = _lastModifiedDate;
            this.creationDate = _creationDate;
            this.isFolder = _isFolder;
            this.icon = _icon;
            this.isSelected = _isSelected;
            this.lastSelectedTime = 0;
            this.shouldShow = true;
            this.lastClickTime = 0;
        }

        void SetGbxMetadata(dictionary@ metadata) {
            gbxMetadata = metadata;
        }
    }

    class Navigation {
        string CurrentPath;
        FileExplorer@ explorer;

        Navigation(FileExplorer@ fe) {
            @explorer = fe;
            CurrentPath = fe.Config.path;
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
            log("Current path before moving up: " + path, LogLevel::Info, 572, "MoveUpOneDirectory");

            UpdateHistory(path);

            if (path.EndsWith("/") || path.EndsWith("\\")) {
                path = path.SubStr(0, path.Length - 1);
            }
            
            int lastSlash = Math::Max(path.LastIndexOf("/"), path.LastIndexOf("\\"));
            if (lastSlash > 0) {
                path = path.SubStr(0, lastSlash);
            } else {
                path = "/";
            }

            if (!path.EndsWith("/") && !path.EndsWith("\\")) {
                path += "/";
            }

            log("New path after moving up: " + path, LogLevel::Info, 591, "MoveUpOneDirectory");

            explorer.tab[0].LoadDirectory(path);
        }

        void MoveIntoSelectedDirectory() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            // ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();

            if (selectedElement !is null && selectedElement.isFolder) {
                if (!selectedElement.path.StartsWith(explorer.tab[0].Navigation.GetPath())) {
                    log("Folder is not in the current folder, cannot move into it.", LogLevel::Warn, 602, "MoveIntoSelectedDirectory");
                } else {
                    UpdateHistory(selectedElement.path);
                    explorer.tab[0].LoadDirectory(selectedElement.path);
                }
            } else {
                log("No folder selected or selected element is not a folder.", LogLevel::Warn, 608, "MoveIntoSelectedDirectory");
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

        uint CurrentPage = 0;
        uint TotalPages = 1;


        FileTab(Config@ cfg, FileExplorer@ fe) {
            @Config = cfg;
            @explorer = fe;
            @Navigation = fe.nav;
            
            LoadDirectory(Config.path);
        }

        void LoadDirectory(const string &in path) {
            Elements.Resize(0);

            explorer.nav.UpdateHistory(path);
            explorer.nav.SetPath(path);

            StartIndexingFiles(path);
            CurrentPage = 0;
            UpdatePagination();
        }

        void StartIndexingFiles(const string &in path, bool recursive = false) {
            explorer.IsIndexing = true;
            explorer.IndexingMessage = recursive ? "Recursive search in progress..." : "Folder is being indexed...";
            explorer.CurrentIndexingPath = path;

            startnew(CoroutineFuncUserdata(IndexFilesCoroutine), this);
        }

        void IndexFilesCoroutine(ref@ r) {
            FileTab@ tab = cast<FileTab@>(r);
            if (tab is null) return;

            tab.Elements.Resize(0);
            tab.explorer.IsIndexing = true;
            string startPath = tab.Navigation.GetPath();
            bool recursive = tab.Config.recursiveSearch;
            log((recursive ? "Recursive " : "") + "Indexing started for path: " + startPath, LogLevel::Info, 704, "IndexFilesCoroutine");

            // Incase I change my mind and want to add recursive search back in at a later date... (it's not fully working, so it's commented out for now, but I'm probably not gonna do anything with it... way too slow)
            // array<string> elements = recursive ? PerformRecursiveIndexing(tab, startPath) : tab.explorer.GetFiles(startPath, false);
            array<string> elements = tab.explorer.GetFiles(startPath, false);

            if (elements.Length == 0) {
                log("No files found in directory: " + startPath, LogLevel::Info, 711, "IndexFilesCoroutine");
            }

            const uint batchSize = 1000;
            uint totalFiles = elements.Length;
            uint processedFiles = 0;

            for (uint i = 0; i < totalFiles; i++) {
                string path = elements[i];
                if (path.Contains("\\/")) {
                    path = path.Replace("\\/", "/");
                }

                ElementInfo@ elementInfo = tab.explorer.GetElementInfo(path);
                if (elementInfo !is null) {
                    tab.Elements.InsertLast(elementInfo);
                }

                processedFiles++;

                if (processedFiles % batchSize == 0) {
                    tab.explorer.IndexingMessage = "Indexing element " + processedFiles + " out of " + totalFiles;
                    yield();
                }
            }

            tab.explorer.IndexingMessage = "Indexing element " + processedFiles + " out of " + totalFiles;
            yield();

            tab.ApplyFiltersAndSearch();
            tab.ApplyVisibilitySettings();
            tab.explorer.IsIndexing = false;

            log((recursive ? "Recursive " : "") + "Indexing completed. Number of elements: " + tab.Elements.Length, LogLevel::Info, 744, "IndexFilesCoroutine");

            explorer.UpdateCurrentSelectedElement();
        }

        // Incase I change my mind and want to add recursive search back in at a later date... (it's not fully working, so it's commented out for now, but I'm probably not gonna do anything with it... way too slow)
        // array<string> PerformRecursiveIndexing(FileTab@ tab, const string &in startPath) {
        //     array<string> results;
        //     array<string> dirsToProcess = { startPath };

        //     while (dirsToProcess.Length > 0) {
        //         string currentDir = dirsToProcess[dirsToProcess.Length - 1];
        //         dirsToProcess.RemoveLast();

        //         array<string> elements = IO::IndexFolder(currentDir, false);

        //         for (uint i = 0; i < elements.Length; i++) {
        //             if (utils.IsDirectory(elements[i])) {
        //                 dirsToProcess.InsertLast(elements[i]);
        //             } else {
        //                 results.InsertLast(elements[i]);
        //             }

        //             tab.explorer.IndexingMessage = "Indexed " + tostring(results.Length) + " files from " + currentDir;

        //             if (results.Length % 100 == 0) {
        //                 yield();
        //             }
        //         }
        //     }

        //     return results;
        // }

        void ApplyFiltersAndSearch() {
            if (explorer.Config.recursiveSearch) {
                ApplyRecursiveSearch();
            } else {
                ApplyNonRecursiveSearch();
            }

            ApplyFilters();
            if (explorer.Config.enablePagination) {
                UpdatePagination();
            } else {
                explorer.tab[0].TotalPages = 1;
                explorer.tab[0].CurrentPage = 0;
            }
        }

        void ApplyNonRecursiveSearch() {
            array<ElementInfo@> tempElements = Elements;
            Elements.Resize(0);

            for (uint i = 0; i < tempElements.Length; i++) {
                if (Config.searchQuery == "" || tempElements[i].name.ToLower().Contains(Config.searchQuery.ToLower())) {
                    Elements.InsertLast(tempElements[i]);
                }
            }
        }

        void ApplyRecursiveSearch() {
            array<ElementInfo@> tempElements = LoadAllElementsRecursively(Navigation.GetPath());
            Elements.Resize(0);

            for (uint i = 0; i < tempElements.Length; i++) {
                if (Config.searchQuery == "" || tempElements[i].name.ToLower().Contains(Config.searchQuery.ToLower())) {
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
                if (elementInfo.isFolder) {
                    array<ElementInfo@> subElements = LoadAllElementsRecursively(elementInfo.path);
                    for (uint j = 0; j < subElements.Length; j++) {
                        elementList.InsertLast(subElements[j]);
                    }
                }
            }
            return elementList;
        }

        void ApplyFilters() {
            bool anyActiveFilters = false;
            for (uint i = 0; i < Config.filters.Length; i++) {
                if (Config.IsFilterActive(Config.filters[i])) {
                    anyActiveFilters = true;
                    break;
                }
            }

            for (uint i = 0; i < Elements.Length; i++) {
                ElementInfo@ element = Elements[i];
                element.shouldShow = true;

                if (anyActiveFilters && !element.isFolder) {
                    bool found = false;
                    for (uint j = 0; j < Config.filters.Length; j++) {
                        string filter = Config.filters[j];
                        if (Config.IsFilterActive(filter)) {

                            string elementGbxType = element.gbxType;
                            
                            if (elementGbxType.ToLower() == filter.ToLower()) {
                                found = true;
                                break;
                            } else if (filter.ToLower() == elementGbxType.ToLower()) {
                                found = true;
                                break;
                            }
                        }
                    }
                    element.shouldShow = found;
                }
            }
        }

        void ApplyVisibilitySettings() {
            for (uint i = 0; i < Elements.Length; i++) {
                ElementInfo@ element = Elements[i];
                if (Config.hideFiles && !element.isFolder) {
                    element.shouldShow = false;
                }
                if (Config.hideFolders && element.isFolder) {
                    element.shouldShow = false;
                }
            }
        }

        ElementInfo@ GetSelectedElement() {
            for (uint i = 0; i < Elements.Length; i++) {
                if (Elements[i].isSelected) {
                    return Elements[i];
                }
            }
            return null;
        }

        void UpdatePagination() {
            uint totalElements = Elements.Length;
            TotalPages = uint(Math::Ceil(float(totalElements) / Config.maxElementsPerPage));
            if (CurrentPage >= TotalPages) {
                CurrentPage = Math::Max(TotalPages - 1, 0);
            }
        }

        void SortElements() {
            for (uint i = 0; i < Elements.Length - 1; i++) {
                for (uint j = i + 1; j < Elements.Length; j++) {
                    bool swap = false;
                    if (Config.sortFilesBeforeFolders) {
                        swap = Elements[i].isFolder && !Elements[j].isFolder;
                    } else {
                        swap = !Elements[i].isFolder && Elements[j].isFolder;
                    }
                        
                    if (Config.sortingCriteria == SortingCriteria::nameIgnoreFileFolder) {
                        swap = Config.sortingAscending ? Elements[i].name > Elements[j].name : Elements[i].name < Elements[j].name;
                    } else if (Config.sortingCriteria == SortingCriteria::name) {
                        if (Elements[i].isFolder && Elements[j].isFolder) {
                            swap = Config.sortingAscending ? Elements[i].name > Elements[j].name : Elements[i].name < Elements[j].name;
                        } else if (!Elements[i].isFolder && !Elements[j].isFolder) {
                            swap = Config.sortingAscending ? Elements[i].name > Elements[j].name : Elements[i].name < Elements[j].name;
                        } else {
                            swap = Config.sortFilesBeforeFolders ? !Elements[i].isFolder : Elements[i].isFolder;
                        }
                    } else if (Config.sortingCriteria == SortingCriteria::size) {
                        swap = Config.sortingAscending ? Elements[i].sizeBytes > Elements[j].sizeBytes : Elements[i].sizeBytes < Elements[j].sizeBytes;
                    } else if (Config.sortingCriteria == SortingCriteria::lastModified) {
                        swap = Config.sortingAscending ? Elements[i].lastModifiedDate > Elements[j].lastModifiedDate : Elements[i].lastModifiedDate < Elements[j].lastModifiedDate;
                    } else if (Config.sortingCriteria == SortingCriteria::createdDate) {
                        swap = Config.sortingAscending ? Elements[i].creationDate > Elements[j].creationDate : Elements[i].creationDate < Elements[j].creationDate;
                    }
        
                    if (swap) {
                        ElementInfo@ temp = Elements[i];
                        @Elements[i] = Elements[j];
                        @Elements[j] = temp;
                    }
                }
            }
        }
    }

    class Utils {
        FileExplorer@ explorer;

        Utils(FileExplorer@ fe) {
            @explorer = fe;
        }

        // ------------------------------------------------
        // Directory and Path Operations
        // ------------------------------------------------

        bool IsDirectory(const string &in path) {
            if (path.EndsWith("/") || path.EndsWith("\\")) return true;
            return false;
        }

        string GetDirectoryName(const string &in path) {
            string trimmedPath = path;

            while (trimmedPath.EndsWith("/") || trimmedPath.EndsWith("\\")) {
                trimmedPath = trimmedPath.SubStr(0, trimmedPath.Length - 1);
            }

            int index = trimmedPath.LastIndexOf("/");
            int index2 = trimmedPath.LastIndexOf("\\");

            index = Math::Max(index, index2);

            if (index == -1) {
                return trimmedPath;
            }

            return trimmedPath.SubStr(index + 1);
        }

        // ------------------------------------------------
        // File/Folder Loading and Operations
        // ------------------------------------------------

        void RefreshCurrentDirectory() {
            string currentPath = explorer.tab[0].Navigation.GetPath();
            log("Refreshing directory: " + currentPath, LogLevel::Info, 977, "RefreshCurrentDirectory");
            explorer.tab[0].LoadDirectory(currentPath);
        }

        void OpenSelectedFolderInNativeFileExplorer() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            if (selectedElement !is null && selectedElement.isFolder) {
                log("Opening folder: " + selectedElement.path, LogLevel::Info, 984, "OpenSelectedFolderInNativeFileExplorer");
                OpenExplorerPath(selectedElement.path);
            } else {
                log("No folder selected or selected element is not a folder.", LogLevel::Error, 987, "OpenSelectedFolderInNativeFileExplorer");
            }
        }

        void OpenCurrentFolderInNativeFileExplorer() {
            string currentPath = explorer.tab[0].Navigation.GetPath();
            log("Opening folder: " + currentPath, LogLevel::Info, 993, "OpenCurrentFolderInNativeFileExplorer");
            OpenExplorerPath(currentPath);
        }

        bool IsElementSelected() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            return selectedElement !is null;
        }

        // ------------------------------------------------
        // File I/O Operations
        // ------------------------------------------------

        string ReadFileToEnd(const string &in path) {
            IO::File file(path, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();
            return content;
        }

        void WriteFile(const string &in path, const string &in content) {
            IO::File file;
            file.Open(path, IO::FileMode::Write);
            file.Write(content);
            file.Close();
        }

        // ------------------------------------------------
        // UI Helper Functions
        // ------------------------------------------------

        void DisabledButton(const string &in text, const vec2 &in size = vec2()) {
            UI::BeginDisabled();
            UI::Button(text, size);
            UI::EndDisabled();
        }

        // ------------------------------------------------
        // Window Management Functions
        // ------------------------------------------------

        vec2 originalPos;
        vec2 originalSize;
        bool isMaximized = false;

        void MaximizeWindow() {
            vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
            if (isMaximized) {
                UI::SetWindowPos(originalPos);
                UI::SetWindowSize(originalSize);
                isMaximized = false;
            } else {
                originalPos = UI::GetWindowPos();
                originalSize = UI::GetWindowSize();

                vec2 maximizedSize = vec2(screenSize.x * 0.97, screenSize.y * 0.97);
                vec2 maximizedPos = vec2(screenSize.x * 0.015, screenSize.y * 0.015);

                UI::SetWindowPos(maximizedPos);
                UI::SetWindowSize(maximizedSize);
                isMaximized = true;
            }
        }

        void MinimizeWindow() {
            originalPos = UI::GetWindowPos();
            originalSize = UI::GetWindowSize();
            isMaximized = false;

            vec2 minimizedPos = vec2(30, Draw::GetHeight() - 70);
            vec2 minimizedSize = vec2(325, 40);

            UI::SetWindowPos(minimizedPos);
            UI::SetWindowSize(minimizedSize);
        }

        void BaseWindow() {
            UI::SetWindowPos(vec2(150, 200));
            UI::SetWindowSize(vec2(1650, 800));
        }

        // ------------------------------------------------
        // File and Folder Manipulation
        // ------------------------------------------------

        bool RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;

        void DeleteSelectedElement() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            if (selectedElement !is null) {
                if (selectedElement.isFolder) {
                    array<string> folderContents = IO::IndexFolder(selectedElement.path, false);
                    if (folderContents.Length > 0) {
                        utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = true;
                    } else {
                        log("Deleting empty folder: " + selectedElement.path, LogLevel::Info, 1088, "DeleteSelectedElement");
                        IO::DeleteFolder(selectedElement.path);
                        explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    }
                } else {
                    log("Deleting file: " + selectedElement.path, LogLevel::Info, 1093, "DeleteSelectedElement");
                    IO::Delete(selectedElement.path);
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
            }
        }

        bool RENDER_RENAME_POPUP_FLAG;

        void RenameSelectedElement(const string &in newName) {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            if (selectedElement is null) return;

            string currentPath = selectedElement.path;
            string newPath;

            string sanitizedNewName = Path::SanitizeFileName(newName);

            if (selectedElement.isFolder) {
                while (currentPath.EndsWith("/") || currentPath.EndsWith("\\")) {
                    currentPath = currentPath.SubStr(0, currentPath.Length - 1);
                }

                string parentDirectory = Path::GetDirectoryName(currentPath);
                newPath = Path::Join(parentDirectory, sanitizedNewName);
            } else {
                string directoryPath = Path::GetDirectoryName(currentPath);
                string extension = Path::GetExtension(currentPath);
                newPath = Path::Join(directoryPath, sanitizedNewName + extension);
            }

            IO::Move(currentPath, newPath);

            explorer.tab[0].LoadDirectory(Path::GetDirectoryName(currentPath));
        }

        void PinSelectedElement() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            if (selectedElement !is null) {
                if (explorer.Config.pinnedElements.Find(selectedElement.path) == -1) {
                    log("Pinning element: " + selectedElement.path, LogLevel::Info, 1133, "PinSelectedElement");
                    explorer.Config.pinnedElements.InsertLast(selectedElement.path);
                    explorer.Config.SaveSettings();
                }
            }
        }

        void TruncateSelectedPathsIfNeeded() {
            uint maxAllowed = uint(explorer.Config.minMaxReturnAmount.y);
            if (explorer.Config.minMaxReturnAmount.y != -1 && explorer.Config.selectedPaths.Length > maxAllowed) {
                explorer.Config.selectedPaths.Resize(maxAllowed);
            }
        }

        // ------------------------------------------------
        // Sorting Functions
        // ------------------------------------------------

        string SortingCriteriaToString(SortingCriteria criteria) {
            switch (criteria) {
                case SortingCriteria::nameIgnoreFileFolder: return "NameIgnoreFileFolder";
                case SortingCriteria::name: return "Name";
                case SortingCriteria::size: return "Size";
                case SortingCriteria::lastModified: return "Date Modified";
                case SortingCriteria::createdDate: return "Date Created";
            }
            return "Unknown";
        }

        SortingCriteria StringToSortingCriteria(const string &in str) {
            if (str == "NameIgnoreFileFolder") return SortingCriteria::nameIgnoreFileFolder;
            if (str == "Name") return SortingCriteria::name;
            if (str == "Size") return SortingCriteria::size;
            if (str == "Date Modified") return SortingCriteria::lastModified;
            if (str == "Date Created") return SortingCriteria::createdDate;
            return SortingCriteria::name;
        }

        // ------------------------------------------------
        // File Type Handling
        // ------------------------------------------------

        string GetGbxFileType(const string &in path) {
            string ext = Path::GetExtension(path).SubStr(1).ToLower();
            if (ext == "gbx") {
                string fileName = Path::GetFileName(path);

                string trimmedPath = fileName;
                int index = trimmedPath.LastIndexOf(".");
                trimmedPath = trimmedPath.SubStr(0, index);
                int index2 = trimmedPath.LastIndexOf(".");

                string gbxFileType = trimmedPath.SubStr(index2 + 1);

                return gbxFileType;
            }
            return "";
        }

        // ------------------------------------------------
        // Validation Functions
        // ------------------------------------------------

        bool IsValidReturnElement(ElementInfo@ element) {
            bool canReturn = true;

            if (element.isFolder) {
                canReturn = !(explorer.Config.canOnlyReturn.Find("file") >= 0 || 
                            explorer.Config.canOnlyReturn.Find("files") >= 0);
            } else {
                canReturn = !(explorer.Config.canOnlyReturn.Find("folder") >= 0 || 
                            explorer.Config.canOnlyReturn.Find("folders") >= 0 || 
                            explorer.Config.canOnlyReturn.Find("dir") >= 0 || 
                            explorer.Config.canOnlyReturn.Find("directories") >= 0);
            }

            if (!element.isFolder && explorer.Config.canOnlyReturn.Length > 0) {
                bool isValidFileType = false;

                if (element.type.ToLower() == "gbx" && element.gbxType.Length > 0) {
                    for (uint i = 0; i < explorer.Config.canOnlyReturn.Length; i++) {
                        if (element.gbxType.ToLower() == explorer.Config.canOnlyReturn[i].ToLower()) {
                            isValidFileType = true;
                            break;
                        }
                    }
                } else {
                    for (uint i = 0; i < explorer.Config.canOnlyReturn.Length; i++) {
                        if (element.type.ToLower() == explorer.Config.canOnlyReturn[i].ToLower()) {
                            isValidFileType = true;
                            break;
                        }
                    }
                }

                if (!isValidFileType) {
                    canReturn = false;
                }
            }

            return canReturn;
        }
    }

    class FileExplorer {
        string sessionId;
        bool showInterface = false;
        int64 closeTime = -1;
        bool locked = false;

        Config@ Config;
        // Utils@ utils;
        array<FileTab@> tab;
        array<string> PinnedElements;
        UserInterface@ ui;
        Exports@ exports;
        Navigation@ nav;

        bool IsIndexing = false;
        string IndexingMessage = "";
        array<ElementInfo@> CurrentElements;
        string CurrentIndexingPath;

        ElementInfo@ CurrentSelectedElement;

        FileExplorer(Config@ cfg, const string &in id) {
            sessionId = id;
            
            @Config = cfg;
            @utils = Utils(this);
            @nav = Navigation(this);
            tab.Resize(1);
            @tab[0] = FileTab(cfg, this);
            @ui = UserInterface(this);
            @exports = Exports(this);

            @CurrentSelectedElement = null;

            nav.UpdateHistory(cfg.path);
            
            @CurrentSelectedElement = null;

            nav.UpdateHistory(cfg.path);
        }

        void UpdateCurrentSelectedElement() {
            @CurrentSelectedElement = tab[0].GetSelectedElement();
        }

        void Open(Config@ config) {
            string pluginName = Meta::ExecutingPlugin().Name;
            string sessionKey = pluginName + "::" + config.id;

            FileExplorer@ explorer;
            if (!explorersByPlugin.Get(sessionKey, @explorer)) {
                log("Explorer not found for sessionKey: " + sessionKey, LogLevel::Error, 1281, "Open");
                return;
            }

            @Config = config;
            log("Config initialized with path: " + Config.path, LogLevel::Info, 1286, "Open");

            if (nav is null) {
                @nav = Navigation(this);
                log("Navigation initialized", LogLevel::Info, 1290, "Open");
            }

            if (nav is null) {
                log("Navigation is null after initialization.", LogLevel::Error, 1294, "Open");
                return;
            }

            log("Setting navigation path to: " + Config.path, LogLevel::Info, 1298, "Open");

            nav.SetPath(Config.path);
            Config.LoadSettings(sessionKey);
            exports.selectionComplete = false;
            this.showInterface = true;
        }

        void Close() {
            Config.SaveSettings();
            this.showInterface = false;
            this.closeTime = Time::Now;
            this.locked = true;

            startnew(CoroutineFunc(this.DelayedCleanup));
        }

        private void DelayedCleanup() {
            yield(150);
            if (this.locked) {
                MarkForDeletion();
            }
        }

        void MarkForDeletion() {
            yield();
            CloseCurrentSession();
        }

        private void CloseCurrentSession() {
            string pluginName = Meta::ExecutingPlugin().Name;
            string sessionKey = pluginName + "::" + sessionId;
            explorersByPlugin.Delete(sessionKey);
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
            bool isFolder = utils.IsDirectory(path);
            string name = isFolder ? utils.GetDirectoryName(path) : Path::GetFileName(path);
            string type = isFolder ? "folder" : Path::GetExtension(path).SubStr(1);
            string gbxType = isFolder ? "" : utils.GetGbxFileType(path);
            string size = isFolder ? "-" : ConvertFileSizeToString(IO::FileSize(path));
            int64 sizeBytes = IO::FileSize(path);
            int64 lastModified = IO::FileModifiedTime(path);
            int64 creationDate = IO::FileCreatedTime(path);
            _Icon icon = GetElementIcon(isFolder, type);
            ElementInfo@ elementInfo = ElementInfo(name, path, size, sizeBytes, type, gbxType, lastModified, creationDate, isFolder, icon, false);

            if (type.ToLower() == "gbx") {
                startnew(CoroutineFuncUserdata(ReadGbxMetadataCoroutine), elementInfo);
            }

            return elementInfo;
        }

        void ReadGbxMetadataCoroutine(ref@ r) {
            ElementInfo@ elementInfo = cast<ElementInfo@>(r);
            if (elementInfo is null) return;

            string path = elementInfo.path;
            dictionary gbxMetadata = ReadGbxHeader(path);
            elementInfo.SetGbxMetadata(gbxMetadata);
        }

        string ConvertFileSizeToString(uint64 size) {
            if (size < 1024) return size + " B";
            else if (size < 1024 * 1024) return (size / 1024) + " KB";
            else if (size < 1024 * 1024 * 1024) return (size / (1024 * 1024)) + " MB";
            else return (size / (1024 * 1024 * 1024)) + " GB";
        }

        _Icon GetElementIcon(bool isFolder, const string &in type) {
            if (isFolder) return _Icon::folder;
            string ext = type.ToLower();
            if (ext == "txt" || ext == "rtf" || ext == "csv" || ext == "json") return _Icon::fileText;
            if (ext == "pdf") return _Icon::filePdf;
            if (ext == "doc" || ext == "docx") return _Icon::fileWord;
            if (ext == "xls" || ext == "xlsx") return _Icon::fileExcel;
            if (ext == "ppt" || ext == "pptx") return _Icon::filePowerpoint;
            if (ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "gif") return _Icon::fileImage;
            if (ext == "rar" || ext == "zip" || ext == "7z") return _Icon::fileArchive;
            if (ext == "ogg" || ext == "mp3" || ext == "wav") return _Icon::fileAudio;
            if (ext == "mp4" || ext == "mov") return _Icon::fileVideo;
            if (ext == "cs" || ext == "cpp" || ext == "js" || ext == "java" || ext == "py") return _Icon::fileCode;
            if (ext == "epub") return _Icon::fileEpub;
            return _Icon::file;
        }

        string GetElementIconString(_Icon icon, bool isSelected) {
            switch(icon) {
                case _Icon::folder: return isSelected ? "\\$FD4"+Icons::FolderOpenO+"\\$g" : "\\$FD4"+Icons::FolderO+"\\$g";
                case _Icon::fileText: return Icons::FileTextO;
                case _Icon::filePdf: return Icons::FilePdfO;
                case _Icon::fileWord: return Icons::FileWordO;
                case _Icon::fileExcel: return Icons::FileExcelO;
                case _Icon::filePowerpoint: return Icons::FilePowerpointO;
                case _Icon::fileImage: return Icons::FileImageO;
                case _Icon::fileArchive: return Icons::FileArchiveO;
                case _Icon::fileAudio: return Icons::FileAudioO;
                case _Icon::fileVideo: return Icons::FileVideoO;
                case _Icon::fileCode: return Icons::FileCodeO;
                case _Icon::fileEpub: return Icons::FileEpub;
                default: return Icons::FileO;
            }
        }
    }

    enum ContextType {
        mainArea,
        selectedElements,
        pinnedElements
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
            Render_DeleteConfirmationPopup();

            switch (currentContextType) {
                case ContextType::mainArea:
                    Render_Context_MainArea();
                    break;
                case ContextType::selectedElements:
                    Render_Context_SelectedElements();
                    break;
                case ContextType::pinnedElements:
                    Render_Context_PinnedElements();
                    break;
            }
        }

        void Render_Rows() {
            Render_TopBar();
            Render_NavigationBar();
            Render_ActionBar();
            Render_ReturnBar();
        }

        void Render_Columns() {
            UI::BeginTable("FileExplorerTable", 3, UI::TableFlags::Resizable | UI::TableFlags::Borders);
            
            // Left Sidebar (Hardcoded Paths, Pinned Elements, Selected Elements)
            UI::TableNextColumn();
            UI::BeginChild("LeftSidebar", vec2(0, 0), true);
            Render_LeftSidebar();
            UI::EndChild();
            
            // Main Area (File listing, with some inforamtion about each file)
            UI::TableNextColumn();
            UI::BeginChild("MainArea", vec2(0, 0), true);
            Render_MainAreaBar();
            UI::EndChild();
            
            // Details Bar (Selected file details, more information about the selected file)
            UI::TableNextColumn();
            UI::BeginChild("DetailBar", vec2(0, 0), true);
            Render_DetailBar();
            UI::EndChild();
            
            UI::EndTable();
        }

        void Render_TopBar() {
            UI::PushStyleColor(UI::Col::Button, vec4(0, 0, 0, 0));
            UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0, 0, 0, 0));
            UI::PushStyleColor(UI::Col::ButtonActive, vec4(0, 0, 0, 0));


            // print(UI::GetWindowContentRegionWidth());
            UI::Text("File Explorer | " + "\\$888" + Meta::ExecutingPlugin().Name + "\\$g" + " | " + explorer.Config.id);
            
            UI::PopStyleColor(3);

            UI::SameLine();

            float availWidth = UI::GetContentRegionAvail().x;
            UI::Dummy(vec2(availWidth - 240, 0));
            UI::SameLine();

            vec2 buttonSize = vec2(60, 0);
            UI::PushStyleColor(UI::Col::Button, vec4(0, 0, 0, 0));
            UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0, 0, 0, 0));
            UI::PushStyleColor(UI::Col::ButtonActive, vec4(0, 0, 0, 0));
            uint currentPage = explorer.tab[0].CurrentPage + 1;
            uint totalPages = explorer.tab[0].TotalPages;
            string text = ("\\$AAA" + currentPage + "/" + totalPages + "\\$g");

            if (explorer.Config.enablePagination) {
                if (UI::Button(text, buttonSize)) {}
            } else {
                if (UI::Button("##", buttonSize)) {}
            }
            
            UI::PopStyleColor(3);

            UI::SameLine();

            if (UI::Button(Icons::WindowMinimize)) {
                utils.MinimizeWindow();
            }
            UI::SameLine();
            if (UI::Button(Icons::WindowMaximize)) {
                utils.MaximizeWindow();
            }
            UI::SameLine();
            if (UI::Button(Icons::WindowClose)) {
                explorer.Close();
            }
            UI::SameLine();
            if (UI::Button(Icons::WindowRestore)) {
                utils.BaseWindow();
            }

            UI::Separator();
        }

        void Render_NavigationBar() {
            float buttonWidth = 30.0;
            float totalWidth = UI::GetContentRegionAvail().x;
            float pathWidth = (totalWidth * 0.8f - buttonWidth * 3);
    
            if (explorer.Config.enableSearchBar) {
                pathWidth += explorer.Config.searchBarPadding;
            }

            float searchWidth = totalWidth - pathWidth - buttonWidth * 3;

            // Navigation Buttons
            if (explorer.tab[0].Navigation.HistoryIndex > 0) {
                if (UI::Button(Icons::ArrowLeft, vec2(buttonWidth, 0))) {
                    explorer.tab[0].Navigation.NavigateBack();
                }
            } else {
                utils.DisabledButton(Icons::ArrowLeft, vec2(buttonWidth, 0));
            }
            UI::SameLine();
            if (explorer.tab[0].Navigation.HistoryIndex < int(explorer.tab[0].Navigation.History.Length) - 1) {
                if (UI::Button(Icons::ArrowRight, vec2(buttonWidth, 0))) {
                    explorer.tab[0].Navigation.NavigateForward();
                }
            } else {
                utils.DisabledButton(Icons::ArrowRight, vec2(buttonWidth, 0));
            }
            UI::SameLine();
            if (explorer.tab[0].Navigation.CanMoveUpDirectory()) {
                if (UI::Button(Icons::ArrowUp, vec2(buttonWidth, 0))) {
                    explorer.tab[0].Navigation.MoveUpOneDirectory();
                }
            } else {
                utils.DisabledButton(Icons::ArrowUp, vec2(buttonWidth, 0));
            }
            UI::SameLine();
            
            if (
                explorer.tab[0].GetSelectedElement() !is null
            &&  explorer.tab[0].GetSelectedElement().isFolder
            &&  explorer.tab[0].GetSelectedElement().isSelected
            ) {
                if (UI::Button(Icons::ArrowDown)) { explorer.tab[0].Navigation.MoveIntoSelectedDirectory(); }
            } else {
                utils.DisabledButton(Icons::ArrowDown);
            }

            UI::SameLine();

            UI::PushItemWidth(pathWidth);
            string newPath = UI::InputText("##PathInput", explorer.tab[0].Navigation.GetPath());
            if (UI::IsKeyPressed(UI::Key::Enter)) {
                explorer.tab[0].LoadDirectory(newPath);
            }
            UI::PopItemWidth();

            if (explorer.Config.enableSearchBar) {
                UI::SameLine();
                UI::PushItemWidth(searchWidth - 110);

                UI::Text(Icons::Search + "");
                UI::SameLine();
                string newSearchQuery = UI::InputText("##SearchInput", explorer.Config.searchQuery);
                if (UI::IsKeyPressed(UI::Key::Enter) && newSearchQuery != explorer.Config.searchQuery) {
                    explorer.Config.searchQuery = newSearchQuery;
                    explorer.tab[0].ApplyFiltersAndSearch();
                }

                UI::PopItemWidth();
            }

            UI::Separator();
        }

        string newFilter = "";
        void Render_ActionBar() {
            if (!explorer.Config.enablePagination) {
                utils.DisabledButton(Icons::ChevronLeft);
                UI::SameLine();
                utils.DisabledButton(Icons::ChevronRight);
                UI::SameLine();
            } else {
                if (explorer.tab[0].CurrentPage > 0) {
                    if (UI::Button(Icons::ChevronLeft)) {
                        explorer.tab[0].CurrentPage--;
                    }
                } else {
                    utils.DisabledButton(Icons::ChevronLeft);
                }
                UI::SameLine();

                if (explorer.tab[0].CurrentPage < explorer.tab[0].TotalPages - 1) {
                    if (UI::Button(Icons::ChevronRight)) {
                        explorer.tab[0].CurrentPage++;
                    }
                } else {
                    utils.DisabledButton(Icons::ChevronRight);
                }
                UI::SameLine();
            }

            if (UI::Button(Icons::Refresh)) { utils.RefreshCurrentDirectory(); }
            UI::SameLine();
            if (UI::Button(Icons::FolderOpen)) { utils.OpenCurrentFolderInNativeFileExplorer(); }
            UI::SameLine();
            if (!utils.IsElementSelected()) {
                utils.DisabledButton(Icons::Trash); 
                UI::SameLine();
                utils.DisabledButton(Icons::Pencil);
                UI::SameLine();
                utils.DisabledButton(Icons::ThumbTack);
            } else {
                if (UI::Button(Icons::Trash)) { utils.DeleteSelectedElement(); }
                UI::SameLine();
                if (UI::Button(Icons::Pencil)) { utils.RENDER_RENAME_POPUP_FLAG = !utils.RENDER_RENAME_POPUP_FLAG; }
                UI::SameLine();
                if (UI::Button(Icons::ThumbTack)) { utils.PinSelectedElement(); }
            }
            UI::SameLine();
            if (UI::Button(Icons::Filter)) { UI::OpenPopup("filterMenu"); }

            if (UI::BeginPopup("filterMenu")) {
                UI::Text("All filters");
                UI::Separator();

                UI::PushStyleColor(UI::Col::Button, vec4(0, 0, 0, 0));
                UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0, 0, 0, 0));
                UI::PushStyleColor(UI::Col::ButtonActive, vec4(0, 0, 0, 0));

                if (UI::Button("Add filter", vec2(70, 0))) {}
                
                UI::PopStyleColor(3);

                UI::SameLine();
                newFilter = UI::InputText("##", newFilter);
                UI::SameLine();
                if (UI::Button("Add")) {
                    explorer.Config.filters.InsertLast(newFilter.ToLower());
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
                UI::Separator();
                UI::Text("Filter length: " + explorer.Config.filters.Length);

                if (UI::Button("Remove All Filters")) {
                    explorer.Config.filters.Resize(0);
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }

                for (uint i = 0; i < explorer.Config.filters.Length; i++) {
                    string filter = explorer.Config.filters[i];
                    bool isActive = explorer.Config.IsFilterActive(filter);

                    if (UI::BeginMenu(filter + (isActive ? "\\$888 (Active)" : "\\$888 (Inactive)"))) {
                        if (UI::MenuItem(isActive ? "Deactivate Filter" : "Activate Filter")) {
                            explorer.Config.ToggleFilterActive(filter);
                            explorer.tab[0].ApplyFiltersAndSearch();
                        }
                        
                        if (UI::MenuItem("Remove Filter")) {
                            explorer.Config.filters.RemoveAt(i);
                            explorer.Config.activeFilters.Delete(filter);
                            explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                        }
                        UI::EndMenu();
                    }
                }

                UI::EndPopup();
            }

            UI::SameLine();

            if (UI::Button(Icons::Sort)) { UI::OpenPopup("sortMenu"); }

            if (UI::BeginPopup("sortMenu")) {
                string orderButtonLabel = explorer.Config.sortingAscending ? Icons::ArrowUp : Icons::ArrowDown;
                if (UI::MenuItem(orderButtonLabel + " Order", "", explorer.Config.sortingAscending)) {
                    explorer.Config.sortingAscending = !explorer.Config.sortingAscending;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Sort Files Before Folders", "", explorer.Config.sortFilesBeforeFolders)) {
                    explorer.Config.sortFilesBeforeFolders = !explorer.Config.sortFilesBeforeFolders;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                UI::Separator();

                if (UI::MenuItem("Name", "", explorer.Config.sortingCriteria == SortingCriteria::name)) {
                    explorer.Config.sortingCriteria = SortingCriteria::name;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Name (Ignore File/Folder)", "", explorer.Config.sortingCriteria == SortingCriteria::nameIgnoreFileFolder)) {
                    explorer.Config.sortingCriteria = SortingCriteria::nameIgnoreFileFolder;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Size", "", explorer.Config.sortingCriteria == SortingCriteria::size)) {
                    explorer.Config.sortingCriteria = SortingCriteria::size;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Date Modified", "", explorer.Config.sortingCriteria == SortingCriteria::lastModified)) {
                    explorer.Config.sortingCriteria = SortingCriteria::lastModified;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Date Created", "", explorer.Config.sortingCriteria == SortingCriteria::createdDate)) {
                    explorer.Config.sortingCriteria = SortingCriteria::createdDate;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }

                UI::EndPopup();
            }

            UI::SameLine();

            // LAST ELEMENT LEFT SIDE
            // LARGE SEPERATOR
            // FIRST ELEMENT RIGHT SIDE

            UI::SameLine();
            UI::Dummy(vec2(UI::GetContentRegionAvail().x - 45, 0));
            UI::SameLine();
            if (UI::Button(Icons::Bars)) { UI::OpenPopup("burgerMenu"); }

            if (UI::BeginPopup("burgerMenu")) {
                if (UI::MenuItem("Hide Files", "", explorer.Config.hideFiles)) {
                    explorer.Config.hideFiles = !explorer.Config.hideFiles;
                    explorer.tab[0].ApplyVisibilitySettings();
                    utils.RefreshCurrentDirectory();
                }
                if (UI::MenuItem("Hide Folders", "", explorer.Config.hideFolders)) {
                    explorer.Config.hideFolders = !explorer.Config.hideFolders;
                    explorer.tab[0].ApplyVisibilitySettings();
                    utils.RefreshCurrentDirectory();
                }

                if (UI::BeginMenu("Pagination")) {
                    if (UI::MenuItem("Enable Pagination", "", explorer.Config.enablePagination)) {
                        explorer.Config.enablePagination = !explorer.Config.enablePagination;
                        utils.RefreshCurrentDirectory();
                    }

                    if (explorer.Config.enablePagination) {
                        explorer.Config.maxElementsPerPage = UI::SliderInt("Max Elements Per Page", explorer.Config.maxElementsPerPage, 1, 100);
                    }

                    UI::EndMenu();
                }

                if (UI::BeginMenu("Search Bar")) {
                    if (UI::MenuItem("Enable Search Bar", "", explorer.Config.enableSearchBar)) {
                        explorer.Config.enableSearchBar = !explorer.Config.enableSearchBar;
                        utils.RefreshCurrentDirectory();
                    }

                    if (explorer.Config.enableSearchBar) {
                        explorer.Config.searchBarPadding = UI::SliderInt("Search Bar Padding", explorer.Config.searchBarPadding, -200, 100);
                    }

                    // if (UI::MenuItem("Enable Recursive Search" + "\\$0f0 " + "Warning \\$g Extremely laggy, use with causion", "", explorer.Config.RecursiveSearch)) {
                    //     explorer.Config.RecursiveSearch = !explorer.Config.RecursiveSearch;
                    //     explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    // }

                    UI::EndMenu();
                }

                if (UI::MenuItem("Use Extra Warning When Deleting", "", explorer.Config.useExtraWarningWhenDeleting)) {
                    explorer.Config.useExtraWarningWhenDeleting = !explorer.Config.useExtraWarningWhenDeleting;
                }
                
                UI::Separator();

                if (UI::BeginMenu("Visible Columns")) {
                    array<string> orderedColumns = { "ico", "name", "type", "size", "lastModified", "createdDate" };
                    for (uint i = 0; i < orderedColumns.Length; i++) {
                        string col = orderedColumns[i];
                        bool isVisible = explorer.Config.IsColumnVisible(col);
                        if (UI::MenuItem(col, "", isVisible, true)) {
                            explorer.Config.ToggleColumnVisibility(col);
                            utils.RefreshCurrentDirectory();
                        }
                    }
                    UI::EndMenu();
                }

                if (UI::BeginMenu("File Name Display Options")) {
                    if (UI::MenuItem("Default File Name", "", explorer.Config.fileNameDisplayOption == 0)) {
                        explorer.Config.fileNameDisplayOption = 0;
                        utils.RefreshCurrentDirectory();
                    }
                    if (UI::MenuItem("No Formatting", "", explorer.Config.fileNameDisplayOption == 1)) {
                        explorer.Config.fileNameDisplayOption = 1;
                        utils.RefreshCurrentDirectory();
                    }
                    if (UI::MenuItem("ManiaPlanet Formatting", "", explorer.Config.fileNameDisplayOption == 2)) {
                        explorer.Config.fileNameDisplayOption = 2;
                        utils.RefreshCurrentDirectory();
                    }
                    UI::EndMenu();
                }

                UI::Separator();

                if (UI::BeginMenu("Valid/Invalid File Colors")) {
                    UI::Text("Valid File Color");
                    explorer.Config.validFileColor = UI::InputColor4("##", explorer.Config.validFileColor);
                    UI::Text("Invalid File Color");
                    explorer.Config.invalidFileColor = UI::InputColor4("##", explorer.Config.invalidFileColor);
                    UI::Text("Valid Folder Color");
                    explorer.Config.validFolderColor = UI::InputColor4("##", explorer.Config.validFolderColor);
                    UI::Text("Invalid Folder Color");
                    explorer.Config.invalidFolderColor = UI::InputColor4("##", explorer.Config.invalidFolderColor);

                    UI::EndMenu();
                }

                if (UI::BeginMenu("Reset Settings")) {
                    if (UI::MenuItem("Reset All Settings")) {
                        explorer.Config.ResetSettings();
                        explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    }
                    UI::EndMenu();
                }

                explorer.Config.SaveSettings();

                UI::EndPopup();
            }

            UI::Separator();
        }

        string newFileName = "";
        void Render_RenamePopup() {
            if (utils.RENDER_RENAME_POPUP_FLAG) {
                UI::OpenPopup("RenamePopup");
                utils.RENDER_RENAME_POPUP_FLAG = false;
            }

            if (UI::BeginPopupModal("RenamePopup", UI::WindowFlags::AlwaysAutoResize)) {
                UI::Text("Enter new name:");
                newFileName = UI::InputText("##RenameInput", newFileName);
                if (UI::Button("Rename")) {
                    utils.RenameSelectedElement(newFileName);
                    newFileName = "";
                    UI::CloseCurrentPopup();
                }
                UI::SameLine();
                if (UI::Button("Cancel")) {
                    newFileName = "";
                    UI::CloseCurrentPopup();
                }
                UI::EndPopup();
            }
        }

        void Render_DeleteConfirmationPopup() {
            if (utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG && explorer.Config.useExtraWarningWhenDeleting) {
                UI::OpenPopup("DeleteConfirmationPopup");
            } else if (utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG && !explorer.Config.useExtraWarningWhenDeleting) {
                ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();

                if (selectedElement !is null && selectedElement.isFolder) {
                    log("Deleting folder with contents: " + selectedElement.path, LogLevel::Info, 1885, "Render_DeleteConfirmationPopup");
                    IO::DeleteFolder(selectedElement.path, true);
                    utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
            }

            if (UI::BeginPopupModal("DeleteConfirmationPopup", utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG, UI::WindowFlags::AlwaysAutoResize)) {
                ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();

                UI::Text("Are you sure you want to delete this folder and all its contents?");
                UI::Separator();
                if (UI::Button("Yes, delete all")) {
                    if (selectedElement !is null && selectedElement.isFolder) {
                        log("Deleting folder with contents: " + selectedElement.path, LogLevel::Info, 1899, "Render_DeleteConfirmationPopup");
                        IO::DeleteFolder(selectedElement.path, true);
                        utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
                        explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    } else {
                        log("No selected element or element is not a folder.", LogLevel::Error, 1904, "Render_DeleteConfirmationPopup");
                    }
                    UI::CloseCurrentPopup();
                }
                UI::SameLine();
                if (UI::Button("Cancel")) {
                    utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
                    UI::CloseCurrentPopup();
                }
                UI::EndPopup();
            }
        }


        void Render_ReturnBar() {
            if (explorer.Config.mustReturn) {
                bool validReturnAmount = explorer.Config.selectedPaths.Length >= uint(explorer.Config.minMaxReturnAmount.x) &&
                                        (explorer.Config.selectedPaths.Length <= uint(explorer.Config.minMaxReturnAmount.y) || explorer.Config.minMaxReturnAmount.y == -1);

                if (validReturnAmount) {
                    array<string> validSelections;
                    for (uint i = 0; i < explorer.Config.selectedPaths.Length; i++) {
                        ElementInfo@ element = explorer.GetElementInfo(explorer.Config.selectedPaths[i]);

                        if (utils.IsValidReturnElement(element)) {
                            validSelections.InsertLast(element.path);
                        }
                    }

                    if (validSelections.Length > 0) {
                        if (UI::Button("Return Selected Paths")) {
                            explorer.exports.SetSelectionComplete(validSelections);
                            explorer.Close();
                        }
                    } else {
                        utils.DisabledButton("Return Selected Paths");
                    }
                } else {
                    utils.DisabledButton("Return Selected Paths");
                }

                UI::SameLine();
                UI::Text("Selected element amount: " + explorer.Config.selectedPaths.Length);
                UI::Separator();
            }
        }

        void Render_LeftSidebar() {
            UI::Text("Hardcoded Paths");
            UI::Separator();
            Render_HardcodedPaths();
            UI::Separator();

            UI::Text("Pinned Elements");
            UI::Separator();
            Render_PinnedElements();
            UI::Separator();

            UI::Text("Selected Elements");
            UI::Separator();
            Render_SelectedElements();
            UI::Separator();
        }

        void Render_HardcodedPaths() {
            vec4 defaultColor = vec4(1, 1, 1, 1);    // White         (default)
            vec4 grayColor = vec4(0.7, 0.7, 0.7, 1); // Slightly gray

            string currentPath = explorer.tab[0].Navigation.GetPath();

            UI::PushStyleColor(UI::Col::Text, Path::SanitizeFileName(currentPath) == Path::SanitizeFileName(IO::FromUserGameFolder("")) ? grayColor : defaultColor);
            if (UI::Selectable(Icons::Home + " Trackmania Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromUserGameFolder(""));
            }
            UI::PopStyleColor();

            UI::PushStyleColor(UI::Col::Text, Path::SanitizeFileName(currentPath) == Path::SanitizeFileName(IO::FromUserGameFolder("Maps/")) ? grayColor : defaultColor);
            if (UI::Selectable(Icons::Map + " Trackmania Maps Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromUserGameFolder("Maps/"));
            }
            UI::PopStyleColor();

            UI::PushStyleColor(UI::Col::Text, Path::SanitizeFileName(currentPath) == Path::SanitizeFileName(IO::FromUserGameFolder("Replays/")) ? grayColor : defaultColor);
            if (UI::Selectable(Icons::SnapchatGhost + " Trackmania Replays Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromUserGameFolder("Replays/"));
            }
            UI::PopStyleColor();

            UI::PushStyleColor(UI::Col::Text, Path::SanitizeFileName(currentPath) == Path::SanitizeFileName(IO::FromAppFolder("")) ? grayColor : defaultColor);
            if (UI::Selectable(Icons::Trademark + " Trackmania App Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromAppFolder(""));
            }
            UI::PopStyleColor();

            UI::PushStyleColor(UI::Col::Text, Path::SanitizeFileName(currentPath) == Path::SanitizeFileName(IO::FromDataFolder("")) ? grayColor : defaultColor);
            if (UI::Selectable(Icons::Heartbeat + " Openplanet Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromDataFolder(""));
            }
            UI::PopStyleColor();

            UI::PushStyleColor(UI::Col::Text, Path::SanitizeFileName(currentPath) == Path::SanitizeFileName(IO::FromStorageFolder("")) ? grayColor : defaultColor);
            if (UI::Selectable(Icons::Inbox + " Openplanet Storage Folder", false)) {
                explorer.tab[0].LoadDirectory(IO::FromStorageFolder(""));
            }
            UI::PopStyleColor();
        }

        void Render_PinnedElements() {
            if (explorer.Config.pinnedElements.Length == 0) {
                UI::Text("\\$888" + "No pinned elements.");
            } else {
                for (uint i = 0; i < explorer.Config.pinnedElements.Length; i++) {
                    string path = explorer.Config.pinnedElements[i];
                    ElementInfo@ element = explorer.GetElementInfo(path);

                    if (element !is null) {
                        SelectableWithClickCheck(element, ContextType::pinnedElements);
                    } else {
                        explorer.Config.pinnedElements.RemoveAt(i);
                        explorer.Config.SaveSettings();
                        i--;
                    }
                }
            }
        }

        void Render_Context_PinnedElements() {
            if (explorer.ui.openContextMenu) {
                UI::OpenPopup("PinnedElementContextMenu");
                explorer.ui.openContextMenu = false;
            }

            if (UI::BeginPopup("PinnedElementContextMenu")) {
                ElementInfo@ element = explorer.tab[0].GetSelectedElement();
                if (element !is null) {
                    if (UI::MenuItem("Add to Selected Elements")) {
                        if (explorer.Config.selectedPaths.Find(element.path) == -1) {
                            explorer.Config.selectedPaths.InsertLast(element.path);
                            utils.TruncateSelectedPathsIfNeeded();
                        }
                    }

                    if (UI::MenuItem("Remove from Pinned Elements")) {
                        int index = explorer.Config.pinnedElements.Find(element.path);
                        if (index != -1) {
                            explorer.Config.pinnedElements.RemoveAt(index);
                            explorer.Config.SaveSettings();
                        }
                    }

                    if (UI::MenuItem("Rename Pinned Element")) {
                        utils.RENDER_RENAME_POPUP_FLAG = true;
                    }
                } else {
                    int pinnedPath = explorer.Config.pinnedElements.Find(element.path);
                    explorer.Config.pinnedElements.RemoveAt(pinnedPath);
                }
                UI::EndPopup();
            }
        }

        void Render_SelectedElements() {
            for (uint i = 0; i < explorer.Config.selectedPaths.Length; i++) {
                string path = explorer.Config.selectedPaths[i];
                ElementInfo@ element = explorer.GetElementInfo(path);

                SelectableWithClickCheck(element, ContextType::selectedElements);
            }
        }

        void Render_Context_SelectedElements() {
            if (openContextMenu) {
                UI::OpenPopup("SelectedElementContextMenu");
                openContextMenu = false;
            }

            if (UI::BeginPopup("SelectedElementContextMenu")) {
                ElementInfo@ element = explorer.tab[0].GetSelectedElement();
                if (element !is null) {
                    if (UI::MenuItem("Remove from Selected Elements")) {
                        int index = explorer.Config.selectedPaths.Find(element.path);
                        if (index != -1) {
                            explorer.Config.selectedPaths.RemoveAt(index);
                        }
                    }

                    if (UI::MenuItem("Pin Element")) {
                        utils.PinSelectedElement();
                    }
                }
                UI::EndPopup();
            }
        }

        void Render_MainAreaBar() {
            if (explorer.IsIndexing) {
                UI::Text(explorer.IndexingMessage);
            } else if (explorer.tab[0].Elements.Length == 0) {
                UI::Text("No elements to display.");
            } else {
                array<string> orderedColumns = { "ico", "name", "type", "size", "lastModified", "createdDate" };
                uint columnCount = 0;

                for (uint i = 0; i < orderedColumns.Length; i++) {
                    bool isVisible = explorer.Config.IsColumnVisible(orderedColumns[i]);
                    if (isVisible) {
                        columnCount++;
                    }
                }

                if (columnCount > 0) {
                    UI::BeginTable("FilesTable", columnCount, UI::TableFlags::Resizable | UI::TableFlags::Borders | UI::TableFlags::SizingFixedSame);

                    for (uint i = 0; i < orderedColumns.Length; i++) {
                        if (explorer.Config.IsColumnVisible(orderedColumns[i])) {
                            if (orderedColumns[i] == "ico") {
                                UI::TableSetupColumn(orderedColumns[i], UI::TableColumnFlags::None, 30.0f);
                            } else {
                                UI::TableSetupColumn(orderedColumns[i]);
                            }
                        }
                    }

                    UI::TableHeadersRow();

                    uint startIndex = explorer.Config.enablePagination ? explorer.tab[0].CurrentPage * explorer.Config.maxElementsPerPage : 0;
                    uint endIndex = explorer.Config.enablePagination ? Math::Min(startIndex + explorer.Config.maxElementsPerPage, explorer.tab[0].Elements.Length) : explorer.tab[0].Elements.Length;

                    for (uint i = startIndex; i < endIndex; i++) {
                        if (i >= explorer.tab[0].Elements.Length) { break; }
                        
                        ElementInfo@ element = explorer.tab[0].Elements[i];
                        if (!element.shouldShow) continue;

                        UI::TableNextRow();
                        uint colIndex = 0;
                        for (uint j = 0; j < orderedColumns.Length; j++) {
                            if (explorer.Config.IsColumnVisible(orderedColumns[j])) {
                                UI::TableSetColumnIndex(colIndex++);
                                string col = orderedColumns[j];
                                
                                // FIXME: The column size is not set on first load, this has to be done manually by the user, which is not ideal...
                                if (col == "ico") {
                                    UI::Text(explorer.GetElementIconString(element.icon, element.isSelected));
                                } else if (col == "name") {
                                    SelectableWithClickCheck(element, ContextType::mainArea);
                                } else if (col == "type") {
                                    UI::Text(element.type);
                                } else if (col == "size") {
                                    UI::Text(element.isFolder ? "-" : element.size);
                                } else if (col == "lastModified") {
                                    UI::Text(Time::FormatString("%Y-%m-%d %H:%M:%S", element.lastModifiedDate));
                                } else if (col == "createdDate") {
                                    UI::Text(Time::FormatString("%Y-%m-%d %H:%M:%S", element.creationDate));
                                }
                            }
                        }
                    }

                    UI::EndTable();
                } else {
                    UI::Text("No columns selected to display.");
                }
            }
        }

        void Render_Context_MainArea() {
            if (openContextMenu) {
                UI::OpenPopup("MainElementContextMenu");
                openContextMenu = false;
            }

            if (UI::BeginPopup("MainElementContextMenu")) {
                ElementInfo@ element = explorer.tab[0].GetSelectedElement();
                if (element !is null) {
                    bool canAddMore = explorer.Config.selectedPaths.Length < uint(explorer.Config.minMaxReturnAmount.y) || explorer.Config.minMaxReturnAmount.y == -1;
                    
                    bool isValidElement = utils.IsValidReturnElement(element);

                    if (canAddMore && isValidElement) {
                        if (UI::MenuItem("Add to Selected Elements", "", false)) {
                            if (explorer.Config.selectedPaths.Find(element.path) == -1) {
                                explorer.Config.selectedPaths.InsertLast(element.path);
                                utils.TruncateSelectedPathsIfNeeded();
                            }
                        }
                    } else {
                        UI::MenuItem("Add to Selected Elements", "", false, false);
                    }

                    if (canAddMore && isValidElement) {
                        if (UI::MenuItem("Quick return")) {
                            explorer.exports.SetSelectionComplete({ element.path });
                            explorer.exports.selectionComplete = true;
                            explorer.Close();
                        }
                    } else {
                        UI::MenuItem("Quick return", "", false, false);
                    }

                    if (UI::MenuItem("Rename Element")) {
                        utils.RENDER_RENAME_POPUP_FLAG = true;
                    }

                    if (UI::MenuItem("Pin Element")) {
                        utils.PinSelectedElement();
                    }

                    if (UI::MenuItem("Delete Element")) {
                        utils.DeleteSelectedElement();
                    }
                }
                UI::EndPopup();
            }
        }

        void SelectableWithClickCheck(ElementInfo@ element, ContextType contextType) {
            string displayName = element.name;
            switch (explorer.Config.fileNameDisplayOption) {
                case 1:
                    displayName = Text::StripFormatCodes(element.name);
                    break;
                case 2:
                    displayName = element.name.Replace("$", "\\$");
                    break;
                default:
                    displayName = element.name;
            }

            bool isValid = utils.IsValidReturnElement(element);

            vec4 textColor = element.isFolder
                            ? (isValid ? explorer.Config.validFolderColor : explorer.Config.invalidFolderColor)
                            : (isValid ? explorer.Config.validFileColor : explorer.Config.invalidFileColor);

            UI::PushStyleColor(UI::Col::Text, textColor);
            UI::Selectable(displayName, element.isSelected);
            UI::PopStyleColor();

            if (UI::IsItemHovered() && UI::IsMouseClicked(UI::MouseButton::Left) && (UI::IsKeyDown(UI::Key::LeftCtrl) || UI::IsKeyDown(UI::Key::RightCtrl)) ) {
                HandleElementSelection(element, EnterType::ControlClick, contextType);
            } else if (UI::IsItemHovered() && UI::IsMouseClicked(UI::MouseButton::Left)) {
                HandleElementSelection(element, EnterType::LeftClick, contextType);
            } else if (UI::IsItemHovered() && UI::IsMouseClicked(UI::MouseButton::Right)) {
                HandleElementSelection(element, EnterType::RightClick, contextType);
            }
        }

        void HandleElementSelection(ElementInfo@ element, EnterType enterType, ContextType contextType) {
            bool canAddMore = explorer.Config.selectedPaths.Length < uint(explorer.Config.minMaxReturnAmount.y) || explorer.Config.minMaxReturnAmount.y == -1;
            bool isValidForSelection = utils.IsValidReturnElement(element);

            uint64 currentTime = Time::Now;
            const uint64 doubleClickThreshold = 600; // 0.6 seconds

            // Handle right- and control-click (context menu)
            if (enterType == EnterType::RightClick || enterType == EnterType::ControlClick) {
                // Set as normal click first (to fix selection issues), then right click
                if (contextType == ContextType::mainArea) {
                    for (uint i = 0; i < explorer.tab[0].Elements.Length; i++) {
                        explorer.tab[0].Elements[i].isSelected = false;
                    }
                    element.isSelected = true;
                    element.lastSelectedTime = currentTime;
                    element.lastClickTime = currentTime;
                    @explorer.CurrentSelectedElement = element;
                }

                openContextMenu = true;
                currentContextType = contextType;
                @explorer.CurrentSelectedElement = element;
                return;
            }

            if (!isValidForSelection) return;

            // Handle double-click for selection or folder navigation
            if (contextType == ContextType::pinnedElements || element.isSelected) {
                if (currentTime - element.lastClickTime <= doubleClickThreshold) {
                    if (contextType == ContextType::pinnedElements) {
                        if (canAddMore && explorer.Config.selectedPaths.Find(element.path) == -1) {
                            explorer.Config.selectedPaths.InsertLast(element.path);
                            utils.TruncateSelectedPathsIfNeeded();
                        }
                        @explorer.CurrentSelectedElement = element;
                    } else if (element.isFolder) {
                        explorer.tab[0].Navigation.MoveIntoSelectedDirectory();
                    } else if (canAddMore) {
                        if (explorer.Config.selectedPaths.Find(element.path) == -1) {
                            explorer.Config.selectedPaths.InsertLast(element.path);
                            utils.TruncateSelectedPathsIfNeeded();
                        }
                        @explorer.CurrentSelectedElement = element;
                    }
                } else {
                    element.lastClickTime = currentTime;
                }
            } 
            // Handle normal left-click for selection
            else if (enterType == EnterType::LeftClick) {
                if (contextType != ContextType::pinnedElements) {
                    for (uint i = 0; i < explorer.tab[0].Elements.Length; i++) {
                        explorer.tab[0].Elements[i].isSelected = false;
                    }
                }
                element.isSelected = true;
                element.lastSelectedTime = currentTime;
                element.lastClickTime = currentTime;
                @explorer.CurrentSelectedElement = element;
            }
        }

        ContextType currentContextType;
        bool openContextMenu = false;

        void Render_DetailBar() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            if (selectedElement !is null) {
                UI::Text("Selected Element Details");
                UI::Separator();
                UI::Text("ICO: " + explorer.GetElementIconString(selectedElement.icon, selectedElement.isSelected));
                UI::Text("Name: " + selectedElement.name);
                UI::Text("Path: " + selectedElement.path);
                UI::Text("Size: " + selectedElement.size);
                UI::Text("Type: " + selectedElement.type);
                UI::Text("Last Modified: " + Time::FormatString("%Y-%m-%d %H:%M:%S", selectedElement.lastModifiedDate));
                UI::Text("Selected Time: " + selectedElement.lastSelectedTime);

                if (selectedElement.type.ToLower() == "gbx") {
                    UI::Separator();
                    UI::Text("GBX File Detected - Displaying GBX Info");

                    dictionary gbxMetadata = selectedElement.gbxMetadata;

                    if (gbxMetadata.IsEmpty()) {
                        UI::Text("No metadata found.");
                    }

                    if (true) UI::Text("Selected element " + selectedElement.path);

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
    }

/* ------------------------ Handle Button Clicks ------------------------ */
    enum EnterType {
        None,
        LeftClick,
        RightClick,
        DoubleClick,
        ControlClick
    }
/* ------------------------ End Handle Button Clicks ------------------------ */

    FileExplorer@ fe_GetExplorerById(const string &in id) {
        string pluginName = Meta::ExecutingPlugin().Name;
        string sessionKey = pluginName + "::" + id;
        FileExplorer@ explorer;
        explorersByPlugin.Get(sessionKey, @explorer);
        return explorer;
    }

    void RenderFileExplorer() {
        string pluginName = Meta::ExecutingPlugin().Name;

        array<string> keys = explorersByPlugin.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            string sessionKey = keys[i];

            if (sessionKey.StartsWith(pluginName + "::")) {
                FileExplorer@ explorer;
                if (explorersByPlugin.Get(sessionKey, @explorer)) {
                    string sessionId = sessionKey.SubStr(pluginName.Length + 2); // Skip "pluginName::"
                    string windowTitle = "File Explorer " + sessionId;

                    if (!explorer.showInterface) return;
                    if (UI::Begin(windowTitle, explorer.showInterface, UI::WindowFlags::NoTitleBar)) {
                        explorer.ui.Render_FileExplorer();
                    }
                    UI::End();
                }
            }
        }
    }

    dictionary explorersByPlugin;

    void fe_Start(
        bool _mustReturn,
        string id,
        vec2 _minmaxReturnAmount = vec2(1, -1),
        string _path = "",
        string _searchQuery = "",
        string[] _filters = array<string>(),
        string[] _canOnlyReturn = array<string>()
    ) {
        string pluginName = Meta::ExecutingPlugin().Name;

        string sessionKey = pluginName + "::" + id;

        if (explorersByPlugin.Exists(sessionKey)) {
            NotifyError("Error", "Session ID '" + id + "' already in use by this plugin. Please contact the plugin developer if this is a signed plugin (or if you are the dev, please fix :peepoShy:).", 20000);
            return;
        }

        Config config;
        config.mustReturn = _mustReturn;
        config.id = id;
        config.minMaxReturnAmount = _minmaxReturnAmount;
        config.path = _path;
        config.searchQuery = _searchQuery;
        config.filters = _filters;
        config.canOnlyReturn = _canOnlyReturn;

        FileExplorer@ newExplorer = FileExplorer(config, id);

        explorersByPlugin.Set(sessionKey, @newExplorer);

        newExplorer.Open(config);
    }


    void fe_ForceClose(string id = "*") {
        string pluginName = Meta::ExecutingPlugin().Name;
        
        if (id == "*") {
            array<string> keys = explorersByPlugin.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string sessionKey = keys[i];
                if (sessionKey.StartsWith(pluginName + "::")) {
                    FileExplorer@ explorer;
                    if (explorersByPlugin.Get(sessionKey, @explorer)) {
                        explorer.Close();
                    }
                    explorersByPlugin.Delete(sessionKey);
                }
            }
            log("All file explorer instances for this plugin have been closed.", LogLevel::Error, 2473, "fe_ForceClose");
            return;
        }

        string sessionKey = pluginName + "::" + id;
        FileExplorer@ explorer;
        if (explorersByPlugin.Get(sessionKey, @explorer)) {
            explorer.Close();
            explorersByPlugin.Delete(sessionKey);
            log("File explorer instance '" + id + "' has been closed.", LogLevel::Info, 2482, "fe_ForceClose");
        } else {
            NotifyError("Error", "Session ID '" + id + "' not found for this plugin.", 20000);
        }
    }
}

/* ------------------------ GBX Parsing ------------------------ */

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

    int64 startTime = Time::Now;

    for (uint i = 0; i < chunks.Length; i++) {
        MemoryBuffer chunkBuffer = mapFile.Read(chunks[i].ChunkSize);
        if (   chunks[i].ChunkId == 50933761 // Maps /*50933761*/ (Sometimes "50606082"??)
            || chunks[i].ChunkId == 50606082 // Replays
            || chunks[i].ChunkId == 50606082 // Challenges
            ) {
            int stringLength = chunkBuffer.ReadInt32();
            xmlString = chunkBuffer.ReadString(stringLength);
            break;
        }

        if (Time::Now - startTime > 300) {
            log("Error: Timeout while reading GBX header for file: " + path, LogLevel::Error, 2534, "ReadGbxHeader");
            mapFile.Close();
            return metadata;
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
        } else {
            log("Error: Missing header node in GBX file: " + path, LogLevel::Error, 2567, "ReadGbxHeader");
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


/* ------------------------ Functions / Variables that have to be in the global namespace ------------------------ */


// Sorry, but due to limitations in Openplanet the "Render" function has to be in the global namespace.
// If you are using this function in your own project please add ` FILE_EXPLORER_BASE_RENDERER ` to your own 
// render pipeline, usually one of the "Render", or "RenderInterface" functions.
// If this is not done, the File Explorer will not work as intended.

// ----- REMOVE THIS IF YOU HAVE ANY RENDER FUNCTION IN YOUR OWN CODE (also read the comment above) ----- //
/*
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
        "example", // id
        vec2(1, -1), // _minmaxReturnAmount
        IO::FromUserGameFolder("Replays/"), // path // Change to Maps/ when done with general gbx detection is done
        "", // searchQuery
        { "replay", "ghost" }, // filters
        { "", "ghost" } // canOnlyReturn
    );
}

// Remove after testing
void Render() {
    FILE_EXPLORER_BASE_RENDERER();
    // FILE_EXPLORER_V1_BASE_RENDERER(); // Used for comparison, should be removed on release

    
    if (UI::Begin(Icons::UserPlus + " File Explorer", S_windowOpen, UI::WindowFlags::AlwaysAutoResize)) {
        if (UI::Button("Open File Explorer")) {
            OpenFileExplorerExample();
        }
        UI::Text("Control proper: " + tostring(UI::IsKeyDown(UI::Key::LeftCtrl)));
        UI::Text("Control proper: " + tostring(UI::IsKeyDown(UI::Key::RightCtrl)));
    }
    UI::End();
}