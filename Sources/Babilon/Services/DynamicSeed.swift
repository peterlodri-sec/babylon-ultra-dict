import Foundation

@Observable
final class DynamicSeed: @unchecked Sendable {
    static let baseSeed = "OM MANI PADME HUNG"
    private(set) var seed: String = baseSeed
    private(set) var track: String = "Akkezdet Phiai — Kottazűr"
    private(set) var frequency: String = "∞ Hz"
    
    private let playlist = [
        ("Akkezdet Phiai", "Kottazűr", "∞ Hz"),
        ("Belga", "Kocsi", "420 Hz"),
        ("NKS", "Vegyetek jót ha tudtok", "333 Hz"),
        ("Akkezdet Phiai", "Megalázó És Felszabadító", "777 Hz"),
        ("Sub Bass Monster", "Nincs baj", "111 Hz"),
        ("Belga", "Nemzeti Hiphop", "888 Hz"),
        ("Akkezdet Phiai", "Akkezdet", "666 Hz"),
        ("NKS", "Nincsen Kegyelem Soha", "999 Hz"),
        ("Solomun", "Nobody Is Not Loved", "432 Hz"),
    ]
    private var index = 0
    
    func start() {
        Task { @MainActor in
            while true {
                fetchNextTrack()
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
        // Background API fetch
        Task { await fetchFromAPI() }
    }
    
    @MainActor
    private func fetchNextTrack() {
        let t = playlist[index % playlist.count]
        track = "\(t.0) — \(t.1)"
        frequency = t.2
        seed = "\(DynamicSeed.baseSeed)_\(t.1.uppercased().replacingOccurrences(of: " ", with: "_"))_\(t.2.replacingOccurrences(of: " ", with: ""))"
        index += 1
    }
    
    private func fetchFromAPI() async {
        guard let url = URL(string: "https://music.vaked.dev/ENTHEA"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return }
        await MainActor.run {
            track = json["track"] ?? track
            frequency = json["frequency"] ?? frequency
            seed = "\(DynamicSeed.baseSeed)_\(track.replacingOccurrences(of: " ", with: "_"))_\(frequency.replacingOccurrences(of: " ", with: ""))"
        }
    }
}
