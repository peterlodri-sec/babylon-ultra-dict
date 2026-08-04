import BabilonBotLib
import Foundation

// BabilonBot CLI — headless dog→human quant translation daemon
// v1.0 · macOS 14+ · iOS 18+ · OM MANI PADME HUNG

@main
struct BabilonBotMain {
    static func main() {
        let args = CommandLine.arguments
        let cmd = args.count > 1 ? args[1] : "run"
        let rest = Array(args.dropFirst(2))

        switch cmd {
        case "run":    runCmd(rest)
        case "export": exportCmd(rest)
        case "auth":   authCmd(rest)
        case "serve":  serveCmd(rest)
        case "status": statusCmd()
        default:       usage()
        }
    }
}

// ── usage ──

func usage() {
    print("""
    BABILON Bot v1.0 · dog→human quant translation daemon

      babilonbot run     Continuous translation (default)
      babilonbot export  Generate + export JSONL training data
      babilonbot auth    Authenticate dog via quant ternary
      babilonbot serve   HTTP API on :8500
      babilonbot status  Print configuration

    Options:
      --dog, -d NAME     Dog to auth (default: Marley)
      --verbose, -v      Live output
      --output, -o PATH  Log file path
      --count, -c N      Export count (default: 100)
    """)
}

// ── run ──

func runCmd(_ args: [String]) {
    var dog = "Marley", verbose = false, output: String? = nil, i = 0
    while i < args.count {
        switch args[i] {
        case "--dog", "-d": i += 1; dog = i < args.count ? args[i] : dog
        case "--verbose", "-v": verbose = true
        case "--output", "-o": i += 1; output = i < args.count ? args[i] : nil
        default: break
        }; i += 1
    }

    let engine = BabilonBotEngine()
    engine.currentDog = QuantDogProfile.registry.first(where: { $0.name.lowercased() == dog.lowercased() })
    print("🐕 BabilonBot · dog: \(dog) · OM MANI PADME HUNG\n")

    engine.onTranslation = { r in
        let line = "[\(r.soundType)] \(r.hungarian) | q=\(String(format: "%.2f", r.confidence)) | \(r.dogName)"
        if verbose { print("  \(line)"); fflush(stdout) }
        if let path = output {
            logRecord(r, to: path)
        }
    }
    engine.start()

    signal(SIGINT, SIG_IGN)
    let src = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    src.setEventHandler { print("\n≡ stopped · \(engine.records.count) translations"); exit(0) }
    src.resume()
    dispatchMain()
}

func logRecord(_ r: TranslationRecord, to path: String) {
    guard let data = try? JSONEncoder().encode(r) else { return }
    var line = data
    line.append(10) // newline
    if let h = FileHandle(forWritingAtPath: path) {
        h.seekToEndOfFile(); h.write(line); h.closeFile()
    } else {
        FileManager.default.createFile(atPath: path, contents: line)
    }
}

// ── export ──

func exportCmd(_ args: [String]) {
    var count = 100, output = "babilonbot_export.jsonl", i = 0
    while i < args.count {
        switch args[i] {
        case "--count", "-c": i += 1; count = Int(args[i]) ?? 100
        case "--output", "-o": i += 1; output = args[i]
        default: break
        }; i += 1
    }

    print("Exporting \(count) translations...")
    let engine = BabilonBotEngine()
    engine.onTranslation = { _ in
        if engine.records.count % 20 == 0 { print("  \(engine.records.count)/\(count)") }
    }
    engine.start()
    while engine.records.count < count { usleep(100_000) }

    let jsonl = engine.exportRecordsAsJSONL()
    try! jsonl.write(toFile: output, atomically: true, encoding: .utf8)
    print("✓ \(engine.records.count) records → \(output)\n")
}

// ── auth ──

func authCmd(_ args: [String]) {
    var dog = "Marley", i = 0
    while i < args.count {
        if args[i] == "--name" || args[i] == "-n" { i += 1; dog = i < args.count ? args[i] : dog }
        i += 1
    }
    if let d = QuantDogProfile.registry.first(where: { $0.name.lowercased() == dog.lowercased() }) {
        print("✓ \(d.name) · \(d.breed) · \(d.role)\n  [\(d.ternarity.map(String.init).joined(separator: ","))]\n")
    } else {
        print("✗ Unknown: \(dog)\n  Registry: \(QuantDogProfile.registry.map(\.name).joined(separator: ", "))\n")
    }
}

// ── serve ──

func serveCmd(_ args: [String]) {
    var port = 8500, i = 0
    while i < args.count {
        if args[i] == "--port" || args[i] == "-p" { i += 1; port = Int(args[i]) ?? 8500 }
        i += 1
    }

    let engine = BabilonBotEngine()
    engine.start()
    let server = BabilonHTTPServer(port: port, engine: engine)
    print("≡ BabilonBot HTTP · http://127.0.0.1:\(port)\n  GET /status /latest /export /dogs\n")
    server.start()
    dispatchMain()
}

func statusCmd() {
    print("""
    BabilonBot v1.0 · BABYLON-ultra-dict
      \(QuantDogProfile.registry.count) dogs: \(QuantDogProfile.registry.map(\.name).joined(separator: ", "))
      \(BabilonLexicon.count) lexicon entries
      PRNG: Xoshiro128Star** · OM MANI PADME HUNG

    """)
}

// ── Embedded HTTP server ──

final class BabilonHTTPServer: @unchecked Sendable {
    private let port: Int
    private let engine: BabilonBotEngine

    init(port: Int, engine: BabilonBotEngine) { self.port = port; self.engine = engine }

    func start() { DispatchQueue.global().async { self.run() } }

    private func run() {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return }
        var reuse: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        var addr = sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: UInt16(port).bigEndian, sin_addr: in_addr(s_addr: INADDR_ANY), sin_zero: (0,0,0,0,0,0,0,0))
        withUnsafePointer(to: &addr) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) } }
        listen(fd, 10)
        while true {
            let client = accept(fd, nil, nil)
            guard client >= 0 else { continue }
            DispatchQueue.global().async { self.handle(client) }
        }
    }

    private func handle(_ client: Int32) {
        defer { close(client) }
        var buf = [UInt8](repeating: 0, count: 4096)
        let n = recv(client, &buf, buf.count, 0)
        guard n > 0, let req = String(bytes: buf[0..<n], encoding: .utf8) else { return }
        let path = req.components(separatedBy: "\r\n").first?.components(separatedBy: " ").dropFirst().first ?? "/"

        let body: String
        switch path {
        case "/status":
            body = #"{"dog":"\#(engine.currentDog?.name ?? "Marley")","translations":\#(engine.records.count),"running":true}"#
        case "/latest":
            body = (engine.records.last.flatMap { try? String(data: JSONEncoder().encode($0), encoding: .utf8) }) ?? "{}"
        case "/export":
            body = engine.exportRecordsAsJSONL()
        case "/dogs":
            body = "[\(QuantDogProfile.registry.map { #"{"name":"\#($0.name)","breed":"\#($0.breed)","role":"\#($0.role)"}"# }.joined(separator: ","))]"
        default:
            body = #"{"endpoints":["/status","/latest","/export","/dogs"]}"#
        }
        let resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
        _ = resp.withCString { send(client, $0, strlen($0), 0) }
    }
}
