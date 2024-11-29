// ToggleGhostVisibilityHook.as
namespace ToggleGhostVisibilityHook {

    class ToggleGhostVisibilityUpdateHook : MLHook::HookMLEventsByType {
        ToggleGhostVisibilityUpdateHook(const string &in typeToHook) {
            super(typeToHook);
        }

        void OnEvent(MLHook::PendingEvent@ event) override {
            if (this.type != "TMGame_Record_ToggleGhost") return;

            string pid = event.data[0];
            int offset = event.data[1];

            if (event.data.Length >= 2) {
                ToggleGhostMgr::UpdateLoadedGhosts(pid, offset);
            }
            else {
                log("TMGame_Record_ToggleGhost event data is incomplete.", LogLevel::Error, 20, "ToggleGhostVisibilityHook");
            }
        }
    }

    ToggleGhostVisibilityUpdateHook@ toggleGhostHook;

    void InitializeHook() {
        @toggleGhostHook = ToggleGhostVisibilityUpdateHook("TMGame_Record_ToggleGhost");
        MLHook::RegisterMLHook(toggleGhostHook, "TMGame_Record_ToggleGhost", true);
    }

    void UninitializeHook() {
        if (toggleGhostHook !is null) {
            MLHook::UnregisterMLHookFromAll(toggleGhostHook);
            @toggleGhostHook = null;
        }
    }
}