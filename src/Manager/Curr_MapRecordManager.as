namespace CurrentMapRecords {
    namespace ValidationReplay {
        bool validationReplayCanBeLoaded = false;

        bool ValidationReplayCanBeLoadedForCurrentMap() {
            if (ValidationReplayExists()) { ExtractReplay(); }
            return true;
        }
        
        string GetValidationReplayFilePath() {
            return Server::currentMapRecordsValidationReplay + "Validation_" + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
        }

        bool ValidationReplayExists() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return false;

            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return false;

            CGameDataFileManagerScript@ dataFileMgr = playground.DataFileMgr;
            if (dataFileMgr is null) { /*log("DataFileMgr is null", LogLevel::Error, 22, "ValidationReplayExists");*/ return false; }

            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) { /*log("Author ghost is empty", LogLevel::Warn, 25, "ValidationReplayExists");*/ return false; }

            return true;
        }

        void ExtractReplay() {
            try {
                CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
                if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 33, "ExtractReplay"); }
                string outputFileName = Server::currentMapRecordsValidationReplay + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";

                CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
                if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 37, "ExtractReplay"); }

                CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, GetApp().RootMap, authorGhost);
                if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 40, "ExtractReplay"); }

                while (taskResult.IsProcessing) { yield(); }
                if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 43, "ExtractReplay"); }

                log("Replay extracted to: " + outputFileName, LogLevel::Info, 45, "ExtractReplay");
            } catch {
                log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 47, "ExtractReplay");
            }
        }

        void AddValidationReplay() {
            if (validationReplayCanBeLoaded) { ExtractReplay(); }
            ReplayLoader::LoadReplayFromPath(GetValidationReplayFilePath());
        }
    }

#if DEPENDENCY_CHAMPIONMEDALS
namespace ChampMedal {
    bool championMedalExists = false;
    uint currentMapChampionMedal = 0;
    string globalMapUid;
    string mapName;
    int timeDifference = 0;

    CGameCtnChallenge@ rootMap = null;

    string displaySavePath = "";
    uint displayTimeDifference = 0;

    bool championMedalHasExactMatch = false;
    bool ReqForCurrentMapFinished = false;

    void AddChampionMedal() {
        if (championMedalExists) {
            startnew(FetchSurroundingRecords);
        }
    }

    void OnMapLoad() {
        if (ChampionMedalExists()) {
            ResetState();
            championMedalExists = true;
            FetchMap();
            FetchChampionMedalTime();
        } else {
            championMedalExists = false;
        }
    }

    void ResetState() {
        championMedalExists = false;
        currentMapChampionMedal = 0;
        globalMapUid = "";
        mapName = "";
        timeDifference = 0;
        displaySavePath = "";
        displayTimeDifference = 0;
        championMedalHasExactMatch = false;
        ReqForCurrentMapFinished = false;
    }

    void FetchMap() {
        @rootMap = GetApp().RootMap;
        if (rootMap is null) { log("Root map is null", LogLevel::Warn, 104, "FetchMap"); return; }
        globalMapUid = rootMap.MapInfo.MapUid;
        mapName = rootMap.MapInfo.Name;
    }

    bool ChampionMedalExists() {
        int startTime = Time::Now;
        while (Time::Now - startTime < 500 || ChampionMedals::GetCMTime() == 0) { yield(); }
        log("" + ChampionMedals::GetCMTime(), LogLevel::Info, 112, "ChampionMedalExists");
        return ChampionMedals::GetCMTime() > 0;
    }

    void FetchChampionMedalTime() {
        if (championMedalExists) {
            currentMapChampionMedal = ChampionMedals::GetCMTime();
        }
    }

    void FetchSurroundingRecords() {
        if (!championMedalExists) return;

        string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + globalMapUid + "/surround/1/1?score=" + currentMapChampionMedal;
        auto req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) { yield(); }

        if (req.ResponseCode() != 200) { log("Failed to fetch surrounding records, response code: " + req.ResponseCode(), LogLevel::Error, 131, "FetchSurroundingRecords"); return; }

        Json::Value data = Json::Parse(req.String());
        if (data.GetType() == Json::Type::Null) { log("Failed to parse response for surrounding records.", LogLevel::Error, 134, "FetchSurroundingRecords"); return; }

        Json::Value tops = data["tops"];
        if (tops.GetType() != Json::Type::Array || tops.Length == 0) { log("Invalid tops data in response.", LogLevel::Error, 137, "FetchSurroundingRecords"); return; }

        Json::Value top = tops[0]["top"];
        if (top.GetType() != Json::Type::Array || top.Length == 0) { log("Invalid top data in response.", LogLevel::Error, 140, "FetchSurroundingRecords"); return; }

        uint closestScore = 0;
        int smallestDifference = int(0x7FFFFFFF);
        string closestAccountId;
        int closestPosition = -1;
        bool exactMatchFound = false;

        for (uint i = 0; i < top.Length; i++) {
            if (i == top.Length / 2) continue;

            uint score = top[i]["score"];
            string accountId = top[i]["accountId"];
            int position = top[i]["position"];
            int difference = int(currentMapChampionMedal) - int(score);

            log("Found surrounding record: score = " + score + ", accountId = " + accountId + ", position = " + position + ", difference = " + difference, LogLevel::Info, 156, "FetchSurroundingRecords");

            if (difference == 0) {
                closestScore = score;
                closestAccountId = accountId;
                closestPosition = position;
                smallestDifference = difference;
                exactMatchFound = true;
                break;
            } else if (difference > 0 && difference < smallestDifference) {
                closestScore = score;
                closestAccountId = accountId;
                closestPosition = position;
                smallestDifference = difference;
            }
        }

        if (closestAccountId != "") {
            timeDifference = smallestDifference;
            championMedalHasExactMatch = exactMatchFound;

            log("Closest record found: score = " + closestScore + ", accountId = " + closestAccountId + ", position = " + closestPosition + ", difference = " + timeDifference, LogLevel::Info, 177, "FetchSurroundingRecords");
            LoadRecordFromArbitraryMap::LoadSelectedRecord(globalMapUid, tostring(closestPosition - 1), closestAccountId);
        }

        ReqForCurrentMapFinished = true;
    }


}
#endif








/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    namespace GPS {
        string savePathBase = "";
        CGameCtnChallenge@ rootMap = null;
        array<GhostData@> ghosts;
        string finalSavePath = "";
        uint64 CTmRaceResult_VTable_Ptr = 0;
        int selectedGhostIndex = -1;

        bool gpsReplayCanBeLoaded = false;

        void LoadReplay() {
            if (selectedGhostIndex >= 0 && selectedGhostIndex < ghosts.Length) {
                ReplayLoader::LoadReplayFromPath(ghosts[selectedGhostIndex].savePath);
            }
        }

        void OnMapLoad() {

            FetchMap();
            
            gpsReplayCanBeLoaded = GPSReplayCanBeLoadedForCurrentMap();
            if (!gpsReplayCanBeLoaded) { return; }

            FetchPath();
            FetchVTablePtr();
            FetchGhosts();
            ConvertGhosts();
            SaveReplays();
        }

        bool GPSReplayCanBeLoadedForCurrentMap() {
            if (rootMap is null || rootMap.ClipGroupInGame is null) {
                log("rootMap or ClipGroupInGame is null", LogLevel::Error, 253, "GPSReplayCanBeLoadedForCurrentMap");
                return false;
            }

            for (uint i = 0; i < rootMap.ClipGroupInGame.Clips.Length; i++) {
                auto clip = rootMap.ClipGroupInGame.Clips[i];
                if (clip is null) continue;
                for (uint j = 0; j < clip.Tracks.Length; j++) {
                    auto track = clip.Tracks[j];
                    if (track is null) continue;
                    if (track.Name.StartsWith("Ghost:")) {
                        return true;
                    }
                }
            }
            return false;
        }

        void FetchPath() {
            savePathBase = Server::currentMapRecordsGPS + Text::StripFormatCodes(GetApp().RootMap.MapName) + "_" + GetApp().RootMap.MapInfo.MapUid + "/";
        }

        void FetchMap() {
            @rootMap = GetApp().RootMap;
        }

        void FetchVTablePtr() {
            string ghostFilePath = IO::FromUserGameFolder("Replays/ArbitraryRecordLoader/Dummy/CTmRaceResult_VTable_Ptr.Replay.Gbx");

            while (rootMap is null) { yield(); } // Change to something that waits untill the player is loaded.
            sleep(1000); // Change to something that waits untill the player is loaded.

            auto ghostMgr = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript).GhostMgr;
            if (ghostMgr is null) { log("ghostMgr is null", LogLevel::Error, 286, "FetchVTablePtr"); return; }

            auto dfm = cast<CGameDataFileManagerScript>(GetApp().Network.ClientManiaAppPlayground.DataFileMgr);

            ReplayLoader::LoadReplayFromPath(ghostFilePath);

            array<CGameGhostScript@> ghost = GetGhost(dfm);
            if (ghost is null) { log("Failed to retrieve the ghost by ID", LogLevel::Error, 293, "FetchVTablePtr"); return; }

            uint64 pointer = Dev::GetOffsetUint64(ghost[0].Result, 0x0);
            log("Hexadecimal pointer: " + Text::FormatPointer(pointer), LogLevel::Info, 296, "FetchVTablePtr");

            CTmRaceResult_VTable_Ptr = pointer;
        }

        array<CGameGhostScript@> GetGhost(CGameDataFileManagerScript@ dfm) {
            array<CGameGhostScript@> ghosts;
            for (uint i = 0; i < dfm.Ghosts.Length; i++) {
                if (dfm.Ghosts[i].Nickname == "cfa844b7-6b53-4663-ac0d-9bdd3ad1af22") {
                    ghosts.InsertLast(dfm.Ghosts[i]);
                }
            }
            return ghosts;
        }

        void FetchGhosts() {
            for (uint i = 0; i < rootMap.ClipGroupInGame.Clips.Length; i++) {
                auto clip = rootMap.ClipGroupInGame.Clips[i];
                for (uint j = 0; j < clip.Tracks.Length; j++) {
                    auto track = clip.Tracks[j];
                    if (track.Name.StartsWith("Ghost:")) {
                        for (uint k = 0; k < track.Blocks.Length; k++) {
                            auto block = cast<CGameCtnMediaBlockEntity>(track.Blocks[k]);
                            if (block !is null) {
                                auto recordData = cast<CPlugEntRecordData>(Dev::GetOffsetNod(block, 0x58));
                                if (recordData !is null) {
                                    auto newGhost = CGameCtnGhost();
                                    Dev::SetOffset(newGhost, 0x2e0, recordData);
                                    recordData.MwAddRef();
                                    string ghostName = track.Name.SubStr(6);  // Remove "ghost:" prefix
                                    string savePath = savePathBase + ghostName + "_" + Text::Format("%d", i) + ".Replay.Gbx";

                                    if (!IO::FolderExists(_IO::File::GetFilePathWithoutFileName(savePath))) {
                                        IO::CreateFolder(_IO::File::GetFilePathWithoutFileName(savePath), true);
                                    }

                                    ghosts.InsertLast(GhostData(ghostName, savePath, newGhost));
                                }
                            }
                        }
                    }
                }
            }
        }

        void ConvertGhosts() {
            for (uint i = 0; i < ghosts.Length; i++) {
                if (ghosts[i] is null) {
                    log("Ghost at index " + i + " is null", LogLevel::Error, 344, "ConvertGhosts");
                    continue;
                }
                ghosts[i].ConvertToScript(CTmRaceResult_VTable_Ptr);
            }
        }

        void SaveReplays() {
            for (uint i = 0; i < ghosts.Length; i++) {
                if (ghosts[i] is null) {
                    log("Ghost at index " + i + " is null", LogLevel::Error, 354, "SaveReplays");
                    continue;
                }
                ghosts[i].Save(rootMap);
            }
        }
    }

    class GhostData {
        int selcetedGhostIndex = -1;

        string name;
        string savePath;
        CGameCtnGhost@ ghost;
        CGameGhostScript@ ghostScript;

        GhostData(const string &in name, const string &in savePath, CGameCtnGhost@ ghost) {
            this.name = name;
            this.savePath = savePath;
            @this.ghost = ghost;
        }

        void ConvertToScript(uint64 CTmRaceResult_VTable_Ptr) {
            if (ghost is null) {
                log("Ghost is null in ConvertToScript", LogLevel::Error, 378, "ConvertToScript");
                return;
            }

            ghost.MwAddRef();
            @ghostScript = CGameGhostScript();
            MwId ghostId = MwId();
            Dev::SetOffset(ghostScript, 0x18, ghostId.Value);
            Dev::SetOffset(ghostScript, 0x20, ghost);
            uint64 ghostPtr = Dev::GetOffsetUint64(ghostScript, 0x20);

            auto @tmRaceResultNodPre = CGameGhostScript();
            Dev::SetOffset(tmRaceResultNodPre, 0x0, CTmRaceResult_VTable_Ptr);
            trace('force casting');
            auto tmRaceResultNod = Dev::ForceCast<CTmRaceResultNod@>(tmRaceResultNodPre).Get();
            trace('done force casting');
            @tmRaceResultNodPre = null;
            Dev::SetOffset(tmRaceResultNod, 0x18, ghostPtr + 0x28);
            tmRaceResultNod.MwAddRef();

            Dev::SetOffset(ghostScript, 0x28, tmRaceResultNod);
        }


        void Save(CGameCtnChallenge@ rootMap) {
            if (ghostScript is null) {
                log("GhostScript is null in Save for ghost " + name, LogLevel::Error, 404, "Save");
                return;
            }

            CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
            CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(savePath, rootMap, ghostScript);
            if (taskResult is null) {
                log("Replay task returned null for ghost " + name, LogLevel::Error, 411, "Save");
            }
        }
    }
}

