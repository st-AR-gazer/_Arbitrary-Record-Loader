bool permissionsOkay = false;
void PermsCheck() {
    permissionsOkay = Permissions::ViewRecords() && Permissions::PlayRecords();
    if (!permissionsOkay) {
        NotifyWarn("Your edition of the game does not support playing against record ghosts.\n\nThis plugin won't work, sorry :(.");
        log("Permission check failed", LogLevel::Warn, 6, "PermsCheck");
        permissionsOkay = false;
    }
    return;
}