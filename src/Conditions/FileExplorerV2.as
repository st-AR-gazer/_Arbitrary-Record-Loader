// :Yayy: FileExplorerV2 go brrrrr
// Required version 1.26.31

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

        - Game crashes when 'minimize' or 'basesize' buttons are clicked...

*/
namespace FileExplorer {
    bool showInterface = false;
    FileExplorer@ explorer;

    // ONLY CHANGE THIS IF A DESTRUCTIVE CHANGE IS MADE TO THE FILE EXPLORER SAVE FILE FORMAT, IDEALY 
    // THIS SHOULD NEVER 'CHANGE', JUST BE ADDED TOO, BUT FOR SOME FUTURE PROOFING, THIS WAS ADDED...
    const int FILE_EXPLORER_SETTINGS_VERSION = 1;
    
    class Config {
        bool MustReturn;
        vec2 MinMaxReturnAmount;
        array<string> FileTypeMustBe;
        array<string> CanOnlyReturn;

        string Path;
        string SearchQuery;
        array<string> Filters;
        dictionary ActiveFilters;
        array<string> SelectedPaths;
        array<string> PinnedElements;

        // UI-related settings
        bool HideFiles = false;
        bool HideFolders = false;
        bool EnablePagination = false;
        bool UseExtraWarningWhenDeleting = true;
        bool RecursiveSearch = false;
        int MaxElementsPerPage = 30;
        dictionary ColumnsToShow;
        int FileNameDisplayOption = 0; // 0: Default, 1: No Formatting, 2: ManiaPlanet Formatting
        bool EnableSearchBar = true;
        int SearchBarPadding = 0;

        vec4 ValidFileColor = vec4(1, 1, 1, 1);     // Default: White
        vec4 InvalidFileColor = vec4(1, 0, 0, 1);   // Default: Red
        vec4 ValidFolderColor = vec4(1, 1, 1, 1);   // Default: White
        vec4 InvalidFolderColor = vec4(1, 0, 0, 1); // Default: Red

        SortingCriteria SortingCriteria = SortingCriteria::Name;
        bool SortingAscending = true;
        bool SortFilesBeforeFolders = false;

        /*const*/ string settingsDirectory = IO::FromDataFolder("Plugin_FileExplorer_Settings");
        /*const*/ string settingsFilePath = Path::Join(settingsDirectory, "FileExplorerSettings.json");

        Config() {
            MustReturn = false;
            Path = "";
            SearchQuery = "";
            Filters = array<string>();
            SelectedPaths = array<string>();
            PinnedElements = array<string>();

            ColumnsToShow.Set("ico", true);
            ColumnsToShow.Set("name", true);
            ColumnsToShow.Set("type", true);
            ColumnsToShow.Set("size", true);
            ColumnsToShow.Set("lastModified", true);
            ColumnsToShow.Set("createdDate", true);
        }

        void LoadSettings() {
            if (!IO::FolderExists(settingsDirectory)) {
                IO::CreateFolder(settingsDirectory);
            }

            if (IO::FileExists(settingsFilePath)) {
                string jsonString = explorer.utils.ReadFileToEnd(settingsFilePath);
                Json::Value settings = Json::Parse(jsonString);

                bool foundVersion = false;

                for (uint i = 0; i < settings.Length; i++) {
                    Json::Value versionedSettings = settings[i];
                    
                    if (versionedSettings.HasKey("version") && versionedSettings["version"] == FILE_EXPLORER_SETTINGS_VERSION) {
                        foundVersion = true;
                        Json::Value explorerSettings = versionedSettings["settings"];

                        if (explorerSettings.HasKey("PinnedElements")) {
                            Json::Value pins = explorerSettings["PinnedElements"];
                            PinnedElements.Resize(pins.Length);
                            for (uint i = 0; i < pins.Length; i++) {
                                PinnedElements[i] = pins[i];
                            }
                        }
                        if (explorerSettings.HasKey("HideFiles")) {
                            HideFiles = explorerSettings["HideFiles"];
                        }
                        if (explorerSettings.HasKey("HideFolders")) {
                            HideFolders = explorerSettings["HideFolders"];
                        }
                        if (explorerSettings.HasKey("EnablePagination")) {
                            EnablePagination = explorerSettings["EnablePagination"];
                        }
                        if (explorerSettings.HasKey("UseExtraWarningWhenDeleting")) {
                            UseExtraWarningWhenDeleting = explorerSettings["UseExtraWarningWhenDeleting"];
                        }
                        if (explorerSettings.HasKey("RecursiveSearch")) {
                            RecursiveSearch = explorerSettings["RecursiveSearch"];
                        }
                        if (explorerSettings.HasKey("FileNameDisplayOption")) {
                            FileNameDisplayOption = explorerSettings["FileNameDisplayOption"];
                        }
                        if (explorerSettings.HasKey("ColumnsToShow")) {
                            Json::Value cols = explorerSettings["ColumnsToShow"];
                            for (uint i = 0; i < cols.GetKeys().Length; i++) {
                                string col = cols.GetKeys()[i];
                                ColumnsToShow.Set(col, bool(cols[col]));
                            }
                        }
                        if (explorerSettings.HasKey("MaxElementsPerPage")) {
                            MaxElementsPerPage = explorerSettings["MaxElementsPerPage"];
                        }
                        if (explorerSettings.HasKey("SearchBarPadding")) {
                            SearchBarPadding = explorerSettings["SearchBarPadding"];
                        }
                        if (explorerSettings.HasKey("EnableSearchBar")) {
                            EnableSearchBar = explorerSettings["EnableSearchBar"];
                        }
                        if (explorerSettings.HasKey("SortingCriteria")) {
                            SortingCriteria = explorer.utils.StringToSortingCriteria(explorerSettings["SortingCriteria"]);
                        }
                        if (explorerSettings.HasKey("SortingAscending")) {
                            SortingAscending = explorerSettings["SortingAscending"];
                        }
                        if (explorerSettings.HasKey("SortFilesBeforeFolders")) {
                            SortFilesBeforeFolders = explorerSettings["SortFilesBeforeFolders"];
                        }
                        if (settings.HasKey("ValidFileColor")) {
                            ValidFileColor = StringToVec4(settings["ValidFileColor"]);
                        }
                        if (settings.HasKey("InvalidFileColor")) {
                            InvalidFileColor = StringToVec4(settings["InvalidFileColor"]);
                        }
                        if (settings.HasKey("ValidFolderColor")) {
                            ValidFolderColor = StringToVec4(settings["ValidFolderColor"]);
                        }
                        if (settings.HasKey("InvalidFolderColor")) {
                            InvalidFolderColor = StringToVec4(settings["InvalidFolderColor"]);
                        }
                        
                        break;
                    }
                }

                if (!foundVersion) {
                    log("Settings version mismatch or not found. Settings cannot be loaded.", LogLevel::Error, 156, "LoadSettings");
                }
            }
        }

        void SaveSettings() {
            if (!IO::FolderExists(settingsDirectory)) {
                IO::CreateFolder(settingsDirectory);
            }

            Json::Value settings = Json::Array();
            if (IO::FileExists(settingsFilePath)) {
                string jsonString = explorer.utils.ReadFileToEnd(settingsFilePath);
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

            explorer.utils.WriteFile(settingsFilePath, Json::Write(settings));

            // log("Settings saved to: " + settingsFilePath, LogLevel::Info, 276, "SaveSettings");
        }

        Json::Value GetCurrentSettings() {
            Json::Value explorerSettings = Json::Object();

            Json::Value pins = Json::Array();
            for (uint i = 0; i < PinnedElements.Length; i++) {
                pins.Add(PinnedElements[i]);
            }
            explorerSettings["PinnedElements"] = pins;

            explorerSettings["HideFiles"] = HideFiles;
            explorerSettings["HideFolders"] = HideFolders;
            explorerSettings["EnablePagination"] = EnablePagination;
            explorerSettings["UseExtraWarningWhenDeleting"] = UseExtraWarningWhenDeleting;
            explorerSettings["RecursiveSearch"] = RecursiveSearch;
            explorerSettings["FileNameDisplayOption"] = FileNameDisplayOption;

            Json::Value cols = Json::Object();
            array<string> colKeys = ColumnsToShow.GetKeys();
            for (uint i = 0; i < colKeys.Length; i++) {
                string col = colKeys[i];
                bool value = false;
                ColumnsToShow.Get(col, value);
                cols[col] = value;
            }
            explorerSettings["ColumnsToShow"] = cols;
            explorerSettings["MaxElementsPerPage"] = MaxElementsPerPage;
            explorerSettings["SearchBarPadding"] = SearchBarPadding;
            explorerSettings["EnableSearchBar"] = EnableSearchBar;
            explorerSettings["SortingCriteria"] = explorer.utils.SortingCriteriaToString(SortingCriteria);
            explorerSettings["SortingAscending"] = SortingAscending;
            explorerSettings["SortFilesBeforeFolders"] = SortFilesBeforeFolders;

            explorerSettings["ValidFileColor"] = Vec4ToString(ValidFileColor);
            explorerSettings["InvalidFileColor"] = Vec4ToString(InvalidFileColor);
            explorerSettings["ValidFolderColor"] = Vec4ToString(ValidFolderColor);
            explorerSettings["InvalidFolderColor"] = Vec4ToString(InvalidFolderColor);

            return explorerSettings;
        }


        void ToggleColumnVisibility(const string &in columnName) {
            if (ColumnsToShow.Exists(columnName)) {
                bool isVisible;
                ColumnsToShow.Get(columnName, isVisible);
                ColumnsToShow.Set(columnName, !isVisible);
            }
        }

        bool IsColumnVisible(const string &in columnName) const {
            if (ColumnsToShow.Exists(columnName)) {
                bool isVisible;
                ColumnsToShow.Get(columnName, isVisible);
                return isVisible;
            }
            return false;
        }

        bool IsFilterActive(const string &in filter) const {
            bool isActive = true;
            if (ActiveFilters.Exists(filter)) {
                ActiveFilters.Get(filter, isActive);
            }
            return isActive;
        }

        void ToggleFilterActive(const string &in filter) {
            bool isActive = IsFilterActive(filter);
            ActiveFilters.Set(filter, !isActive);
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
        NameIgnoreFileFolder,
        Name,
        Size,
        LastModified,
        CreatedDate
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
            explorer.utils.TruncateSelectedPathsIfNeeded();
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
        int64 SizeBytes;
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

        ElementInfo(
                const string &in _name, 
                const string &in _path, 
                const string &in _size, 
                int64 _sizeBytes, 
                const string &in _type, 
                int64 _lastModifiedDate, 
                int64 _creationDate, 
                bool _isFolder, 
                Icon _icon, bool _isSelected) {
            this.Name = _name;
            this.Path = _path;
            this.Size = _size;
            this.SizeBytes = _sizeBytes;
            this.Type = _type;
            this.LastModifiedDate = _lastModifiedDate;
            this.CreationDate = _creationDate;
            this.IsFolder = _isFolder;
            this.Icon = _icon;
            this.IsSelected = _isSelected;
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
            log("Current path before moving up: " + path, LogLevel::Info, 410, "MoveUpOneDirectory");

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

            log("New path after moving up: " + path, LogLevel::Info, 429, "MoveUpOneDirectory");

            explorer.tab[0].LoadDirectory(path);
        }

        void MoveIntoSelectedDirectory() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            // ElementInfo@ selectedElement = explorer.ui.GetSelectedElement();

            if (selectedElement !is null && selectedElement.IsFolder) {
                if (!selectedElement.Path.StartsWith(explorer.tab[0].Navigation.GetPath())) {
                    log("Folder is not in the current folder, cannot move into it.", LogLevel::Warn, 440, "MoveIntoSelectedDirectory");
                } else {
                    UpdateHistory(selectedElement.Path);
                    explorer.tab[0].LoadDirectory(selectedElement.Path);
                }
            } else {
                log("No folder selected or selected element is not a folder.", LogLevel::Warn, 446, "MoveIntoSelectedDirectory");
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
            
            LoadDirectory(Config.Path);
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
            bool recursive = tab.Config.RecursiveSearch;
            log((recursive ? "Recursive " : "") + "Indexing started for path: " + startPath, LogLevel::Info, 542, "IndexFilesCoroutine");

            // Incase I change my mind and want to add recursive search back in at a later date... (it's not fully working, so it's commented out for now, but I'm probably not gonna do anything with it... way too slow)
            // array<string> elements = recursive ? PerformRecursiveIndexing(tab, startPath) : tab.explorer.GetFiles(startPath, false);
            array<string> elements = tab.explorer.GetFiles(startPath, false);

            if (elements.Length == 0) {
                log("No files found in directory: " + startPath, LogLevel::Info, 549, "IndexFilesCoroutine");
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

            log((recursive ? "Recursive " : "") + "Indexing completed. Number of elements: " + tab.Elements.Length, LogLevel::Info, 582, "IndexFilesCoroutine");

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
        //             if (explorer.utils.IsDirectory(elements[i])) {
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
            if (explorer.Config.RecursiveSearch) {
                ApplyRecursiveSearch();
            } else {
                ApplyNonRecursiveSearch();
            }

            ApplyFilters();
            if (explorer.Config.EnablePagination) {
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
            bool anyActiveFilters = false;
            for (uint i = 0; i < Config.Filters.Length; i++) {
                if (Config.IsFilterActive(Config.Filters[i])) {
                    anyActiveFilters = true;
                    break;
                }
            }

            for (uint i = 0; i < Elements.Length; i++) {
                ElementInfo@ element = Elements[i];
                element.shouldShow = true;

                if (anyActiveFilters && !element.IsFolder) {
                    bool found = false;
                    for (uint j = 0; j < Config.Filters.Length; j++) {
                        string filter = Config.Filters[j];
                        if (Config.IsFilterActive(filter)) {
                            if (element.Type.ToLower() == filter.ToLower()) {
                                found = true;
                                break;
                            } else if (filter.ToLower() == "replay" && element.Path.ToLower().Contains(".replay.gbx")) {
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

        void UpdatePagination() {
            uint totalElements = Elements.Length;
            TotalPages = uint(Math::Ceil(float(totalElements) / Config.MaxElementsPerPage));
            if (CurrentPage >= TotalPages) {
                CurrentPage = Math::Max(TotalPages - 1, 0);
            }
        }

        void SortElements() {
            for (uint i = 0; i < Elements.Length - 1; i++) {
                for (uint j = i + 1; j < Elements.Length; j++) {
                    bool swap = false;
                    if (Config.SortFilesBeforeFolders) {
                        swap = Elements[i].IsFolder && !Elements[j].IsFolder;
                    } else {
                        swap = !Elements[i].IsFolder && Elements[j].IsFolder;
                    }
                        
                    if (Config.SortingCriteria == SortingCriteria::NameIgnoreFileFolder) {
                        swap = Config.SortingAscending ? Elements[i].Name > Elements[j].Name : Elements[i].Name < Elements[j].Name;
                    } else if (Config.SortingCriteria == SortingCriteria::Name) {
                        if (Elements[i].IsFolder && Elements[j].IsFolder) {
                            swap = Config.SortingAscending ? Elements[i].Name > Elements[j].Name : Elements[i].Name < Elements[j].Name;
                        } else if (!Elements[i].IsFolder && !Elements[j].IsFolder) {
                            swap = Config.SortingAscending ? Elements[i].Name > Elements[j].Name : Elements[i].Name < Elements[j].Name;
                        } else {
                            swap = Elements[i].IsFolder;
                        }
                    } else if (Config.SortingCriteria == SortingCriteria::Size) {
                        swap = Config.SortingAscending ? Elements[i].SizeBytes > Elements[j].SizeBytes : Elements[i].SizeBytes < Elements[j].SizeBytes;
                    } else if (Config.SortingCriteria == SortingCriteria::LastModified) {
                        swap = Config.SortingAscending ? Elements[i].LastModifiedDate > Elements[j].LastModifiedDate : Elements[i].LastModifiedDate < Elements[j].LastModifiedDate;
                    } else if (Config.SortingCriteria == SortingCriteria::CreatedDate) {
                        swap = Config.SortingAscending ? Elements[i].CreationDate > Elements[j].CreationDate : Elements[i].CreationDate < Elements[j].CreationDate;
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

        void RefreshCurrentDirectory() {
            string currentPath = explorer.tab[0].Navigation.GetPath();
            log("Refreshing directory: " + currentPath, LogLevel::Info, 767, "RefreshCurrentDirectory");
            explorer.tab[0].LoadDirectory(currentPath);
        }

        void OpenSelectedFolderInNativeFileExplorer() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            if (selectedElement !is null && selectedElement.IsFolder) {
                log("Opening folder: " + selectedElement.Path, LogLevel::Info, 774, "OpenSelectedFolderInNativeFileExplorer");
                OpenExplorerPath(selectedElement.Path);
            } else {
                log("No folder selected or selected element is not a folder.", LogLevel::Error, 777, "OpenSelectedFolderInNativeFileExplorer");
            }
        }

        void OpenCurrentFolderInNativeFileExplorer() {
            string currentPath = explorer.tab[0].Navigation.GetPath();
            log("Opening folder: " + currentPath, LogLevel::Info, 783, "OpenCurrentFolderInNativeFileExplorer");
            OpenExplorerPath(currentPath);
        }

        bool IsElementSelected() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            return selectedElement !is null;
        }

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

        void DisabledButton(const string &in text, const vec2 &in size = vec2 ( )) {
            UI::BeginDisabled();
            UI::Button(text, size);
            UI::EndDisabled();
        }

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

        bool RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
        void DeleteSelectedElement() {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            if (selectedElement !is null) {
                if (selectedElement.IsFolder) {
                    array<string> folderContents = IO::IndexFolder(selectedElement.Path, false);
                    if (folderContents.Length > 0) {
                        explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = true;
                    } else {
                        log("Deleting empty folder: " + selectedElement.Path, LogLevel::Info, 860, "DeleteSelectedElement");
                        IO::DeleteFolder(selectedElement.Path);
                        explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    }
                } else {
                    log("Deleting file: " + selectedElement.Path, LogLevel::Info, 865, "DeleteSelectedElement");
                    IO::Delete(selectedElement.Path);
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
            }
        }

        bool RENDER_RENAME_POPUP_FLAG;
        void RenameSelectedElement(const string &in newName) {
            ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();
            if (selectedElement is null) return;

            string currentPath = selectedElement.Path;
            string newPath;

            string sanitizedNewName = Path::SanitizeFileName(newName);

            if (selectedElement.IsFolder) {
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
                if (explorer.Config.PinnedElements.Find(selectedElement.Path) == -1) {
                    log("Pinning element: " + selectedElement.Path, LogLevel::Info, 904, "PinSelectedElement");
                    explorer.Config.PinnedElements.InsertLast(selectedElement.Path);
                    explorer.Config.SaveSettings();
                }
            }
        }

        void TruncateSelectedPathsIfNeeded() {
            uint maxAllowed = uint(explorer.Config.MinMaxReturnAmount.y);
            if (explorer.Config.MinMaxReturnAmount.y != -1 && explorer.Config.SelectedPaths.Length > maxAllowed) {
                explorer.Config.SelectedPaths.Resize(maxAllowed);
            }
        }

        string SortingCriteriaToString(SortingCriteria criteria) {
            switch (criteria) {
                case SortingCriteria::NameIgnoreFileFolder: return "NameIgnoreFileFolder";
                case SortingCriteria::Name: return "Name";
                case SortingCriteria::Size: return "Size";
                case SortingCriteria::LastModified: return "Date Modified";
                case SortingCriteria::CreatedDate: return "Date Created";
            }
            return "Unknown";
        }

        SortingCriteria StringToSortingCriteria(const string &in str) {
            if (str == "NameIgnoreFileFolder") return SortingCriteria::NameIgnoreFileFolder;
            if (str == "Name") return SortingCriteria::Name;
            if (str == "Size") return SortingCriteria::Size;
            if (str == "Date Modified") return SortingCriteria::LastModified;
            if (str == "Date Created") return SortingCriteria::CreatedDate;
            return SortingCriteria::Name;
        }
    }

    class FileExplorer {
        array<FileTab@> tab;
        Config@ Config;
        array<string> PinnedElements;
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
            explorer.Config.LoadSettings();
            explorer.exports.selectionComplete = false;
            showInterface = true;
        }

        void Close() {
            Config.SaveSettings();
            showInterface = false;
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
            bool isFolder = explorer.utils.IsDirectory(path);
            string name = isFolder ? explorer.utils.GetDirectoryName(path) : Path::GetFileName(path);
            string type = isFolder ? "folder" : Path::GetExtension(path).SubStr(1);
            string size = isFolder ? "-" : ConvertFileSizeToString(IO::FileSize(path));
            int64 sizeBytes = IO::FileSize(path);
            int64 lastModified = IO::FileModifiedTime(path);
            int64 creationDate = IO::FileCreatedTime(path);
            Icon icon = GetElementIcon(isFolder, type);
            ElementInfo@ elementInfo = ElementInfo(name, path, size, sizeBytes, type, lastModified, creationDate, isFolder, icon, false);

            if (type.ToLower() == "gbx") {
                startnew(CoroutineFuncUserdata(ReadGbxMetadataCoroutine), elementInfo);
            }

            return elementInfo;
        }

        void ReadGbxMetadataCoroutine(ref@ r) {
            ElementInfo@ elementInfo = cast<ElementInfo@>(r);
            if (elementInfo is null) return;

            string path = elementInfo.Path;
            dictionary gbxMetadata = ReadGbxHeader(path);
            elementInfo.SetGbxMetadata(gbxMetadata);
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

    enum ContextType {
        MainArea,
        SelectedElements,
        PinnedElements
    }

    class UserInterface {
        FileExplorer@ explorer;

        UserInterface(FileExplorer@ fe) {
            @explorer = fe;
        }

        void Render_FileExplorer() {
            if (!showInterface) return;

            Render_Rows();
            Render_Columns();

            Render_Misc();
        }

        void Render_Misc() {
            Render_RenamePopup();
            Render_DeleteConfirmationPopup();

            switch (currentContextType) {
                case ContextType::MainArea:
                    Render_Context_MainArea();
                    break;
                case ContextType::SelectedElements:
                    Render_Context_SelectedElements();
                    break;
                case ContextType::PinnedElements:
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

            if (UI::Button("File Explorer", vec2(90, 0))) {}
            
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

            if (explorer.Config.EnablePagination) {
                if (UI::Button(text, buttonSize)) {}
            } else {
                if (UI::Button("##", buttonSize)) {}
            }
            
            UI::PopStyleColor(3);

            UI::SameLine();

            if (UI::Button(Icons::WindowMinimize)) {
                explorer.utils.MinimizeWindow();
            }
            UI::SameLine();
            if (UI::Button(Icons::WindowMaximize)) {
                explorer.utils.MaximizeWindow();
            }
            UI::SameLine();
            if (UI::Button(Icons::WindowClose)) {
                explorer.Close();
            }
            UI::SameLine();
            if (UI::Button(Icons::WindowRestore)) {
                explorer.utils.BaseWindow();
            }

            UI::Separator();
        }

        void Render_NavigationBar() {
            float buttonWidth = 30.0;
            float totalWidth = UI::GetContentRegionAvail().x;
            float pathWidth = (totalWidth * 0.8f - buttonWidth * 3);
    
            if (explorer.Config.EnableSearchBar) {
                pathWidth += explorer.Config.SearchBarPadding;
            }

            float searchWidth = totalWidth - pathWidth - buttonWidth * 3;

            // Navigation Buttons
            if (explorer.tab[0].Navigation.HistoryIndex > 0) {
                if (UI::Button(Icons::ArrowLeft, vec2(buttonWidth, 0))) {
                    explorer.tab[0].Navigation.NavigateBack();
                }
            } else {
                explorer.utils.DisabledButton(Icons::ArrowLeft, vec2(buttonWidth, 0));
            }
            UI::SameLine();
            if (explorer.tab[0].Navigation.HistoryIndex < int(explorer.tab[0].Navigation.History.Length) - 1) {
                if (UI::Button(Icons::ArrowRight, vec2(buttonWidth, 0))) {
                    explorer.tab[0].Navigation.NavigateForward();
                }
            } else {
                explorer.utils.DisabledButton(Icons::ArrowRight, vec2(buttonWidth, 0));
            }
            UI::SameLine();
            if (explorer.tab[0].Navigation.CanMoveUpDirectory()) {
                if (UI::Button(Icons::ArrowUp, vec2(buttonWidth, 0))) {
                    explorer.tab[0].Navigation.MoveUpOneDirectory();
                }
            } else {
                explorer.utils.DisabledButton(Icons::ArrowUp, vec2(buttonWidth, 0));
            }
            UI::SameLine();
            
            if (
                explorer.tab[0].GetSelectedElement() !is null
            &&  explorer.tab[0].GetSelectedElement().IsFolder
            &&  explorer.tab[0].GetSelectedElement().IsSelected
            ) {
                if (UI::Button(Icons::ArrowDown)) { explorer.tab[0].Navigation.MoveIntoSelectedDirectory(); }
            } else {
                explorer.utils.DisabledButton(Icons::ArrowDown);
            }

            UI::SameLine();

            UI::PushItemWidth(pathWidth);
            string newPath = UI::InputText("##PathInput", explorer.tab[0].Navigation.GetPath());
            if (UI::IsKeyPressed(UI::Key::Enter)) {
                explorer.tab[0].LoadDirectory(newPath);
            }
            UI::PopItemWidth();

            if (explorer.Config.EnableSearchBar) {
                UI::SameLine();
                UI::PushItemWidth(searchWidth - 110);

                UI::Text(Icons::Search + "");
                UI::SameLine();
                string newSearchQuery = UI::InputText("##SearchInput", explorer.Config.SearchQuery);
                if (UI::IsKeyPressed(UI::Key::Enter) && newSearchQuery != explorer.Config.SearchQuery) {
                    explorer.Config.SearchQuery = newSearchQuery;
                    explorer.tab[0].ApplyFiltersAndSearch();
                }

                UI::PopItemWidth();
            }

            UI::Separator();
        }

        string newFilter = "";
        void Render_ActionBar() {
            if (!explorer.Config.EnablePagination) {
                explorer.utils.DisabledButton(Icons::ChevronLeft);
                UI::SameLine();
                explorer.utils.DisabledButton(Icons::ChevronRight);
                UI::SameLine();
            } else {
                if (explorer.tab[0].CurrentPage > 0) {
                    if (UI::Button(Icons::ChevronLeft)) {
                        explorer.tab[0].CurrentPage--;
                    }
                } else {
                    explorer.utils.DisabledButton(Icons::ChevronLeft);
                }
                UI::SameLine();

                if (explorer.tab[0].CurrentPage < explorer.tab[0].TotalPages - 1) {
                    if (UI::Button(Icons::ChevronRight)) {
                        explorer.tab[0].CurrentPage++;
                    }
                } else {
                    explorer.utils.DisabledButton(Icons::ChevronRight);
                }
                UI::SameLine();
            }

            if (UI::Button(Icons::Refresh)) { explorer.utils.RefreshCurrentDirectory(); }
            UI::SameLine();
            if (UI::Button(Icons::FolderOpen)) { explorer.utils.OpenCurrentFolderInNativeFileExplorer(); }
            UI::SameLine();
            if (!explorer.utils.IsElementSelected()) {
                explorer.utils.DisabledButton(Icons::Trash); 
                UI::SameLine();
                explorer.utils.DisabledButton(Icons::Pencil);
                UI::SameLine();
                explorer.utils.DisabledButton(Icons::ThumbTack);
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

                UI::PushStyleColor(UI::Col::Button, vec4(0, 0, 0, 0));
                UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0, 0, 0, 0));
                UI::PushStyleColor(UI::Col::ButtonActive, vec4(0, 0, 0, 0));

                if (UI::Button("Add filter", vec2(70, 0))) {}
                
                UI::PopStyleColor(3);

                UI::SameLine();
                newFilter = UI::InputText("##", newFilter);
                UI::SameLine();
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
                    bool isActive = explorer.Config.IsFilterActive(filter);

                    if (UI::BeginMenu(filter + (isActive ? "\\$888 (Active)" : "\\$888 (Inactive)"))) {
                        if (UI::MenuItem(isActive ? "Deactivate Filter" : "Activate Filter")) {
                            explorer.Config.ToggleFilterActive(filter);
                            explorer.tab[0].ApplyFiltersAndSearch();
                        }
                        
                        if (UI::MenuItem("Remove Filter")) {
                            explorer.Config.Filters.RemoveAt(i);
                            explorer.Config.ActiveFilters.Delete(filter);
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
                string orderButtonLabel = explorer.Config.SortingAscending ? Icons::ArrowUp : Icons::ArrowDown;
                if (UI::MenuItem(orderButtonLabel + " Order", "", explorer.Config.SortingAscending)) {
                    explorer.Config.SortingAscending = !explorer.Config.SortingAscending;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Sort Files Before Folders", "", explorer.Config.SortFilesBeforeFolders)) {
                    explorer.Config.SortFilesBeforeFolders = !explorer.Config.SortFilesBeforeFolders;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                UI::Separator();

                if (UI::MenuItem("Name", "", explorer.Config.SortingCriteria == SortingCriteria::Name)) {
                    explorer.Config.SortingCriteria = SortingCriteria::Name;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Name (Ignore File/Folder)", "", explorer.Config.SortingCriteria == SortingCriteria::NameIgnoreFileFolder)) {
                    explorer.Config.SortingCriteria = SortingCriteria::NameIgnoreFileFolder;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Size", "", explorer.Config.SortingCriteria == SortingCriteria::Size)) {
                    explorer.Config.SortingCriteria = SortingCriteria::Size;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Date Modified", "", explorer.Config.SortingCriteria == SortingCriteria::LastModified)) {
                    explorer.Config.SortingCriteria = SortingCriteria::LastModified;
                    explorer.tab[0].SortElements();
                    explorer.Config.SaveSettings();
                }
                if (UI::MenuItem("Date Created", "", explorer.Config.SortingCriteria == SortingCriteria::CreatedDate)) {
                    explorer.Config.SortingCriteria = SortingCriteria::CreatedDate;
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
                if (UI::MenuItem("Hide Files", "", explorer.Config.HideFiles)) {
                    explorer.Config.HideFiles = !explorer.Config.HideFiles;
                    explorer.tab[0].ApplyVisibilitySettings();
                    explorer.utils.RefreshCurrentDirectory();
                }
                if (UI::MenuItem("Hide Folders", "", explorer.Config.HideFolders)) {
                    explorer.Config.HideFolders = !explorer.Config.HideFolders;
                    explorer.tab[0].ApplyVisibilitySettings();
                    explorer.utils.RefreshCurrentDirectory();
                }

                if (UI::BeginMenu("Pagination")) {
                    if (UI::MenuItem("Enable Pagination", "", explorer.Config.EnablePagination)) {
                        explorer.Config.EnablePagination = !explorer.Config.EnablePagination;
                        explorer.utils.RefreshCurrentDirectory();
                    }

                    if (explorer.Config.EnablePagination) {
                        explorer.Config.MaxElementsPerPage = UI::SliderInt("Max Elements Per Page", explorer.Config.MaxElementsPerPage, 1, 100);
                    }

                    UI::EndMenu();
                }

                if (UI::BeginMenu("Search Bar")) {
                    if (UI::MenuItem("Enable Search Bar", "", explorer.Config.EnableSearchBar)) {
                        explorer.Config.EnableSearchBar = !explorer.Config.EnableSearchBar;
                        explorer.utils.RefreshCurrentDirectory();
                    }

                    if (explorer.Config.EnableSearchBar) {
                        explorer.Config.SearchBarPadding = UI::SliderInt("Search Bar Padding", explorer.Config.SearchBarPadding, -200, 100);
                    }

                    // if (UI::MenuItem("Enable Recursive Search" + "\\$0f0 " + "Warning \\$g Extremely laggy, use with causion", "", explorer.Config.RecursiveSearch)) {
                    //     explorer.Config.RecursiveSearch = !explorer.Config.RecursiveSearch;
                    //     explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    // }

                    UI::EndMenu();
                }

                if (UI::MenuItem("Use Extra Warning When Deleting", "", explorer.Config.UseExtraWarningWhenDeleting)) {
                    explorer.Config.UseExtraWarningWhenDeleting = !explorer.Config.UseExtraWarningWhenDeleting;
                }
                
                UI::Separator();

                if (UI::BeginMenu("Visible Columns")) {
                    array<string> orderedColumns = { "ico", "name", "type", "size", "lastModified", "createdDate" };
                    for (uint i = 0; i < orderedColumns.Length; i++) {
                        string col = orderedColumns[i];
                        bool isVisible = explorer.Config.IsColumnVisible(col);
                        if (UI::MenuItem(col, "", isVisible, true)) {
                            explorer.Config.ToggleColumnVisibility(col);
                            explorer.utils.RefreshCurrentDirectory();
                        }
                    }
                    UI::EndMenu();
                }

                if (UI::BeginMenu("File Name Display Options")) {
                    if (UI::MenuItem("Default File Name", "", explorer.Config.FileNameDisplayOption == 0)) {
                        explorer.Config.FileNameDisplayOption = 0;
                        explorer.utils.RefreshCurrentDirectory();
                    }
                    if (UI::MenuItem("No Formatting", "", explorer.Config.FileNameDisplayOption == 1)) {
                        explorer.Config.FileNameDisplayOption = 1;
                        explorer.utils.RefreshCurrentDirectory();
                    }
                    if (UI::MenuItem("ManiaPlanet Formatting", "", explorer.Config.FileNameDisplayOption == 2)) {
                        explorer.Config.FileNameDisplayOption = 2;
                        explorer.utils.RefreshCurrentDirectory();
                    }
                    UI::EndMenu();
                }

                UI::Separator();

                if (UI::BeginMenu("Valid/Invalid File Colors")) {
                    if (UI::MenuItem("Valid File Color", "", false, true)) {
                        explorer.Config.ValidFileColor = UI::InputColor4("Valid File Color", explorer.Config.ValidFileColor);
                    }
                    if (UI::MenuItem("Invalid File Color", "", false, true)) {
                        explorer.Config.InvalidFileColor = UI::InputColor4("Invalid File Color", explorer.Config.InvalidFileColor);
                    }
                    if (UI::MenuItem("Valid Folder Color", "", false, true)) {
                        explorer.Config.ValidFolderColor = UI::InputColor4("Valid Folder Color", explorer.Config.ValidFolderColor);
                    }
                    if (UI::MenuItem("Invalid Folder Color", "", false, true)) {
                        explorer.Config.InvalidFolderColor = UI::InputColor4("Invalid Folder Color", explorer.Config.InvalidFolderColor);
                    }
                }
                UI::End();


                explorer.Config.SaveSettings();

                UI::EndPopup();
            }

            UI::Separator();
        }

        string newFileName = "";
        void Render_RenamePopup() {
            if (explorer.utils.RENDER_RENAME_POPUP_FLAG) {
                UI::OpenPopup("RenamePopup");
                explorer.utils.RENDER_RENAME_POPUP_FLAG = false;
            }

            if (UI::BeginPopupModal("RenamePopup", UI::WindowFlags::AlwaysAutoResize)) {
                UI::Text("Enter new name:");
                newFileName = UI::InputText("##RenameInput", newFileName);
                if (UI::Button("Rename")) {
                    explorer.utils.RenameSelectedElement(newFileName);
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
            if (explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG && explorer.Config.UseExtraWarningWhenDeleting) {
                UI::OpenPopup("DeleteConfirmationPopup");
            } else if (explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG && !explorer.Config.UseExtraWarningWhenDeleting) {
                ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();

                if (selectedElement !is null && selectedElement.IsFolder) {
                    log("Deleting folder with contents: " + selectedElement.Path, LogLevel::Info, 1463, "Render_DeleteConfirmationPopup");
                    IO::DeleteFolder(selectedElement.Path, true);
                    explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
                    explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                }
            }

            if (UI::BeginPopupModal("DeleteConfirmationPopup", explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG, UI::WindowFlags::AlwaysAutoResize)) {
                ElementInfo@ selectedElement = explorer.tab[0].GetSelectedElement();

                UI::Text("Are you sure you want to delete this folder and all its contents?");
                UI::Separator();
                if (UI::Button("Yes, delete all")) {
                    if (selectedElement !is null && selectedElement.IsFolder) {
                        log("Deleting folder with contents: " + selectedElement.Path, LogLevel::Info, 1477, "Render_DeleteConfirmationPopup");
                        IO::DeleteFolder(selectedElement.Path, true);
                        explorer.utils.RENDER_DELETE_CONFIRMATION_POPUP_FLAG = false;
                        explorer.tab[0].LoadDirectory(explorer.tab[0].Navigation.GetPath());
                    } else {
                        log("No selected element or element is not a folder.", LogLevel::Error, 1482, "Render_DeleteConfirmationPopup");
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
                bool validReturnAmount = explorer.Config.SelectedPaths.Length >= uint(explorer.Config.MinMaxReturnAmount.x) &&
                                        (explorer.Config.SelectedPaths.Length <= uint(explorer.Config.MinMaxReturnAmount.y) || explorer.Config.MinMaxReturnAmount.y == -1);

                if (validReturnAmount) {
                    array<string> validSelections;
                    for (uint i = 0; i < explorer.Config.SelectedPaths.Length; i++) {
                        ElementInfo@ element = explorer.GetElementInfo(explorer.Config.SelectedPaths[i]);

                        // Validate file type
                        bool validType = true;
                        if (!element.IsFolder && explorer.Config.FileTypeMustBe.Length > 0) {
                            validType = false;
                            for (uint j = 0; j < explorer.Config.FileTypeMustBe.Length; j++) {
                                if (element.Type.ToLower() == explorer.Config.FileTypeMustBe[j].ToLower()) {
                                    validType = true;
                                    break;
                                }
                            }
                        }

                        // Validate CanOnlyReturn
                        if ((explorer.Config.CanOnlyReturn.Find("file") >= 0 && !element.IsFolder) ||
                            (explorer.Config.CanOnlyReturn.Find("files") >= 0 && !element.IsFolder) ||
                            (explorer.Config.CanOnlyReturn.Find("dir") >= 0 && element.IsFolder) ||
                            (explorer.Config.CanOnlyReturn.Find("directories") >= 0 && element.IsFolder) ||
                            (explorer.Config.CanOnlyReturn.Find("directory") >= 0 && element.IsFolder) ||
                            explorer.Config.CanOnlyReturn.IsEmpty()) {
                            if (validType) validSelections.InsertLast(element.Path);
                        }
                    }

                    if (validSelections.Length > 0) {
                        if (UI::Button("Return Selected Paths")) {
                            explorer.exports.SetSelectionComplete(validSelections);
                            explorer.Close();
                        }
                    } else {
                        explorer.utils.DisabledButton("Return Selected Paths");
                    }
                } else {
                    explorer.utils.DisabledButton("Return Selected Paths");
                }
                UI::SameLine();
                UI::Text("Selected element amount: " + explorer.Config.SelectedPaths.Length);
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
            if (explorer.Config.PinnedElements.Length == 0) {
                // UI::Text("No pinned elements.");
            } else {
                for (uint i = 0; i < explorer.Config.PinnedElements.Length; i++) {
                    string path = explorer.Config.PinnedElements[i];
                    ElementInfo@ element = explorer.GetElementInfo(path);

                    if (element !is null) {
                        SelectableWithClickCheck(element, ContextType::PinnedElements);
                    } else {
                        explorer.Config.PinnedElements.RemoveAt(i);
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
                        if (explorer.Config.SelectedPaths.Find(element.Path) == -1) {
                            explorer.Config.SelectedPaths.InsertLast(element.Path);
                            explorer.utils.TruncateSelectedPathsIfNeeded();
                        }
                    }

                    if (UI::MenuItem("Remove from Pinned Elements")) {
                        int index = explorer.Config.PinnedElements.Find(element.Path);
                        if (index != -1) {
                            explorer.Config.PinnedElements.RemoveAt(index);
                            explorer.Config.SaveSettings();
                        }
                    }

                    if (UI::MenuItem("Rename Pinned Element")) {
                        explorer.utils.RENDER_RENAME_POPUP_FLAG = true;
                    }
                } else {
                    int pinnedPath = explorer.Config.PinnedElements.Find(element.Path);
                    explorer.Config.PinnedElements.RemoveAt(pinnedPath);
                }
                UI::EndPopup();
            }
        }

        void Render_SelectedElements() {
            for (uint i = 0; i < explorer.Config.SelectedPaths.Length; i++) {
                string path = explorer.Config.SelectedPaths[i];
                ElementInfo@ element = explorer.GetElementInfo(path);

                SelectableWithClickCheck(element, ContextType::SelectedElements);
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
                        int index = explorer.Config.SelectedPaths.Find(element.Path);
                        if (index != -1) {
                            explorer.Config.SelectedPaths.RemoveAt(index);
                        }
                    }

                    if (UI::MenuItem("Pin Element")) {
                        explorer.utils.PinSelectedElement();
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

                    uint startIndex = explorer.Config.EnablePagination ? explorer.tab[0].CurrentPage * explorer.Config.MaxElementsPerPage : 0;
                    uint endIndex = explorer.Config.EnablePagination ? Math::Min(startIndex + explorer.Config.MaxElementsPerPage, explorer.tab[0].Elements.Length) : explorer.tab[0].Elements.Length;

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
                                    UI::Text(explorer.GetElementIconString(element.Icon, element.IsSelected));
                                } else if (col == "name") {
                                    SelectableWithClickCheck(element, ContextType::MainArea);
                                } else if (col == "type") {
                                    UI::Text(element.Type);
                                } else if (col == "size") {
                                    UI::Text(element.IsFolder ? "-" : element.Size);
                                } else if (col == "lastModified") {
                                    UI::Text(Time::FormatString("%Y-%m-%d %H:%M:%S", element.LastModifiedDate));
                                } else if (col == "createdDate") {
                                    UI::Text(Time::FormatString("%Y-%m-%d %H:%M:%S", element.CreationDate));
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
                    bool canAddMore = explorer.Config.SelectedPaths.Length < uint(explorer.Config.MinMaxReturnAmount.y) || explorer.Config.MinMaxReturnAmount.y == -1;

                    if (canAddMore) {
                        if (UI::MenuItem("Add to Selected Elements", "", false)) {
                            if (explorer.Config.SelectedPaths.Find(element.Path) == -1) {
                                explorer.Config.SelectedPaths.InsertLast(element.Path);
                                explorer.utils.TruncateSelectedPathsIfNeeded();
                            }
                        }
                    } else {
                        UI::MenuItem("Add to Selected Elements", "", false, false);
                    }

                    if (canAddMore) {
                        if (UI::MenuItem("Quick return")) {
                            explorer.exports.SetSelectionComplete( { element.Path } );
                            explorer.exports.selectionComplete = true;
                            explorer.Close();
                        }
                    } else {
                        UI::MenuItem("Quick return", "", false, false);
                    }

                    if (UI::MenuItem("Rename Element")) {
                        explorer.utils.RENDER_RENAME_POPUP_FLAG = true;
                    }

                    if (UI::MenuItem("Pin Element")) {
                        explorer.utils.PinSelectedElement();
                    }

                    if (UI::MenuItem("Delete Element")) {
                        explorer.utils.DeleteSelectedElement();
                    }
                }
                UI::EndPopup();
            }
        }

        void SelectableWithClickCheck(ElementInfo@ element, ContextType contextType) {
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

            bool isValid = true;
            if (!element.IsFolder) {
                isValid = explorer.Config.FileTypeMustBe.Find(element.Type.ToLower()) >= 0;
            }
            if (element.IsFolder) {
                isValid = explorer.Config.CanOnlyReturn.Find("dir") >= 0 || explorer.Config.CanOnlyReturn.Find("directory") >= 0;
            }

            vec4 textColor = element.IsFolder
                ? (isValid ? explorer.Config.ValidFolderColor : explorer.Config.InvalidFolderColor)
                : (isValid ? explorer.Config.ValidFileColor : explorer.Config.InvalidFileColor);
            
            UI::PushStyleColor(UI::Col::Text, textColor);
            UI::Selectable(displayName, element.IsSelected);
            UI::PopStyleColor();

            if (UI::IsItemHovered() && UI::IsMouseClicked(UI::MouseButton::Left) && (UI::IsKeyDown(UI::Key::LeftCtrl) || UI::IsKeyDown(UI::Key::RightCtrl))) {
                HandleElementSelection(element, EnterType::ControlClick, contextType);
            } else if (UI::IsItemHovered() && UI::IsMouseClicked(UI::MouseButton::Right)) {
                HandleElementSelection(element, EnterType::RightClick, contextType);
            } else if (UI::IsItemHovered() && UI::IsMouseClicked(UI::MouseButton::Left)) {
                HandleElementSelection(element, EnterType::LeftClick, contextType);
            }
        }

        void HandleElementSelection(ElementInfo@ element, EnterType enterType, ContextType contextType) {
            // Enforce selection restrictions
            bool canAddMore = explorer.Config.SelectedPaths.Length < uint(explorer.Config.MinMaxReturnAmount.y) || explorer.Config.MinMaxReturnAmount.y == -1;
            // Enforce folder/file only restrictions
            if (explorer.Config.CanOnlyReturn.Find("file") && !element.IsFolder) return;
            if (explorer.Config.CanOnlyReturn.Find("files") && !element.IsFolder) return;
            if (explorer.Config.CanOnlyReturn.Find("dir") && element.IsFolder) return;
            if (explorer.Config.CanOnlyReturn.Find("directories") && element.IsFolder) return;
            if (explorer.Config.CanOnlyReturn.Find("directory") && element.IsFolder) return;
            // Enforce file type filtering (if applicable)
            if (!element.IsFolder && explorer.Config.FileTypeMustBe.Length > 0) {
                bool validType = false;
                for (uint i = 0; i < explorer.Config.FileTypeMustBe.Length; i++) {
                    if (element.Type.ToLower() == explorer.Config.FileTypeMustBe[i].ToLower()) {
                        validType = true;
                        break;
                    }
                }
                if (!validType) return;
            }

            // Handle element click
            // Handle control-click (for multi-selection) or right-click (for context menu)
            uint64 currentTime = Time::Now;
            const uint64 doubleClickThreshold = 600; // 0.6 seconds

            if (enterType == EnterType::RightClick || enterType == EnterType::ControlClick) {
                openContextMenu = true;
                currentContextType = contextType;
                @explorer.CurrentSelectedElement = element;
            } 
            // Handle double-click
            else if (contextType == ContextType::PinnedElements || element.IsSelected) {
                if (currentTime - element.LastClickTime <= doubleClickThreshold) {
                    if (contextType == ContextType::PinnedElements) {
                        if (canAddMore && explorer.Config.SelectedPaths.Find(element.Path) == -1) {
                            explorer.Config.SelectedPaths.InsertLast(element.Path);
                            explorer.utils.TruncateSelectedPathsIfNeeded();
                        }
                        @explorer.CurrentSelectedElement = element;
                    } else if (element.IsFolder) {
                        explorer.tab[0].Navigation.MoveIntoSelectedDirectory();
                    } else if (canAddMore) {
                        if (explorer.Config.SelectedPaths.Find(element.Path) == -1) {
                            explorer.Config.SelectedPaths.InsertLast(element.Path);
                            explorer.utils.TruncateSelectedPathsIfNeeded();
                        }
                        @explorer.CurrentSelectedElement = element;
                    }
                } else {
                    element.LastClickTime = currentTime;
                }
            } 
            // Normal left-click to select an element
            else if (enterType == EnterType::LeftClick) {
                if (contextType != ContextType::PinnedElements) {
                    for (uint i = 0; i < explorer.tab[0].Elements.Length; i++) {
                        explorer.tab[0].Elements[i].IsSelected = false;
                    }
                }
                element.IsSelected = true;
                element.LastSelectedTime = currentTime;
                element.LastClickTime = currentTime;
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

                    if (gbxMetadata.IsEmpty()) {
                        UI::Text("No metadata found.");
                    }

                    if (true) UI::Text("Selected element " + selectedElement.Path);

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

    void RenderFileExplorer() {
        if (showInterface && explorer !is null) {
            // UserInterface ui(explorer);
            if (UI::Begin("File Explorer", showInterface, UI::WindowFlags::NoTitleBar)) {
                explorer.ui.Render_FileExplorer();
            }
            UI::End();
        }
    }

    // - Add cannot return specific file types
    // - Add can only return folders / files

    void fe_Start(
        bool _mustReturn = true,
        vec2 _minmaxReturnAmount = vec2(1, -1),
        string _path = "",
        string _searchQuery = "",
        string[] _filters = array<string>(),
        string[] _fileTypeMustBe = array<string>(),
        string _canOnlyReturn = ""
    ) {
        Config config;
        config.MustReturn = _mustReturn;
        config.MinMaxReturnAmount = _minmaxReturnAmount;
        config.Path = _path;
        config.SearchQuery = _searchQuery;
        config.Filters = _filters;
        config.FileTypeMustBe = _fileTypeMustBe;
        config.CanOnlyReturn = _canOnlyReturn;

        if (explorer is null) {
            @explorer = FileExplorer(config);
        } else {
            @explorer.Config = config;
        }
        
        explorer.Open(config);
    }

    void fe_ForceClose() {
        if (explorer !is null) {
            explorer.Close();
        } else {
            showInterface = false;
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
            log("Error: Timeout while reading GBX header for file: " + path, LogLevel::Error, 2015, "ReadGbxHeader");
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
            log("Error: Missing header node in GBX file: " + path, LogLevel::Error, 2048, "ReadGbxHeader");
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
        vec2(1, -1), // _minmaxReturnAmount
        IO::FromUserGameFolder("Replays/"), // path // Change to Maps/ when done with general gbx detection is done
        "", // searchQuery
        { "replay" }, // filters
        { "replay" }, // fileTypeMustBe
        { "files" } // canOnlyReturn
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