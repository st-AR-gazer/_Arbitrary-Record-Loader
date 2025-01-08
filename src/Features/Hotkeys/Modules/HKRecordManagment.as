namespace Features {
namespace Hotkeys {

    namespace HKRecordManagment {
        class RecordManagmentHotkeyModule : Features::Hotkeys::IHotkeyModule {
            array<string> actions = {
                "Open/Close Interface", "Open Interface", "Close Interface"
            };

            void Initialize() { }

            array<string> GetAvailableActions() {
                return actions;
            }

            bool ExecuteAction(const string &in action, Features::Hotkeys::Hotkey@ hotkey) {
                if (action == "Open/Close Interface") {
                    S_windowOpen = !S_windowOpen;
                    return true;
                } else if (action == "Open Interface") {
                    S_windowOpen = true;
                    return true;
                } else if (action == "Close Interface") {
                    S_windowOpen = false;
                    return true;
                }
                return false;
            }
        }

        Features::Hotkeys::IHotkeyModule@ CreateInstance() {
            return RecordManagmentHotkeyModule();
        }
    }

    void RenderInterface() {
        if (S_windowOpen) {
            Features::Hotkeys::RT_Hotkeys_Popout();
        }
    }

}
}