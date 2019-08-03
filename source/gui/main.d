import core.runtime: Runtime;
import core.sys.windows.windows;
import std.conv: to;
import std.stdio: writeln;
import std.string: toStringz;
import std.utf: toUTF16z, toUTF8;

extern (Windows) int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
        LPSTR lpCmdLine, int nCmdShow) {
    int result;

    try {
        Runtime.initialize();

        result = windowMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow);

        Runtime.terminate();
    } catch (Throwable e) {
        MessageBoxA(null, e.toString().toStringz(), null, MB_ICONEXCLAMATION);

        result = 0;
    }

    return result;
}

extern (Windows) LRESULT WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) nothrow {
    switch (msg) {
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    default:
        break;
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int windowMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    int result;

    MSG msg;
    HWND hwnd;
    WNDCLASSW wc;

    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.lpszClassName = "com.spikespaz.searchdeflector"w.toUTF16z();
    wc.hInstance = hInstance;
    wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
    wc.lpszMenuName = null;
    wc.lpfnWndProc = &WndProc;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);

    RegisterClassW(&wc);

    LPCTSTR lpWindowName = "Search Deflector Configuration".toUTF16z();
    DWORD dwStyle = WS_OVERLAPPEDWINDOW | WS_VISIBLE;

    // Below is my hacky way of hiding the window before the SetWindowPos is used for centering on the monitor.
    int wndPosX = -1_000_000;
    int wndPosY = -1_000_000;
    int wndWidth = 500;
    int wndHeight = 500;
    HWND hWndParent = null;
    HMENU hMenu = null;
    LPVOID lpParam = null;

    hwnd = CreateWindowW(wc.lpszClassName, lpWindowName, dwStyle, wndPosX,
            wndPosY, wndWidth, wndHeight, hWndParent, hMenu, hInstance, lpParam);

    HMONITOR monitor;
    MONITORINFO lpmi;

    lpmi.cbSize = MONITORINFO.sizeof;

    monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    if (!monitor)
        return 1;

    result = GetMonitorInfo(monitor, &lpmi);
    if (!result)
        return result;

    wndPosX = (lpmi.rcMonitor.left + lpmi.rcMonitor.right - wndWidth) / 2;
    wndPosY = (lpmi.rcMonitor.top + lpmi.rcMonitor.bottom - wndHeight) / 2;

    result = SetWindowPos(hwnd, HWND_TOP, wndPosX, wndPosY, 0, 0,
            SWP_NOREDRAW | SWP_NOSIZE | SWP_SHOWWINDOW);
    if (!result)
        return result;

    result = UpdateWindow(hwnd);
    if (!result)
        return result;

    while (GetMessage(&msg, null, 0, 0)) {
        DispatchMessage(&msg);
    }

    return msg.wParam.to!int;
}
