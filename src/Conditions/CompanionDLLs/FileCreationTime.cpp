#include <windows.h>
#include <iostream>
#include <iomanip>

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

void PrintFileCreationTime(const char* filename) {
    int64_t creationTime = GetFileCreationTime(filename);
    if (creationTime == -1) {
        std::cout << "Failed to get file creation time for: " << filename << std::endl;
        return;
    }

    // Convert to FILETIME
    FILETIME ft;
    ft.dwLowDateTime = static_cast<DWORD>(creationTime);
    ft.dwHighDateTime = static_cast<DWORD>(creationTime >> 32);

    // Convert FILETIME to system time
    SYSTEMTIME st;
    FileTimeToSystemTime(&ft, &st);

    // Print the creation time
    std::cout << "File creation time: "
              << st.wYear << "-"
              << std::setw(2) << std::setfill('0') << st.wMonth << "-"
              << std::setw(2) << std::setfill('0') << st.wDay << " "
              << std::setw(2) << std::setfill('0') << st.wHour << ":"
              << std::setw(2) << std::setfill('0') << st.wMinute << ":"
              << std::setw(2) << std::setfill('0') << st.wSecond << std::endl;
}

int main() {
    // Define the path to the target file
    const char* filename = "../../Main.as";
    PrintFileCreationTime(filename);
    return 0;
}
