// Fun Utils I use from time to time

namespace _Text {
    // int NthIndexOf(const string &in str, const string &in value, int n) {
    //     int index = -1;
    //     for (int i = 0; i < n; ++i) {
    //         index = str.IndexOf(value, index + 1);
    //         if (index == -1) break;
    //     }
    //     return index;
    // }

    int LastIndexOf(const string &in str, const string &in value) {
        int lastIndex = -1;
        int index = str.IndexOf(value);
        while (index != -1) { 
            lastIndex = index;
            if (index + value.Length >= str.Length) break;
            index = str.SubStr(index + value.Length).IndexOf(value);
            if (index != -1) {
                index += lastIndex + value.Length;
            }
        }
        return lastIndex;
    }

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
    namespace Folder {
        bool IsDirectory(const string &in path) {
            if (path.EndsWith("/") || path.EndsWith("\\")) return true;
            return false;
        }

        void RecursiveCreateFolder(const string &in path) {
            if (IO::FolderExists(path)) return;

            int index = _Text::LastIndexOf(path, "/");
            if (index == -1) return;

            RecursiveCreateFolder(path.SubStr(0, index));
            IO::CreateFolder(path);
        }
        
        void SafeCreateFolder(const string &in path, bool shouldUseRecursion = true) {
            if (!IO::FolderExists(path)) {
                if (shouldUseRecursion) {
                    RecursiveCreateFolder(path);
                } else {
                    IO::CreateFolder(path);
                }
            }
        }

        string GetFolderName(const string &in path) {
            string trimmedPath = path;
            
            while (trimmedPath.EndsWith("/") || trimmedPath.EndsWith("\\")) {
                trimmedPath = trimmedPath.SubStr(0, trimmedPath.Length - 1);
            }
            
            int index = _Text::LastIndexOf(trimmedPath, "/");
            int index2 = _Text::LastIndexOf(trimmedPath, "\\");

            index = Math::Max(index, index2);

            if (index == -1) {
                return trimmedPath;
            }

            return trimmedPath.SubStr(index + 1);
        }

        string GetFolderPath(const string &in path) {
            string trimmedPath = path;
            
            while (trimmedPath.EndsWith("/") || trimmedPath.EndsWith("\\")) {
                trimmedPath = trimmedPath.SubStr(0, trimmedPath.Length - 1);
            }
            
            int index = _Text::LastIndexOf(trimmedPath, "/");
            int index2 = _Text::LastIndexOf(trimmedPath, "\\");

            index = Math::Max(index, index2);

            if (index == -1) {
                return "";
            }

            return trimmedPath.SubStr(0, index);
        }
    }

    namespace File {
        bool IsFile(const string &in path) {
            if (IO::FileExists(path)) return true;
            return false;
        }

        string GetFileName(const string &in path) {
            if (_IO::Folder::IsDirectory(path)) { log("This is a folder", LogLevel::Error, 141, "GetFileName"); return "";  }
            
            int index = _Text::LastIndexOf(path, "/");
            int backslashIndex = _Text::LastIndexOf(path, "\\");
            if (backslashIndex > index) { index = backslashIndex; }
            if (index == -1) { return path; }
            return path.SubStr(index + 1);
        }

        string GetFilePathWithoutFileName(const string &in path) {
            int index = _Text::LastIndexOf(path, "/");
            int backslashIndex = _Text::LastIndexOf(path, "\\");
            if (backslashIndex > index) { index = backslashIndex; }
            if (index == -1) { return path; }
            return path.SubStr(0, index);
        }
        
        string GetFileNameWithoutExtension(const string &in path) {
            string fileName = _IO::File::GetFileName(path);
            int index = _Text::LastIndexOf(fileName, ".");
            if (index == -1) {
                return fileName;
            }
            return fileName.SubStr(0, index);
        }

        string GetFileExtension(const string &in path) {
            if (_IO::Folder::IsDirectory(path)) { return ""; }

            int index = _Text::LastIndexOf(path, ".");
            if (index == -1) {
                return "";
            }
            return path.SubStr(index + 1);
        }
        
        string StripFileNameFromFilePath(const string &in path) {
            int index = _Text::LastIndexOf(path, "/");
            int index2 = _Text::LastIndexOf(path, "\\");
            index = Math::Max(index, index2);
            if (index == -1) return path;
            return path.SubStr(0, index);
        }

        // Write to file
        void WriteToFile(const string &in path, const string &in content) {
            IO::File file;
            file.Open(path, IO::FileMode::Write);
            file.Write(content);
            file.Close();
        }

        void SafeWriteToFile(string _path, const string &in content, bool shouldUseRecursion = true, bool shouldLogFilePath = false, bool verbose = false) {
            if (shouldLogFilePath) { print(_path); }

            string noFilePath = _IO::File::StripFileNameFromFilePath(_path);
            if (!_IO::Folder::IsDirectory(_path)) { _path = noFilePath; }
            if (shouldUseRecursion) _IO::Folder::SafeCreateFolder(_path, shouldUseRecursion);
            
            IO::File file;
            file.Open(_path, IO::FileMode::Write);
            file.Write(content);
            file.Close();
        }

        void WriteJsonToFile(const string &in path, const Json::Value &in value) {
            string content = Json::Write(value);
            SafeWriteToFile(path, content);
        }

        // Read from file
        string ReadFileToEnd(const string &in path, bool verbose = false) {
            if (!IO::FileExists(path)) {
                log("File does not exist: " + path, LogLevel::Error, 214, "ReadFileToEnd");
                return "";
            }
            IO::File file(path, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();
            return content;
        }
        
        string ReadSourceFileToEnd(const string &in path, bool verbose = false) {
            // if (!IO::FileExists(path)) { log("File does not exist: " + path, LogLevel::Error, 224, "ReadSourceFileToEnd"); return ""; }
            // FileSource assumes the top dir is _PLUGINNAME_.op, not C:\ so this has to be assumed to be an existing path...

            IO::FileSource f(path);
            string content = f.ReadToEnd();
            return content;
        }

        // Move file
        void MoveFile(const string &in source, const string &in destination, bool shouldUseSafeMode = false, bool verbose = false) {
            if (!IO::FileExists(source)) { if (verbose) log("Source file does not exist: " + source, LogLevel::Error, 234, "MoveFile"); return; }
            if (IO::FileExists(destination)) { if (verbose) log("Destination file already exists: " + destination, LogLevel::Error, 235, "MoveFile"); return; }

            IO::File file;
            file.Open(source, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();

            SafeWriteToFile(destination, content, shouldUseSafeMode, false, verbose);
            IO::Delete(source);
        }

        void SafeMoveSourceFileToNonSource(const string &in originalPath, const string &in storagePath, bool verbose = false) {
            if (verbose) log("Moving the file content", LogLevel::Info, 247, "SafeMoveSourceFileToNonSource");
            
            string fileContents = _IO::File::ReadSourceFileToEnd(originalPath);
            _IO::Folder::SafeCreateFolder(_IO::File::StripFileNameFromFilePath(storagePath), true);
            _IO::File::WriteToFile(storagePath, fileContents);

            if (verbose) log("Finished moving the file", LogLevel::Info, 253, "SafeMoveSourceFileToNonSource");
        }

        void SafeMoveFileToNonSource(const string &in originalPath, const string &in storagePath, bool verbose = false) {
            if (verbose) log("Moving the file content", LogLevel::Info, 257, "SafeMoveFileToNonSource");
            
            string fileContents = _IO::File::ReadFileToEnd(originalPath);
            _IO::Folder::SafeCreateFolder(_IO::File::StripFileNameFromFilePath(storagePath), true);
            _IO::File::WriteToFile(storagePath, fileContents);

            if (verbose) log("Finished moving the file", LogLevel::Info, 263, "SafeMoveFileToNonSource");
        }

        // Copy file
        void CopyMoveFile(const string &in source, const string &in destination, bool verbose = false) {
            if (!IO::FileExists(source)) { if (verbose) log("Source file does not exist: " + source, LogLevel::Error, 268, "CopyMoveFile"); return; }
            if (IO::FileExists(destination)) { if (verbose) log("Destination file already exists: " + destination, LogLevel::Error, 269, "CopyMoveFile"); return; }

            IO::File file;
            file.Open(source, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();

            SafeWriteToFile(destination, content, true, false, verbose);
        }

        // Rename file
        void RenameFile(const string &in filePath, string _newFileName, bool verbose = false) {
            if (verbose) log("Attempting to rename file: " + filePath, LogLevel::Info, 281, "RenameFile");

            if (IO::FileExists(filePath)) {
                string dirPath = _IO::File::StripFileNameFromFilePath(filePath);
                string extension = _IO::File::GetFileExtension(filePath);
                string newFilePath = dirPath + "/" + _newFileName + (extension.Length==0 ? "" : "." + extension);

                verbose = true;
                if (verbose) {
                    log("Old File Path: " + filePath, LogLevel::Info, 290, "RenameFile");
                    log("New File Path: " + newFilePath, LogLevel::Info, 291, "RenameFile");
                }

                IO::File fileOld;
                fileOld.Open(filePath, IO::FileMode::Read);
                string fileContent = fileOld.ReadToEnd();
                fileOld.Close();

                IO::File fileNew;
                fileNew.Open(newFilePath, IO::FileMode::Write);
                fileNew.Write(fileContent);
                fileNew.Close();

                IO::Delete(filePath);
                if (verbose) log("File renamed successfully.", LogLevel::Info, 305, "RenameFile");
            } else {
                if (verbose) log("File does not exist: " + filePath, LogLevel::Info, 307, "RenameFile");
            }
        }

        // // Normal(safe) From[nn]File
        // void SafeFromAppFolder(const string &in path) {
        //     // Path is expected to IO::FromAppFolder("[n]")
        //     _IO::Folder::SafeCreateFolder(path, true);
        //     IO::FromAppFolder(path);
        // }
        // void SafeFromDataFolder(const string &in path) {
        //     // Path is expected to IO::FromDataFolder("[n]")
        //     _IO::Folder::SafeCreateFolder(path, true);
        //     IO::FromDataFolder(path);
        // }
        // void SafeFromStorageFolder(const string &in path) {
        //     // Path is expected to IO::FromStorageFolder("[n]")
        //     _IO::Folder::SafeCreateFolder(path, true);
        //     IO::FromStorageFolder(path);
        // }
        // void SafeFromUserGameFolder(const string &in path) {
        //     // Path is expected to IO::FromUserGameFolder("[n]")
        //     _IO::Folder::SafeCreateFolder(path, true);
        //     IO::FromUserGameFolder(path);
        // }
    }

    void OpenFolder(const string &in path, bool verbose = false) {
        if (IO::FolderExists(path)) {
            OpenExplorerPath(path);
        } else {
            if (verbose) log("Folder does not exist: " + path, LogLevel::Info, 338, "OpenFolder");
        }
    }
}

namespace _Json {
    string PrettyPrint(const Json::Value &in value) {
        string jsonStr = Json::Write(value);
        string pretty;
        int depth = 0;
        bool inString = false;

        for (int i = 0; i < jsonStr.Length; ++i) {
            string currentChar = jsonStr.SubStr(i, 1);

            if (currentChar == "\"") inString = !inString;

            if (!inString) {
                if (currentChar == "{" || currentChar == "[") {
                    pretty += currentChar + "\n" + Hidden::Indent(depth + 1);
                    ++depth;
                } else if (currentChar == "}" || currentChar == "]") {
                    --depth;
                    pretty += "\n" + Hidden::Indent(depth) + currentChar;
                } else if (currentChar == ",") {
                    pretty += currentChar + "\n" + Hidden::Indent(depth);
                } else if (currentChar == ":") {
                    pretty += currentChar + " ";
                } else {
                    pretty += currentChar;
                }
            } else {
                pretty += currentChar;
            }
        }

        pretty = "\n" + pretty;
        return pretty;
    }

    namespace Hidden {
        string Indent(int depth) {
            string indent;
            for (int i = 0; i < depth; ++i) {
                indent += "    ";
            }
            return indent;
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
    // void DownloadFile(const string &in url, string content) {
    //     startnew(Hidden::CoroDownloadFile, url, content);
    // }

    void DownloadFileToDestination(const string &in url, const string &in destination) {
        string userdata = url + "|" + destination;
        startnew(Hidden::CoroDownloadFileToDestination, userdata);
    }

    namespace Hidden {
        // void CoroDownloadFile(const string &in url, string content) {
        //     Net::HttpRequest@ request = Net::HttpRequest();
        //     request.Url = url;
        //     request.Method = Net::HttpMethod::Get;
        //     request.Start();
            
        //     while (!request.Finished()) {
        //         yield();
        //     }

        //     if (request.ResponseCode() == 200) {
        //         content = request.Body;
        //         NotifyInfo("File downloaded successfully, returning the content");
        //     } else {
        //         NotifyWarn("Failed to download file. Response code: " + request.ResponseCode());
        //         content = "";
        //     }
        // }

        void CoroDownloadFileToDestination(const string &in userdata) {
            array<string> parts = userdata.Split("|");
            if (parts.Length != 2) {
                NotifyWarn("Invalid userdata format.");
                return;
            }
            string url = parts[0];
            string destination = parts[1];

            Net::HttpRequest@ request = Net::HttpRequest();
            request.Url = url;
            request.Method = Net::HttpMethod::Get;
            request.Start();

            while (!request.Finished()) {
                yield();
            }

            if (request.ResponseCode() == 200) {
                _IO::File::SafeWriteToFile(destination, request.Body);
                NotifyInfo("File downloaded successfully and saved to: " + destination);
            } else {
                NotifyWarn("Failed to download file. Response code: " + request.ResponseCode());
            }
        }
    }
}