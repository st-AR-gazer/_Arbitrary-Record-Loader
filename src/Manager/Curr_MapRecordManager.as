namespace CurrentMapRecords {

    namespace ValidationReplay {

        void AddValidationReplay() {
            if (ValidationReplayExists()) {
                ReplayLoader::LoadReplayFromPath(GetValidationReplayFilePathForCurrentMap());
            }
        }

        bool ValidationReplayExists() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return false;
            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return false;
            CGameDataFileManagerScript@ dataFileMgr = playground.DataFileMgr;
            if (dataFileMgr is null) { /*log("DataFileMgr is null", LogLevel::Error, 17, "ValidationReplayExists");*/ return false; }
            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) { /*log("Author ghost is empty", LogLevel::Warn, 19, "ValidationReplayExists");*/ return false; }
            return true;
        }

        void OnMapLoad() {
            if (ValidationReplayExists()) {
                ExtractValidationReplay();
            }
        }

        void ExtractValidationReplay() {
            try {
                CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
                if (dataFileMgr is null) { log("DataFileMgr is null", LogLevel::Error, 32, "ExtractValidationReplay"); }
                string outputFileName = Server::currentMapRecordsValidationReplay + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
                CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
                if (authorGhost is null) { log("Author ghost is empty", LogLevel::Warn, 35, "ExtractValidationReplay"); }
                CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(outputFileName, GetApp().RootMap, authorGhost);
                if (taskResult is null) { log("Replay task returned null", LogLevel::Error, 37, "ExtractValidationReplay"); }
                while (taskResult.IsProcessing) { yield(); }
                if (!taskResult.HasSucceeded) { log("Error while saving replay " + taskResult.ErrorDescription, LogLevel::Error, 39, "ExtractValidationReplay"); }
                log("Replay extracted to: " + outputFileName, LogLevel::Info, 40, "ExtractValidationReplay");
            } catch {
                log("Error occurred when trying to extract replay: " + getExceptionInfo(), LogLevel::Info, 42, "ExtractValidationReplay");
            }
        }

        int GetValidationReplayTime() {
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (app is null) return -1;
            CGamePlaygroundScript@ playground = cast<CGamePlaygroundScript>(app.PlaygroundScript);
            if (playground is null) return -1;
            CGameDataFileManagerScript@ dataFileMgr = playground.DataFileMgr;
            if (dataFileMgr is null) return -1;
            CGameGhostScript@ authorGhost = dataFileMgr.Map_GetAuthorGhost(GetApp().RootMap);
            if (authorGhost is null) return -1;
            return authorGhost.Result.Time;
        }

        string GetValidationReplayFilePathForCurrentMap() {
            if (GetApp().RootMap is null) { log("RootMap is null, no replay can be loaded...", LogLevel::Info, 59, "GetValidationReplayFilePathForCurrentMap"); return ""; }
            string path = Server::currentMapRecordsValidationReplay + "Validation_" + Text::StripFormatCodes(GetApp().RootMap.MapName) + ".Replay.Gbx";
            if (!IO::FileExists(path)) { log("Validation replay does not exist at path: " + path + " | This is likely due to the validation replay not yet being extracted.", LogLevel::Info, 61, "GetValidationReplayFilePathForCurrentMap"); return ""; }
            return path;
        }
    }

    class Medal {
        bool medalExists = false;
        uint currentMapMedalTime = 0;
        int timeDifference = 0;

        string displaySavePath = "";
        uint displayTimeDifference = 0;

        bool medalHasExactMatch = false;
        bool reqForCurrentMapFinished = false;

        CGameCtnChallenge@ rootMap = null;

        void AddMedal() {
            if (medalExists) {
                startnew(CoroutineFunc(FetchSurroundingRecords));
            }
        }

        void OnMapLoad() {
            if (MedalExists()) {
                ResetState();
                medalExists = true;
                FetchMedalTime();
            } else {
                medalExists = false;
            }
            return;
        }

        void ResetState() {
            medalExists = false;
            currentMapMedalTime = 0;
            timeDifference = 0;
            displaySavePath = "";
            displayTimeDifference = 0;
            medalHasExactMatch = false;
            reqForCurrentMapFinished = false;
        }

        bool MedalExists() {
            int startTime = Time::Now;
            while (Time::Now - startTime < 2000 || GetMedalTime() == 0) { yield(); }
            log("Medal time is: " + GetMedalTime(), LogLevel::Info, 109, "MedalExists");
            return GetMedalTime() > 0;
        }

        void FetchMedalTime() {
            if (medalExists) {
                currentMapMedalTime = GetMedalTime();
            }
        }

        void FetchSurroundingRecords() {
            if (!medalExists) return;

            string url = "https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/Personal_Best/map/" + get_CurrentMapUID() + "/surround/1/1?score=" + currentMapMedalTime;
            auto req = NadeoServices::Get("NadeoLiveServices", url);
            req.Start();

            while (!req.Finished()) { yield(); }

            if (req.ResponseCode() != 200) {
                log("Failed to fetch surrounding records, response code: " + req.ResponseCode(), LogLevel::Error, 129, "FetchSurroundingRecords");
                return;
            }

            Json::Value data = Json::Parse(req.String());
            if (data.GetType() == Json::Type::Null) {
                log("Failed to parse response for surrounding records.", LogLevel::Error, 135, "FetchSurroundingRecords");
                return;
            }

            Json::Value tops = data["tops"];
            if (tops.GetType() != Json::Type::Array || tops.Length == 0) {
                log("Invalid tops data in response.", LogLevel::Error, 141, "FetchSurroundingRecords");
                return;
            }

            Json::Value top = tops[0]["top"];
            if (top.GetType() != Json::Type::Array || top.Length == 0) {
                log("Invalid top data in response.", LogLevel::Error, 147, "FetchSurroundingRecords");
                return;
            }

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
                int difference = int(currentMapMedalTime) - int(score);

                log("Found surrounding record: score = " + score + ", accountId = " + accountId + ", position = " + position + ", difference = " + difference, LogLevel::Info, 165, "FetchSurroundingRecords");

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
                medalHasExactMatch = exactMatchFound;

                log("Closest record found: score = " + closestScore + ", accountId = " + closestAccountId + ", position = " + closestPosition + ", difference = " + timeDifference, LogLevel::Info, 186, "FetchSurroundingRecords");
                LoadRecordFromArbitraryMap::LoadSelectedRecord(get_CurrentMapUID(), tostring(closestPosition - 1), "Medal", closestAccountId);
            }

            reqForCurrentMapFinished = true;
        }

        uint GetMedalTime() { return 0; }
    }

    class ChampionMedal : Medal {
        uint GetMedalTime() override {
            int x = -1;
#if DEPENDENCY_CHAMPIONMEDALS
            x = ChampionMedals::GetCMTime();
#endif
            return x;
        }
    }

    class WarriorMedal : Medal {
        uint GetMedalTime() override {
            int x = -1;
#if DEPENDENCY_WARRIORMEDALS
            x = WarriorMedals::GetWMTime();
#endif
            return x;
        }
    }

    class SBVilleMedal : Medal {
        uint GetMedalTime() override {
            int x = -1;
#if DEPENDENCY_SBVILLECAMPAIGNCHALLENGES
            x = SBVilleCampaignChallenges::getChallengeTime();
#endif
            return x;
        }
    }

#if DEPENDENCY_CHAMPIONMEDALS
    namespace ChampMedal {
        ChampionMedal medal;
    }
#endif

#if DEPENDENCY_WARRIORMEDALS
    namespace WarriorMedal {
        WarriorMedal medal;
    }
#endif

#if DEPENDENCY_SBVILLECAMPAIGNCHALLENGES
    namespace SBVille {
        SBVilleMedal medal;
    }
#endif

    /* Pain Pain Go Away 
        // GPS extraction/loading is something I've canned for now, due to lack of knowledge on my part...

        // namespace GPS {
        //     string savePathBase = "";
        //     CGameCtnChallenge@ rootMap = null;
        //     array<GhostData@> ghosts;
        //     string finalSavePath = "";
        //     uint64 CTmRaceResult_VTable_Ptr = 0x0;
        //     int selectedGhostIndex = -1;

        //     bool gpsReplayCanBeLoaded = false;

        //     void LoadReplay() {
        //         if (selectedGhostIndex >= 0 && selectedGhostIndex < ghosts.Length) {
        //             ReplayLoader::LoadReplayFromPath(ghosts[selectedGhostIndex].savePath);
        //         }
        //     }

        //     void OnMapLoad() {
        //         FetchMap();
                
        //         gpsReplayCanBeLoaded = GPSReplayCanBeLoadedForCurrentMap();
        //         if (!gpsReplayCanBeLoaded) { return; }

        //         FetchPath();
        //         FetchVTablePtr();
        //         FetchGhosts();
        //         ConvertGhosts();
        //         SaveReplays();
        //     }

        //     bool GPSReplayCanBeLoadedForCurrentMap() {
        //         if (rootMap is null || rootMap.ClipGroupInGame is null) {
        //             log("rootMap or ClipGroupInGame is null", LogLevel::Error, 278, "GPSReplayCanBeLoadedForCurrentMap");
        //             return false;
        //         }

        //         for (uint i = 0; i < rootMap.ClipGroupInGame.Clips.Length; i++) {
        //             auto clip = rootMap.ClipGroupInGame.Clips[i];
        //             if (clip is null) continue;
        //             for (uint j = 0; j < clip.Tracks.Length; j++) {
        //                 auto track = clip.Tracks[j];
        //                 if (track is null) continue;
        //                 if (track.Name.StartsWith("Ghost:")) {
        //                     return true;
        //                 }
        //             }
        //         }
        //         return false;
        //     }

        //     void FetchPath() {
        //         savePathBase = Server::currentMapRecordsGPS + Text::StripFormatCodes(GetApp().RootMap.MapName) + "_" + GetApp().RootMap.MapInfo.MapUid + "/";
        //     }

        //     void FetchMap() {
        //         @rootMap = GetApp().RootMap;
        //     }

        //     void FetchVTablePtr() {
        //         string ghostFilePath = IO::FromUserGameFolder("Replays/ArbitraryRecordLoader/Dummy/CTmRaceResult_VTable_Ptr.Replay.Gbx");

        //         while (rootMap is null) { yield(); }    // Change to something that waits until the player is loaded.
        //         sleep(1000);                            // Change to something that waits until the player is loaded.

        //         auto dfm = cast<CGameDataFileManagerScript>(GetApp().Network.ClientManiaAppPlayground.DataFileMgr);
        //         if (dfm is null) { log("DataFileMgr is null", LogLevel::Error, 311, "FetchVTablePtr"); return; }

        //         auto task = dfm.Replay_Load(ghostFilePath);
        //         while (task.IsProcessing) { yield(); }

        //         if (task.HasFailed || !task.HasSucceeded) {
        //             log("Failed to load replay file!", LogLevel::Error, 317, "FetchVTablePtr");
        //             log(task.ErrorCode, LogLevel::Error, 318, "FetchVTablePtr");
        //             log(task.ErrorDescription, LogLevel::Error, 319, "FetchVTablePtr");
        //             log(task.ErrorType, LogLevel::Error, 320, "FetchVTablePtr");
        //             log(tostring(task.Ghosts.Length), LogLevel::Error, 321, "FetchVTablePtr");
        //             return;
        //         }

        //         if (task.Ghosts.Length == 0) { log("No ghosts found in the replay file!", LogLevel::Warn, 325, "FetchVTablePtr"); return; }

        //         auto ghost = task.Ghosts[0];
        //         if (ghost is null) { log("Failed to retrieve the ghost from the replay file", LogLevel::Error, 328, "FetchVTablePtr"); return; }

        //         uint64 pointer = Dev::GetOffsetUint64(ghost.Result, 0x0);
        //         log("Hexadecimal pointer: " + Text::FormatPointer(pointer), LogLevel::Info, 331, "FetchVTablePtr");

        //         CTmRaceResult_VTable_Ptr = pointer;
        //     }

        //     array<CGameGhostScript@> GetGhost(CGameDataFileManagerScript@ dfm) {
        //         array<CGameGhostScript@> ghosts;
        //         for (uint i = 0; i < dfm.Ghosts.Length; i++) {
        //             if (dfm.Ghosts[i].Nickname == "cfa844b7-6b53-4663-ac0d-9bdd3ad1af22") {
        //                 ghosts.InsertLast(dfm.Ghosts[i]);
        //             }
        //         }
        //         return ghosts;
        //     }

        //     void FetchGhosts() {
        //         for (uint i = 0; i < rootMap.ClipGroupInGame.Clips.Length; i++) {
        //             auto clip = rootMap.ClipGroupInGame.Clips[i];
        //             for (uint j = 0; j < clip.Tracks.Length; j++) {
        //                 auto track = clip.Tracks[j];
        //                 if (track.Name.StartsWith("Ghost:")) {
        //                     for (uint k = 0; k < track.Blocks.Length; k++) {
        //                         auto block = cast<CGameCtnMediaBlockEntity>(track.Blocks[k]);
        //                         if (block !is null) {
        //                             auto recordData = cast<CPlugEntRecordData>(Dev::GetOffsetNod(block, 0x58));
        //                             if (recordData !is null) {
        //                                 auto newGhost = CGameCtnGhost();
        //                                 Dev::SetOffset(newGhost, 0x2e0, recordData);
        //                                 recordData.MwAddRef();
                                        
        //                                 newGhost.ModelIdentName.SetName("CarSport");
        //                                 newGhost.ModelIdentAuthor.SetName("Nadeo");
        //                                 newGhost.Validate_ChallengeUid.SetName(rootMap.EdChallengeId);

        //                                 auto ptr1 = GetSomeMemory();
        //                                 auto ptr2 = GetSomeMemory();
        //                                 Dev::SetOffset(newGhost, 0x2e8, ptr1);
        //                                 Dev::SetOffset(newGhost, 0x2F0, uint(1));
        //                                 Dev::SetOffset(newGhost, 0x2F4, uint(1));
        //                                 Dev::Write(ptr1, ptr2);
        //                                 Dev::Write(ptr2, uint(2));
        //                                 Dev::Write(ptr2 + 4, uint(0x02000156));
        //                                 Dev::Write(ptr2 + 8, uint(0));
        //                                 Dev::Write(ptr2 + 0xC, uint(45450));
        //                                 Dev::Write(ptr2 + 0x10, uint64(0));
        //                                 Dev::Write(ptr2 + 0x18, uint64(0));
        //                                 Dev::Write(ptr2 + 0x20, uint(0xD100000));
        //                                 Dev::Write(ptr2 + 0x24, uint(1));

        //                                 string ghostName = track.Name.SubStr(6);  // Remove "ghost:" prefix
        //                                 string savePath = savePathBase + ghostName + "_" + Text::Format("%d", i) + ".Replay.Gbx";

        //                                 if (!IO::FolderExists(_IO::File::GetFilePathWithoutFileName(savePath))) {
        //                                     IO::CreateFolder(_IO::File::GetFilePathWithoutFileName(savePath), true);
        //                                 }

        //                                 print(ghostName + " _ " + newGhost.GhostNickname);

        //                                 ghosts.InsertLast(GhostData(ghostName, savePath, newGhost));
        //                             }
        //                         }
        //                     }
        //                 }
        //             }
        //         }
        //     }

        //     uint64 GetSomeMemory() {
        //         CGameGhostScript@ tmp1 = CGameGhostScript();
        //         Dev::SetOffset(tmp1, 0x8, tmp1);
        //         auto ptr = Dev::GetOffsetUint64(tmp1, 0x8);
        //         for (uint i = 0; i < 0x58; i += 8) {
        //             Dev::SetOffset(tmp1, i, uint64(0));
        //         }
        //         return ptr;
        //     }


        //     void ConvertGhosts() {
        //         for (uint i = 0; i < ghosts.Length; i++) {
        //             if (ghosts[i] is null) { log("Ghost at index " + i + " is null", LogLevel::Error, 411, "ConvertGhosts"); continue; }
        //             ghosts[i].ConvertToScript(CTmRaceResult_VTable_Ptr, ghosts[i].ghost);
        //         }
        //     }

        //     void SaveReplays() {
        //         for (uint i = 0; i < ghosts.Length; i++) {
        //             if (ghosts[i] is null) {
        //                 log("Ghost at index " + i + " is null", LogLevel::Error, 419, "SaveReplays");
        //                 continue;
        //             }
        //             ghosts[i].Save(rootMap);
        //         }
        //     }
        // }

        // class GhostData {
        //     int selcetedGhostIndex = -1;

        //     string name;
        //     string savePath;
        //     CGameCtnGhost@ ghost;
        //     CGameGhostScript@ ghostScript;

        //     GhostData(const string &in name, const string &in savePath, CGameCtnGhost@ ghost) {
        //         this.name = name;
        //         this.savePath = savePath;
        //         @this.ghost = ghost;
        //     }

        //     void ConvertToScript(uint64 CTmRaceResult_VTable_Ptr, CGameCtnGhost@ ghost) {
        //         if (ghost is null) { log("Ghost is null in ConvertToScript", LogLevel::Error, 442, "ConvertToScript"); return; }

        //         ghost.MwAddRef();

        //         @ghostScript = CGameGhostScript();
        //         MwId ghostId = MwId();
        //         Dev::SetOffset(ghostScript, 0x18, ghostId.Value);
        //         Dev::SetOffset(ghostScript, 0x20, ghost);
        //         uint64 ghostPtr = Dev::GetOffsetUint64(ghostScript, 0x20);

        //         CGameGhostScript@ tmRaceResultNodPre = CGameGhostScript();
        //         Dev::SetOffset(tmRaceResultNodPre, 0x0, CTmRaceResult_VTable_Ptr);
        //         CTmRaceResultNod@ tmRaceResultNod = Dev::ForceCast<CTmRaceResultNod@>(tmRaceResultNodPre).Get();
        //         @tmRaceResultNodPre = null;
        //         Dev::SetOffset(tmRaceResultNod, 0x18, ghostPtr + 0x28);
        //         tmRaceResultNod.MwAddRef();

        //         Dev::SetOffset(ghostScript, 0x28, tmRaceResultNod);
        //     }

        //     void Save(CGameCtnChallenge@ rootMap) {
        //         if (ghostScript is null) { log("GhostScript is null in Save for ghost " + name, LogLevel::Error, 463, "Save"); return; }

        //         print(savePath);
        //         print(rootMap.MapName);
        //         print(ghostScript.Nickname);

        //         CGameDataFileManagerScript@ dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
        //         CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(savePath, rootMap, ghostScript);
        //         if (taskResult is null) {
        //             log("Replay task returned null for ghost " + name, LogLevel::Error, 472, "Save");
        //         }
        //     }
        // }
    */
}