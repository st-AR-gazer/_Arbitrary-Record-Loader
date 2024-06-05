void NotifyWarn(const string &in msg) {
    UI::ShowNotification("Plugin Name", msg, vec4(1, .5, .1, .5), 6000);
}

void NotifyInfo(const string &in msg) {
    UI::ShowNotification("Plugin Name", msg, vec4(.2, .8, .5, .3), 6000);
}

enum LogLevel {
    Info,
    InfoG,
    Warn,
    Error,
    Test,
    Dark,
    _
};

//////////// CHANGE TO "true" ON RELEASE  ////////////
[Setting category="z~DEV" name="Show default OP logs"]
bool S_showDefaultLogs = false;
//////////////////////////////////////////////////////

[Setting category="z~DEV" name="Show Debug logs"]
bool S_showDebugLogs = true;

[Setting category="z~DEV" name="Show Info logs (INFO)"]
bool S_showInfoLogs = true;

[Setting category="z~DEV" name="Show InfoG logs (INFO-G)"]
bool S_showInfoGLogs = true;

[Setting category="z~DEV" name="Show Warn logs (WARN)"]
bool S_showWarnLogs = true;

[Setting category="z~DEV" name="Show Error logs (ERROR)"]
bool S_showErrorLogs = true;

[Setting category="z~DEV" name="Show Test logs (TEST)"]
bool S_showTestLogs = true;

[Setting category="z~DEV" name="Show Dark logs (Dark)"]
bool S_showDarkLogs = true;

[Setting category="z~DEV" name="Show Placeholder logs (PLACEHOLDER)"]
bool S_showPlaceholderLogs = true;


[Setting category="z~DEV" name="Show function name in logs"]
bool S_showFunctionNameInLogs = true;

[Setting category="z~DEV" name="Set max function name length in logs" min="0" max="50"]
int S_maxFunctionNameLength = 15;


void log(const string &in msg, LogLevel level = LogLevel::Info, int line = -1, string _functionName = "") {
    string lineInfo = line >= 0 ? " " + tostring(line) : "";
    int lineLength = lineInfo.Length - 1;
    string extraSpaces = "";
    if (lineLength == 1) {        // 1 character
        extraSpaces = "   ";      // Three extra spaces
    } else if (lineLength == 2) { // 2 characters
        extraSpaces = "  ";       // Two extra spaces
    } else if (lineLength == 3) { // 3 characters
        extraSpaces = " ";        // One extra space
    }
    lineInfo += extraSpaces;

    if (_functionName.Length > S_maxFunctionNameLength) {
        _functionName = _functionName.SubStr(0, S_maxFunctionNameLength);
    }
    int functionNameLength = _functionName.Length;
    if (functionNameLength < S_maxFunctionNameLength) {
        int numSpacesToAdd = S_maxFunctionNameLength - functionNameLength;
        for (int i = 0; i < numSpacesToAdd; i++) {
            _functionName += " ";
        }
    }

    bool doLog = false;
    switch(level) {
        case LogLevel::Info:  doLog = S_showInfoLogs;        break;
        case LogLevel::InfoG: doLog = S_showInfoGLogs;       break;
        case LogLevel::Warn:  doLog = S_showWarnLogs;        break;
        case LogLevel::Error: doLog = S_showErrorLogs;       break;
        case LogLevel::Test:  doLog = S_showTestLogs;        break;
        case LogLevel::Dark:  doLog = S_showDarkLogs;        break;
        case LogLevel::_:     doLog = S_showPlaceholderLogs; break;
    }

    if (!S_showDebugLogs) return;
    if (!S_showFunctionNameInLogs) {_functionName = "";}

    if (doLog) {
        switch(level) {
            case LogLevel::Info:  if(!S_showDefaultLogs) { print("\\$0ff[INFO]  " +       "\\$z" + "\\$0cc" + lineInfo + " : " + _functionName + " : \\$z" + msg); } else { trace(msg); } break;
            case LogLevel::InfoG: if(!S_showDefaultLogs) { print("\\$0f0[INFO-G]" +       "\\$z" + "\\$0c0" + lineInfo + " : " + _functionName + " : \\$z" + msg); } else { trace(msg); } break;
            case LogLevel::Warn:  if(!S_showDefaultLogs) { print("\\$ff0[WARN]  " +       "\\$z" + "\\$cc0" + lineInfo + " : " + _functionName + " : \\$z" + msg); } else { warn(msg);  } break;
            case LogLevel::Error: if(!S_showDefaultLogs) { print("\\$f00[ERROR] " +       "\\$z" + "\\$c00" + lineInfo + " : " + _functionName + " : \\$z" + msg); } else { error(msg); } break;
            case LogLevel::Test:  if(!S_showDefaultLogs) { print("\\$aaa[TEST]  " +       "\\$z" + "\\$aaa" + lineInfo + " : " + _functionName + " : \\$z" + msg); } else { trace(msg); } break;
            case LogLevel::Dark:  if(!S_showDefaultLogs) { print("\\$777[DARK]  " +       "\\$z" + "\\$777" + lineInfo + " : " + _functionName + " : \\$z" + msg); } else { trace(msg); } break;
            case LogLevel::_:     if(!S_showDefaultLogs) { print("\\$333[PLACEHOLDER] " + "\\$z" + "\\$333" + lineInfo + " : " + _functionName + " : \\$z" + msg); } else { trace(msg); } break;
        }
    }
}
