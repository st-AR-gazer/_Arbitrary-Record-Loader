namespace Features {
namespace Hotkeys {

namespace InterfaceModule {
    class InterfaceModule : Features::Hotkeys::IHotkeyModule {
        array<string> actions = {
            "Open/Close Record Managment Interface", "Open Record Managment Interface", "Close Record Managment Interface"
        };

        void Initialize() { }

        array<string> GetAvailableActions() {
            return actions;
        }

        bool ExecuteAction(const string &in action, Features::Hotkeys::Hotkey@ hotkey) {
            if (action == "Open/Close Record Managment Interface") {
                S_windowOpen = !S_windowOpen;
                return true;
            } else if (action == "Open Record Managment Interface") {
                S_windowOpen = true;
                return true;
            } else if (action == "Close Record Managment Interface") {
                S_windowOpen = false;
                return true;
            }
            return false;
        }
    }

    Features::Hotkeys::IHotkeyModule@ CreateInstance() {
        return InterfaceModule();
    }
}

}
}