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

/// Entry point for this program, Search Deflector's config GUI.
int windowMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int) {
    int result;

    MSG msg;
    HWND hwnd;
    WNDCLASSW wc;

    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = &WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = hInstance;
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
    wc.lpszMenuName = null;
    wc.lpszClassName = "com.spikespaz.searchdeflector".toUTF16z();

    RegisterClassW(&wc);

    LPCTSTR lpWindowName = "Search Deflector Configuration".toUTF16z();
    DWORD dwStyle = WS_OVERLAPPEDWINDOW | WS_VISIBLE;

    // Below is my hacky way of hiding the window before the SetWindowPos is used for centering on the monitor.
    const int wndWidth = 500;
    const int wndHeight = 500;

    HWND hWndParent = null;
    HMENU hMenu = null;
    LPVOID lpParam = null;

    hwnd = CreateWindowW(wc.lpszClassName, lpWindowName, dwStyle, -1_000_000,
            -1_000_000, wndPosY, wndWidth, wndHeight, hWndParent, hMenu, hInstance, lpParam);

    result = centerWindow(hwnd);
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

/// Takes a window handle as input and centers in the middle of the most appropriate monitor.
int centerWindow(HWND hwnd) {
    int result;

    HMONITOR monitor;
    MONITORINFO lpmi;
    RECT wndRect;

    result = GetWindowRect(hwnd, &wndRect);

    lpmi.cbSize = MONITORINFO.sizeof;

    monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    if (!monitor)
        return 1;

    result = GetMonitorInfo(monitor, &lpmi);
    if (!result)
        return result;

    const int wndWidth = wndRect.right - wndRect.left;
    const int wndHeight = wndRect.bottom - wndRect.top;
    const int wndPosX = (lpmi.rcMonitor.left + lpmi.rcMonitor.right - wndWidth) / 2;
    const int wndPosY = (lpmi.rcMonitor.top + lpmi.rcMonitor.bottom - wndHeight) / 2;

    result = SetWindowPos(hwnd, HWND_TOP, wndPosX, wndPosY, 0, 0,
            SWP_NOREDRAW | SWP_NOSIZE | SWP_SHOWWINDOW);

    return result;
}
