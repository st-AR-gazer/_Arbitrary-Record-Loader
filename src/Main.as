void Main() {
    PermsCheck();
    if (!permissionsOkay) return;

    FetchManifest();

    @api = NadeoApi();
    MLHook::RequireVersionApi('0.3.1');
}