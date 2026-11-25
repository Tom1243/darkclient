#define UNICODE
#include <windows.h>
#include <wchar.h>

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE previous, PWSTR arguments, int show) {
    wchar_t executable[MAX_PATH], powershell[MAX_PATH], command[MAX_PATH * 3];
    DWORD size = GetModuleFileNameW(NULL, executable, MAX_PATH);
    if (!size || size >= MAX_PATH) return 1;
    SetEnvironmentVariableW(L"DARKEDEN_LAUNCHER", executable);
    wchar_t *separator = wcsrchr(executable, L'\\');
    if (!separator) return 1;
    *separator = 0;
    if (!GetSystemDirectoryW(powershell, MAX_PATH) ||
        wcscat_s(powershell, MAX_PATH, L"\\WindowsPowerShell\\v1.0\\powershell.exe")) return 1;
    if (swprintf(command, sizeof(command)/sizeof(*command),
        L"\"%ls\" -NoProfile -STA -ExecutionPolicy Bypass -File \"%ls\\menu.ps1\"", powershell, executable) < 0) return 1;
    STARTUPINFOW startup = {0};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process = {0};
    if (!CreateProcessW(powershell, command, NULL, NULL, FALSE, CREATE_NEW_CONSOLE, NULL, executable, &startup, &process)) {
        MessageBoxW(NULL, L"Could not open Windows PowerShell.", L"Dark Eden", MB_ICONERROR);
        return 1;
    }
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return 0;
}
