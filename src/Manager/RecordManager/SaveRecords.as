namespace RecordManager {
    namespace Save {

        void SaveAndLoadRecord() {
            SaveRecord();
            LoadRecord::LoadRecordFromPath();
        }
















        void SaveRecord() {
            if (selectedRecordID.Value == MwId().Value) { NotifyError("No ghost selected to save."); return; }

            CGameGhostScript@ ghost = GetTrackedGhostById(selectedRecordID);
            if (ghost is null) { NotifyError("Selected ghost not found."); return; }

            string timeStamp = Time::FormatString("%Y-%m-%d-%H-%M-%S", Time::Stamp);
            string fileName = ghost.Id.Value + "_" + ghost.Nickname + "_" + ghost.Result.Time + "_" + timeStamp;
            fileName = fileName.Replace(" ", "-").Replace(":", "-");
            string tmpFilePath = Server::replayARLTmp + fileName + ".Replay.Gbx";

            string replayFilePath = Server::savedFilesDirectory;
            string jsonFilePath = Server::savedJsonDirectory + fileName + ".json";

            log("Saving ghost to file: " + replayFilePath, LogLevel::Info, 234, "SaveRecord");

            auto app = GetApp();
            if (app is null || app.Network is null || app.Network.ClientManiaAppPlayground is null) { NotifyError("App or network components not ready."); return; }
            auto rootMap = cast<CGameCtnChallenge@>(app.RootMap);
            if (rootMap is null) { NotifyError("RootMap is not a valid CGameCtnChallenge."); return; }

            CWebServicesTaskResult@ saveResult = app.Network.ClientManiaAppPlayground.DataFileMgr.Replay_Save(tmpFilePath, rootMap, ghost);
            if (saveResult.HasSucceeded && !saveResult.HasFailed) {
                log("Replay save successful", LogLevel::Info, 243, "SaveRecord");

                string _uuid = CreateRandomUuid();
                Json::Value json = Json::Object();
                json["content"] = Json::Object();
                json["content"]["ID"] = _uuid;
                json["content"]["FileName"] = fileName;
                json["content"]["FullFilePath"] = replayFilePath + fileName + ".Replay.Gbx";
                json["content"]["FromLocalFile"] = true;
                json["content"]["ReplayFilePath"] = replayFilePath;
                json["content"]["Nickname"] = ghost.Nickname;
                json["content"]["Trigram"] = ghost.Trigram;
                json["content"]["CountryPath"] = ghost.CountryPath;
                json["content"]["Time"] = ghost.Result.Time;
                json["content"]["StuntScore"] = ghost.Result.Score;
                json["content"]["MwId Value"] = ghost.Id.Value;

                _IO::File::WriteFile(jsonFilePath, Json::Write(json, true));

                string replayFileData = _IO::File::ReadFileToEnd(tmpFilePath);
                _IO::File::WriteFile(Server::savedFilesDirectory + fileName + ".Replay.Gbx", replayFileData);
                IO::Delete(tmpFilePath);

                NotifyInfo("Ghost saved successfully.");
            } else {
                log("Replay save failed: " + saveResult.ErrorDescription, LogLevel::Error, 268, "SaveRecord");
                NotifyError("Failed to save ghost replay.");
            }
        }

        string CreateRandomUuid() {
            string uuid = "";
            for (int i = 0; i < 32; i++) {
                uuid += tostring(Math::Rand(0, 9) % 10);
            }
            return uuid;
        }

        CGameGhostScript@ GetTrackedGhostById(MwId id) {
            for (uint i = 0; i < GhostTracker().trackedGhosts.Length; i++) {
                if (GhostTracker().trackedGhosts[i].Id.Value == id.Value) {
                    return GhostTracker().trackedGhosts[i];
                }
            }
            return null;
        }

        void SaveRecordByPath(const string &in overwritePath) {
            

        }
    }
}