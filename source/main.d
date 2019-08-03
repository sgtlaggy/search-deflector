import core.runtime: Runtime;
import core.sys.windows.windows;
import std.conv: to;
import std.stdio: writeln;
import std.string: toStringz;
import std.utf: toUTF16z, toUTF8;
import std.windows.registry: RegistryException;
import setup: getAvailableBrowsers;
import common: parseConfig, mergeAAs, createErrorDialog, ENGINE_TEMPLATES, PROJECT_VERSION;

/// Entry point for SUBSYSTEM:WINDOWS
extern (Windows) int WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int) { // @suppress(dscanner.style.phobos_naming_convention)
    ConfigWindow window;

    try {
        Runtime.initialize();

        window = ConfigWindow(hInstance);
        window.begin();

        Runtime.terminate();
    } catch (Throwable error) { // @suppress(dscanner.suspicious.catch_em_all)
        createErrorDialog(error);
    }

    return !window.success;
}

/// Structure for creating and managing a configuration window along with
/// updating the regustry according to the Windows API messaging system.
struct ConfigWindow {
    /// Documents the success of all things done by this object.
    /// This bit is flipped when a nothrow function has a problem,
    /// it is also the exit message for the program.
    bool success = true;

    string className = "com.spikespaz.searchdeflector";
    string wndName = "Search Deflector";
    int wndWidth = 500;
    int wndHeight = 500;

    MSG message;
    HWND hWnd;

    string[string] browsers;
    string[string] engines;

    /// Constructor for ConfigWindow, takes HINSTANCE from WinMain.
    this(HINSTANCE hInstance) {
        // dfmt off
        WNDCLASSW wc = {
            style: CS_HREDRAW | CS_VREDRAW,
            lpfnWndProc: (&this.wndProc).funcptr,
            cbClsExtra: 0,
            cbWndExtra: 0,
            hInstance: hInstance,
            hIcon: LoadIcon(NULL, IDI_APPLICATION),
            hCursor: LoadCursor(NULL, IDC_ARROW),
            hbrBackground: GetSysColorBrush(COLOR_3DFACE),
            lpszMenuName: null,
            lpszClassName: this.className.toUTF16z
        };
        // dfmt on

        RegisterClassW(&wc);

        this.hWnd = CreateWindowW(this.className.toUTF16z, this.wndName.toUTF16z,
                WS_OVERLAPPEDWINDOW, 0, 0, this.wndWidth, this.wndHeight, null,
                null, hInstance, null);

        if (!centerWindow(this.hWnd))
            this.success = false;
    }

    /// Function to start the main window message loop.
    void begin() {
        this.browsers = getAvailableBrowsers(false);
        this.engines = parseConfig(ENGINE_TEMPLATES);
        
        try {
            this.browsers = mergeAAs(browsers, getAvailableBrowsers(true));
        } catch (RegistryException) {
            assert(0);
        } // Just ignore if no browsers in HKCU

        ShowWindow(this.hWnd, SW_SHOWNORMAL);

        while (GetMessage(&message, null, 0, 0)) {
            TranslateMessage(&message);
            DispatchMessage(&message);
        }
    }

    /// This window's procedure callback.
    extern(Windows) LRESULT wndProc(HWND, uint message, WPARAM wParam, LPARAM lParam) nothrow {
        switch (message) {
        case WM_CREATE:
            try {
                this.drawWindow();
            } catch (Throwable error) { // @suppress(dscanner.suspicious.catch_em_all)
                createErrorDialog(error);

                this.success = false;
            }
            break;
        case WM_DESTROY:
            PostQuitMessage(!this.success);
            break;
        default:
            break;
        }

        return DefWindowProcW(hWnd, message, wParam, lParam);
    }

    /// Draw the window controls.
    void drawWindow() {
    }
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

    result = SetWindowPos(hwnd, HWND_TOP, wndPosX, wndPosY, 0, 0, SWP_NOREDRAW | SWP_NOSIZE);

    return result;
}
