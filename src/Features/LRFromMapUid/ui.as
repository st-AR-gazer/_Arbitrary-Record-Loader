// src/Features/LoadRecordFromMapUid/ui.as

namespace Features {
namespace LRFromMapIdentifier {
    string ghostPosition;
    string mapUID;

    void RT_LRFromMapUid() {

        UI::Separator();

        UI::Text("Build a request: ");
        UI::Separator();

        if (UI::Button("Set MapUID to current map")) {
            mapUID = get_CurrentMapUID();
        }
        UI::SameLine();
        if (UI::Button("Set Ghost Position to top 1")) {
            ghostPosition = "0";
        }

        mapUID = UI::InputText("Map UID", mapUID);
        ghostPosition = UI::InputText("Ghost Position", ghostPosition);

        if (UI::Button("Fetch Ghost")) {

            loadRecord.LoadRecordFromMapUid(mapUID, ghostPosition, "AnyMap");
        }

        UI::Separator();
    }
}
}