#include "pch.h"
#include <windows.h>
#include <iostream>

extern "C" __declspec(dllexport) int64_t GetFileCreationTime(const wchar_t* filePath) {
    HANDLE hFile = CreateFileW(filePath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        return -1; // Cannot open file
    }

    FILETIME ftCreate;
    if (!GetFileTime(hFile, &ftCreate, NULL, NULL)) {
        CloseHandle(hFile);
        return -2; // Cannot get file time
    }

    CloseHandle(hFile);

    ULARGE_INTEGER uli;
    uli.LowPart = ftCreate.dwLowDateTime;
    uli.HighPart = ftCreate.dwHighDateTime;
    return static_cast<int64_t>(uli.QuadPart);
}