namespace GhostLoader {
    [Setting category="General" name="Toggle Load Ghost Hotkey"]
    VirtualKey g_toggleLoadGhostHotkey = VirtualKey::F9;

    [Setting hidden]
    bool S_UseGhostLayer = true;

    class ClearTask {
        CWebServicesTaskResult@ task;
        CMwNod@ nod;

        CGameUserManagerScript@ userMgr { get { return cast<CGameUserManagerScript>(nod); } }
        CGameDataFileManagerScript@ dataFileMgr { get { return cast<CGameDataFileManagerScript>(nod); } }
        CGameScoreAndLeaderBoardManagerScript@ scoreMgr { get { return cast<CGameScoreAndLeaderBoardManagerScript>(nod); } }

        ClearTask(CWebServicesTaskResult@ task, CMwNod@ owner) {
            @this.task = task;
            @nod = owner;
        }

        void Release() {
            if (userMgr !is null) userMgr.TaskResult_Release(task.Id);
            else if (dataFileMgr !is null) dataFileMgr.TaskResult_Release(task.Id);
            else if (scoreMgr !is null) scoreMgr.TaskResult_Release(task.Id);
            else warn("ClearTask.Release called but I don't know how to handle this type: " + Reflection::TypeOf(nod).Name);
        }
    }

    ClearTask@[] tasksToClear = {};

    void WaitAndClearTaskLater(CWebServicesTaskResult@ task, CMwNod@ owner) {
        while (task.IsProcessing) yield();
        tasksToClear.InsertLast(ClearTask(task, owner));
    }

    void ClearTaskCoro() {
        while (true) {
            yield();
            if (tasksToClear.Length == 0) continue;
            for (uint i = 0; i < tasksToClear.Length; i++) {
                tasksToClear[i].Release();
            }
            tasksToClear.RemoveRange(0, tasksToClear.Length);
        }
    }

    void CheckHotkey() {
        /*
        if (UI::IsKeyPressed(g_toggleLoadGhostHotkey)) { /* complaints about no matching signature to UI::IsKeyPressed(VirtualHotkey&) * /
            LoadGhostFromDialog();
        }
        */
    }

    void LoadGhostFromDialog() {
        string filePath = OpenGhostFileDialog();
        if (filePath != "") {
            LoadGhost(filePath);
        }
    }

    string OpenGhostFileDialog() {
        _UI::OpenFileDialogWindow(IO::FromAppFolder("UserData/Game/Ghosts/"));
    }

    void LoadGhost(const string &in filePath) {
        if (filePath.ToLower().EndsWith(".gbx")) {
            LoadGhostFromUrl("http://127.0.0.1:29907/get_ghost/" + GetFileName(filePath));
        } else {
            NotifyError("Unsupported file type.");
        }
    }

    string GetFileName(const string &in filePath) {
        array<string> parts = filePath.Split("/");
        return parts[parts.Length - 1];
    }

    void LoadGhostFromUrl(const string &in url) {
        auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
        auto dfm = ps.DataFileMgr;
        auto gm = ps.GhostMgr;
        auto task = dfm.Ghost_Download(GetFileName(url), url);
        WaitAndClearTaskLater(task, dfm);
        if (task.HasFailed || !task.HasSucceeded) {
            log('Ghost_Download failed: ' + task.ErrorCode + ", " + task.ErrorType + ", " + task.ErrorDescription);
            return;
        }
        auto instId = gm.Ghost_Add(task.Ghost, S_UseGhostLayer);
        print('Instance ID: ' + instId.GetName() + " / " + Text::Format("%08x", instId.Value));
    }
}
