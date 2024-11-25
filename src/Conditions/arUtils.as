// Fun Utils I use from time to time

namespace _Text {
    int NthLastIndexOf(const string &in str, const string &in value, int n) {
        int index = -1;
        for (int i = str.Length - 1; i >= 0; --i) {
            if (str.SubStr(i, value.Length) == value) {
                if (n == 1) {
                    index = i;
                    break;
                }
                --n;
            }
        }
        return index;
    }
}

namespace _UI {
    void SimpleTooltip(const string &in msg) {
        if (UI::IsItemHovered()) {
            UI::SetNextWindowSize(400, 0, UI::Cond::Appearing);
            UI::BeginTooltip();
            UI::TextWrapped(msg);
            UI::EndTooltip();
        }
    }

    void DisabledButton(const string &in text, const vec2 &in size = vec2 ( )) {
        UI::BeginDisabled();
        UI::Button(text, size);
        UI::EndDisabled();
    }

    bool DisabledButton(bool disabled, const string &in text, const vec2 &in size = vec2 ( )) {
        if (disabled) {
            DisabledButton(text, size);
            return false;
        } else {
            return UI::Button(text, size);
        }
    }
}

namespace _IO {
    namespace Directory {
        bool IsDirectory(const string &in path) {
            if (path.EndsWith("/") || path.EndsWith("\\")) return true;
            return false;
        }
        
        string GetParentDirectoryName(const string &in path) {
            string trimmedPath = path;

            if (!IsDirectory(trimmedPath)) {
                return _IO::File::GetFilePathWithoutFileName(trimmedPath);
            }

            if (trimmedPath.EndsWith("/") || trimmedPath.EndsWith("\\")) {
                trimmedPath = trimmedPath.SubStr(0, trimmedPath.Length - 1);
            }
            
            int index = trimmedPath.LastIndexOf("/");
            int index2 = trimmedPath.LastIndexOf("\\");

            index = Math::Max(index, index2);

            if (index == -1) {
                return "";
            }

            return trimmedPath.SubStr(index + 1);
        }
    }

    namespace File {
        bool IsFile(const string &in path) {
            if (IO::FileExists(path)) return true;
            return false;
        }

        void WriteFile(string _path, const string &in content, bool verbose = false) {
            string path = _path;
            if (verbose) log("Writing to file: " + path, LogLevel::Info, 84, "WriteFile");

            if (path.EndsWith("/") || path.EndsWith("\\")) { log("Invalid file path: " + path, LogLevel::Error, 86, "WriteFile"); return; }

            IO::File file;
            file.Open(path, IO::FileMode::Write);
            file.Write(content);
            file.Close();
        }

        string GetFilePathWithoutFileName(const string &in path) {
            int index = path.LastIndexOf("/");
            int index2 = path.LastIndexOf("\\");

            index = Math::Max(index, index2);

            if (index == -1) {
                return "";
            }
        
            return path.SubStr(0, index);
        }

        void WriteJsonFile(const string &in path, const Json::Value &in value) {
            string content = Json::Write(value);
            WriteFile(path, content);
        }

        // Read from file
        string ReadFileToEnd(const string &in path, bool verbose = false) {
            if (verbose) log("Reading file: " + path, LogLevel::Info, 114, "ReadFileToEnd");
            if (!IO::FileExists(path)) { log("File does not exist: " + path, LogLevel::Error, 115, "ReadFileToEnd"); return ""; }

            IO::File file(path, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();
            return content;
        }
        
        string ReadSourceFileToEnd(const string &in path, bool verbose = false) {
            if (!IO::FileExists(path)) { log("File does not exist: " + path, LogLevel::Error, 124, "ReadSourceFileToEnd"); return ""; }

            IO::FileSource f(path);
            string content = f.ReadToEnd();
            return content;
        }

        // Move file
        void CopySourceFileToNonSource(const string &in originalPath, const string &in storagePath, bool verbose = false) {
            if (verbose) log("Moving the file content", LogLevel::Info, 133, "CopySourceFileToNonSource");
            
            string fileContents = ReadSourceFileToEnd(originalPath);
            WriteFile(storagePath, fileContents);

            if (verbose) log("Finished moving the file", LogLevel::Info, 138, "CopySourceFileToNonSource");

            // TODO: Must check how IO::Move works with source files
        }

        // Copy file
        void CopyFileTo(const string &in source, const string &in destination, bool verbose = false) {
            if (!IO::FileExists(source)) { if (verbose) log("Source file does not exist: " + source, LogLevel::Error, 145, "CopyFileTo"); return; }
            if (IO::FileExists(destination)) { if (verbose) log("Destination file already exists: " + destination, LogLevel::Error, 146, "CopyFileTo"); return; }

            string content = ReadFileToEnd(source, verbose);
            WriteFile(destination, content, verbose);
        }

        // Rename file
        void RenameFile(const string &in filePath, const string &in newFileName, bool verbose = false) {
            if (verbose) log("Attempting to rename file: " + filePath, LogLevel::Info, 154, "RenameFile");
            if (!IO::FileExists(filePath)) { log("File does not exist: " + filePath, LogLevel::Error, 155, "RenameFile"); return; }

            string currentPath = filePath;
            string newPath;

            string sanitizedNewName = Path::SanitizeFileName(newFileName);

            if (Directory::IsDirectory(newPath)) {
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
        }
    }

    void OpenFolder(const string &in path, bool verbose = false) {
        if (IO::FolderExists(path)) {
            OpenExplorerPath(path);
        } else {
            if (verbose) log("Folder does not exist: " + path, LogLevel::Info, 183, "OpenFolder");
        }
    }
}

namespace _Game {
    bool IsMapLoaded() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap is null) return false;
        return true;
    }

    bool IsPlayingMap() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app is null) return false;

        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
        return !(playground is null || playground.Arena.Players.Length == 0);
    }

    bool IsInEditor() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app is null) return false;

        CSmArenaClient@ e = cast<CSmArenaClient>(app.Editor);
        if (e !is null) return true;
        return false;
    }

    bool IsPlayingInEditor() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app is null) return false;

        CSmArenaClient@ e = cast<CSmArenaClient>(app.Editor);
        if (e is null) return false;
        
        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
        if (playground is null) return false;

        return true;
    }
}

namespace _Net {
    dictionary downloadedData;

    array<UserData@> userData;

    class UserData {
        string key;
        string[] values;

        UserData(const string &in _key, const string[] &_values) {
            key = _key;
            values = _values;
        }
    }

    void PostJsonToEndpoint(const string &in url, const string &in payload, const string &in key) {
        auto data = UserData(key, {url, payload});
        userData.InsertLast(data);
        startnew(Hidden::Coro_PostJsonToEndpoint, @data);
    }
    
    void DownloadFileToDestination(const string &in url, const string &in destination, const string &in key, const string &in overwriteFileName = "", bool noTmp = false) {
        auto data = UserData(key, {url, destination, overwriteFileName, noTmp ? "true" : "false"});
        userData.InsertLast(data);
        startnew(Hidden::Coro_DownloadFileToDestination, @data);
    }

    namespace Hidden {
        void Coro_PostJsonToEndpoint(UserData@ data) {
            if (data.values.Length < 1) {
                log("Insufficient data in UserData for PostJsonToEndpoint", LogLevel::Error, 256, "Coro_PostJsonToEndpoint");
                return;
            }

            string url = data.values[0];
            string payload = data.values[1];
            string key = data.key;

            Net::HttpRequest@ request = Net::HttpRequest();
            request.Url = url;
            request.Method = Net::HttpMethod::Post;
            request.Body = payload;
            request.Start();

            while (!request.Finished()) {
                yield();
            }

            if (request.ResponseCode() == 200) {
                downloadedData[key] = request.String();
                log("Successfully stored raw response for key: " + key, LogLevel::Info, 273, "Coro_PostJsonToEndpoint");
            } else {
                log("Failed to post JSON to endpoint: " + url + ". Response code: " + request.ResponseCode(), LogLevel::Error, 275, "Coro_PostJsonToEndpoint");
                downloadedData[key] = "{\"error\": \"Failed to fetch data\", \"code\": " + request.ResponseCode() + "}";
            }
        }

        void Coro_DownloadFileToDestination(UserData@ data) {
            if (data.values.Length < 4) {
                log("Insufficient data in UserData for DownloadFileToDestination", LogLevel::Error, 282, "Coro_DownloadFileToDestination");
                return;
            }

            string url = data.values[0];
            string destination = data.values[1];
            string overwriteFileName = data.values[2];
            bool noTmp = data.values[3] == "true";

            destination = Path::GetDirectoryName(destination);

            Net::HttpRequest@ request = Net::HttpRequest();
            request.Url = url;
            request.Method = Net::HttpMethod::Get;
            request.Start();

            while (!request.Finished()) { yield(); }

            if (request.ResponseCode() == 200) {
                string contentDisposition = Json::Write(request.ResponseHeaders().ToJson().Get("content-disposition"));
                string fileName = overwriteFileName;

                if (fileName == "") {
                    if (contentDisposition != "") {
                        int index = contentDisposition.IndexOf("filename=");
                        if (index != -1) {
                            fileName = contentDisposition.SubStr(index + 9);
                            fileName = fileName.Trim();
                            fileName = fileName.Replace("\"", "");
                        }
                    }

                    if (fileName == "") {
                        fileName = Path::GetFileName(url);
                    }
                }

                destination = Path::Join(destination, fileName);
                if (destination.EndsWith("/") || destination.EndsWith("\\")) {
                    destination = destination.SubStr(0, destination.Length - 1);
                }

                string tmpPath = Path::Join(IO::FromUserGameFolder(""), fileName);

                request.SaveToFile(tmpPath);
                _IO::File::CopyFileTo(tmpPath, destination);

                if (!IO::FileExists(tmpPath)) { log("Failed to save file to: " + tmpPath, LogLevel::Error, 329, "Coro_DownloadFileToDestination"); return; }

                if (!IO::FileExists(destination)) { log("Failed to move file to: " + destination, LogLevel::Error, 331, "Coro_DownloadFileToDestination"); return; }

                IO::Delete(tmpPath);

                if (!IO::FileExists(tmpPath) && IO::FileExists(destination)) {
                    log("File downloaded successfully, saving " + fileName + " to: " + destination, LogLevel::Info, 336, "Coro_DownloadFileToDestination");

                    downloadedData[data.key] = destination;

                    while (true) {
                        sleep(10000);
                        array<string> keys = downloadedData.GetKeys();
                        for (uint i = 0; i < keys.Length; i++) {
                            downloadedData.Delete(keys[i]);
                        }
                    }
                }
            } else {
                log("Failed to download file. Response code: " + request.ResponseCode(), LogLevel::Error, 349, "Coro_DownloadFileToDestination");
            }
        }
    }
}