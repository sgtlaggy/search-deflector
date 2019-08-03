module common;

import core.sys.windows.windows: CommandLineToArgvW, MessageBox, MB_ICONERROR, MB_YESNO, IDYES;
import std.windows.registry: Registry, RegistryException, Key, REGSAM;
import std.string: strip, splitLines, indexOf, stripLeft;
import std.uri: encodeComponent;
import std.process: browse;
import std.format: format;
import std.conv: to;

/// File name of the executable to download and run to install an update.
enum string SETUP_FILENAME = "SearchDeflector-Installer.exe";
/// Repository path information for Search Deflector, https://github.com/spikespaz/search-deflector.
enum string PROJECT_AUTHOR = "spikespaz";
enum string PROJECT_NAME = "search-deflector"; /// ditto
/// Current version of the Search Deflector binaries.
enum string PROJECT_VERSION = import("version.txt");

/// String of search engine templates.
enum string ENGINE_TEMPLATES = import("engines.txt");
/// String of the GitHub issue template.
enum string ISSUE_TEMPLATE = import("issue.txt");

/// URL of the wiki's thank-you page.
enum string WIKI_THANKS_URL = "https://github.com/spikespaz/search-deflector/wiki/Thanks-for-using-Search-Deflector!";

/// Creates a message box telling the user there was an error, and redirect to issues page.
void createErrorDialog(const Throwable error) nothrow {
    // dfmt off
    try {
        const uint messageId = MessageBox(null,
                "Search Deflector launch failed. Would you like to open the issues page to submit a bug report?" ~
                "\nThe important information will be filled out for you." ~
                "\n\nIf you do not wish to create a bug report, click 'No' to exit.",
                "Search Deflector", MB_ICONERROR | MB_YESNO);

        if (messageId == IDYES)
            browse("https://github.com/spikespaz/search-deflector/issues/new?body=" ~
                createIssueMessage(error).encodeComponent());
    } catch (Throwable) { // @suppress(dscanner.suspicious.catch_em_all)
        assert(0);
    }
    // dfmt on
}

/// Creates a GitHub issue body with the data from an Exception.
string createIssueMessage(const Throwable error) {
    return ISSUE_TEMPLATE.strip().format(error.file, error.line, error.msg, error.info);
}

/// Return a string array of arguments that are parsed in ArgV style from a string.
string[] getConsoleArgs(const wchar* commandLine) {
    int argCount;
    wchar** argList = CommandLineToArgvW(commandLine, &argCount);
    string[] args;

    for (int index; index < argCount; index++)
        args ~= argList[index].to!string();

    return args;
}

/// Class handling registry reads and writes for deflector settings.
class DeflectorSettings {
    string engineURL; /// ditto
    string browserPath; /// ditto
    uint searchCount; /// Counter for how many times the user has made a search query.
    bool freeVersion; /// Flag to determine if this is the classic version from GitHub.

    /// Default constructor that attempts to read registry settings into class fields,
    /// reverting to defaults when regitry access errs.
    this() {
        try
            this.read();
        catch (RegistryException)
            this("google.com/search?q={{query}}", "system_default", 0, false);
    }

    /// Boilerplate constructor populating instance fields from passed argument values.
    this(string engineURL, string browserPath, uint searchCount, bool freeVersion) {
        this.engineURL = engineURL;
        this.browserPath = browserPath;
        this.searchCount = searchCount;
        this.freeVersion = freeVersion;
    }

    /// Read the settings from the registry.
    void read() {
        Key deflectorKey = Registry.currentUser.getKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_READ);

        this.engineURL = deflectorKey.getValue("EngineURL").value_SZ;
        this.browserPath = deflectorKey.getValue("BrowserPath").value_SZ;
        this.searchCount = deflectorKey.getValue("SearchCount").value_DWORD;
        this.freeVersion = deflectorKey.getValue("FreeVersion").value_DWORD.to!bool();
    }

    /// Write settings to registry.
    void write() {
        Key deflectorKey = Registry.currentUser.createKey("SOFTWARE\\Clients\\SearchDeflector", REGSAM.KEY_WRITE);

        // Write necessary changes.
        deflectorKey.setValue("EngineURL", this.engineURL);
        deflectorKey.setValue("BrowserPath", this.browserPath);
        deflectorKey.setValue("SearchCount", this.searchCount);
        deflectorKey.setValue("FreeVersion", this.freeVersion.to!uint());

        deflectorKey.flush();
    }
}

/// Get a config in the pattern of "^(?<key>[^:]+)\s*:\s*(?<value>.+)$" from a string.
string[string] parseConfig(const string config) {
    string[string] data;

    foreach (line; config.splitLines()) {
        if (line.stripLeft()[0 .. 2] == "//") // Ignore comments.
            continue;

        const size_t sepIndex = line.indexOf(":");

        const string key = line[0 .. sepIndex].strip();
        const string value = line[sepIndex + 1 .. $].strip();

        data[key] = value;
    }

    return data;
}

/// Merge two associative arrays, updating existing values in "baseAA" with new ones from "updateAA".
T[K] mergeAAs(T, K)(T[K] baseAA, T[K] updateAA) {
    T[K] newAA = baseAA;

    foreach (key; updateAA.byKey())
        newAA[key] = updateAA[key];

    return newAA;
}
