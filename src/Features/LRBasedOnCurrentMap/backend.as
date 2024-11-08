namespace Features {
namespace LRBasedOnCurrentMap {
    string FromMsToFormat(uint ms) {
        uint minutes = ms / 60000;
        uint seconds = (ms % 60000) / 1000;
        uint milliseconds = ms % 1000;
        return pad(minutes, 2) + ":" + pad(seconds, 2) + "." + pad(milliseconds, 3);
    }

    string pad(uint value, int length) {
        string result = "" + value;
        while (result.Length < length) {
            result = "0" + result;
        }
        return result;
    }
}
}