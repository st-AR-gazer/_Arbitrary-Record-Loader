#include <windows.h>
#include <string>

extern "C" __declspec(dllexport) int64_t GetFileCreationTime(const char* filename) {
    HANDLE hFile = CreateFileA(filename, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        return -1;
    }

    FILETIME creationTime;
    if (!GetFileTime(hFile, &creationTime, NULL, NULL)) {
        CloseHandle(hFile);
        return -1;
    }

    CloseHandle(hFile);

    ULARGE_INTEGER ull;
    ull.LowPart = creationTime.dwLowDateTime;
    ull.HighPart = creationTime.dwHighDateTime;

    return static_cast<int64_t>(ull.QuadPart);
}
