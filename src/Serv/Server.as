namespace Server {
    const string serverUrl = "http://127.0.0.1:29918/get_ghost/";
    const string serverDirectory = IO::FromStorageFolder("AutoMove/");

    void StartHttpServer() {
        Net::Socket serverSocket;
        if (!serverSocket.Listen("127.0.0.1", 29918)) {
            error("Failed to start server on port 29918.");
            return;
        }

        while (true) {
            auto clientSocket = serverSocket.Accept();
            if (clientSocket !is null) {
                startnew(OnHttpRequest, clientSocket);
            }
            yield();
        }
    }

    void OnHttpRequest(ref@ rClientSocket) {
        Net::Socket@ clientSocket = cast<Net::Socket@>(rClientSocket);

        string request;
        if (!clientSocket.ReadLine(request)) {
            log("Failed to read request from client.");
            clientSocket.Close();
            return;
        }

        log("Received request: " + request);

        if (request.StartsWith("GET /get_ghost/")) {
            string filePath = serverDirectory + request.SubStr(15).Split(" ")[0];
            log("Serving file: " + filePath);
            if (IO::FileExists(filePath)) {
                log("File exists: " + filePath);
                string response = "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\n\r\n";
                clientSocket.Write(response);
                clientSocket.Write(_IO::ReadFileToEnd(filePath));
                log("File served: " + filePath);
            } else {
                log("File not found: " + filePath);
                string response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nFile not found";
                clientSocket.Write(response);
            }
        } else {
            log("Invalid request: " + request);
            string response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nNot found";
            clientSocket.Write(response);
        }
        clientSocket.Close();
    }

    void LogServerFiles() {
        log("Listing all files in server directory: " + serverDirectory, LogLevel::Info, 58);
        array<string> files = IO::IndexFolder(serverDirectory, false);
        for (uint i = 0; i < files.Length; i++) {
            log("File: " + files[i], LogLevel::Info, 61);
        }
    }
}
