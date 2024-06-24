// Fun Utils I use from time to time

namespace _Text {
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
    }

    namespace File {
        bool IsFile(const string &in path) {
            if (IO::FileExists(path)) return true;
            return false;
        }

        string GetFileName(const string &in path) {
            int index = _Text::LastIndexOf(path, "/");
            if (index == -1) {
                return path;
            }
            return path.SubStr(index + 1);
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

        void SafeWriteToFile(const string &in path, const string &in content, bool shouldUseRecursion = true, bool shouldLogFilePath = false, bool verbose = false) {
            if (shouldLogFilePath) { print(path); }

            string noFilePath = _IO::File::StripFileNameFromFilePath(path);
            if (!_IO::Folder::IsDirectory(path)) { path = noFilePath; }
            if (shouldUseRecursion) _IO::Folder::SafeCreateFolder(path, shouldUseRecursion);
            
            IO::File file;
            file.Open(path, IO::FileMode::Write);
            file.Write(content);
            file.Close();
        }

        void WriteJsonToFile(const string &in path, const Json::Value &in value) {
            string content = Json::Write(value);
            WriteToFile(path, content);
        }

        // Read from file
        string ReadFileToEnd(const string &in path, bool verbose = false) {
            if (!IO::FileExists(path)) {
                log("File does not exist: " + path, LogLevel::Error, 157, "ReadFileToEnd");
                return "";
            }
            IO::File file(path, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();
            return content;
        }
        
        string ReadSourceFileToEnd(const string &in path, bool verbose = false) {
            if (!IO::FileExists(path)) {
                log("File does not exist: " + path, LogLevel::Error, 168, "ReadSourceFileToEnd");
                return "";
            }

            IO::FileSource f(path);
            string content = f.ReadToEnd();
            return content;
        }

        // Move file
        void MoveFile(const string &in source, const string &in destination, bool shouldUseSafeMode = false, bool verbose = false) {
            if (!IO::FileExists(source)) { if (verbose) log("Source file does not exist: " + source, LogLevel::Error, 179, "MoveFile"); return; }
            if (IO::FileExists(destination)) { if (verbose) log("Destination file already exists: " + destination, LogLevel::Error, 180, "MoveFile"); return; }

            IO::File file;
            file.Open(source, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();

            SafeWriteToFile(destination, content, shouldUseSafeMode, false, verbose);
            IO::Delete(source);
        }

        // Copy file
        void CopyMoveFile(const string &in source, const string &in destination, bool verbose = false) {
            if (!IO::FileExists(source)) { if (verbose) log("Source file does not exist: " + source, LogLevel::Error, 193, "CopyMoveFile"); return; }
            if (IO::FileExists(destination)) { if (verbose) log("Destination file already exists: " + destination, LogLevel::Error, 194, "CopyMoveFile"); return; }

            IO::File file;
            file.Open(source, IO::FileMode::Read);
            string content = file.ReadToEnd();
            file.Close();

            SafeWriteToFile(destination, content, true, false, verbose);
        }
    }

    void OpenFolder(const string &in path, bool verbose = false) {
        if (IO::FolderExists(path)) {
            OpenExplorerPath(path);
        } else {
            if (verbose) log("Folder does not exist: " + path, LogLevel::Info, 209, "OpenFolder");
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