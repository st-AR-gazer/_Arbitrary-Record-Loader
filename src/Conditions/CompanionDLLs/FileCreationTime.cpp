#include "pch.h"
#include <windows.h>
#include <string>
#include <algorithm>

enum class ErrorCodes {
    FILENAME_MATCHES_SPECIFIED_STRING = -50,
    FILE_NOT_FOUND = -1001,
    ACCESS_DENIED = -1003,
    INVALID_FILE_NAME = -1005,
    GENERIC_FILE_ACCESS = -1006,
    PATH_DETECTION_FAILURE = -2001,
    PATH_NORMALIZATION_FAILED = -2002
};

std::wstring normalizePath(const std::wstring& inputPath) {
    std::wstring path = inputPath;
    std::wstring result;

    for (const wchar_t& ch : path) {
        if (ch == L'\\' || ch == L'/') {
            result.append(L"\\\\"); // Change this to be one \\ ?
        }
        else {
            result.push_back(ch);
        }
    }
    return result;
}

extern "C" __declspec(dllexport) int64_t GetFileCreationTime(const wchar_t* filePath) {
    std::wstring path = normalizePath(filePath);
    if (path.empty()) {
        return static_cast<int>(ErrorCodes::PATH_NORMALIZATION_FAILED);
    }
    if (path == L"") {
        return static_cast<int>(ErrorCodes::INVALID_FILE_NAME);
    }
    if (path == L"") { // Add proper file name check here... (Find out _why_ it works for the harcoded path, but not the inserted path...)
                       // it seems most likely that the path is not the same as the hardcoded path, but I'm not sure why that would be the case...
                       // Since the one I'm passing should be the same... Well I guess we'll see...
        return static_cast<int>(ErrorCodes::FILENAME_MATCHES_SPECIFIED_STRING);
    }

    HANDLE hFile = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        return static_cast<int>(ErrorCodes::FILE_NOT_FOUND) - GetLastError();
    }

    FILETIME ftCreate;
    if (!GetFileTime(hFile, &ftCreate, NULL, NULL)) {
        CloseHandle(hFile);
        return static_cast<int>(ErrorCodes::GENERIC_FILE_ACCESS);
    }

    CloseHandle(hFile);
    ULARGE_INTEGER uli;
    uli.LowPart = ftCreate.dwLowDateTime;
    uli.HighPart = ftCreate.dwHighDateTime;
    return static_cast<int64_t>(uli.QuadPart);
}
