import Foundation

// 🎵 music.vaked.dev Dynamic Seed Generator
// Layer between microphone input and translation output.
// Fetches the current music frequency/seed from music.vaked.dev
// and uses it to dynamically modulate the translation seed.
// OM MANI PADME HUNG is the base seed. Music modifies it.

@Observable
class MusicSeedGenerator {
    static let baseSeed = "OM MANI PADME HUNG"
    
    private(set) var currentFrequency: String = "∞ Hz"
    private(set) var currentTrack: String = "Akkezdet Phiai — Kottazűr"
    private(set) var dynamicSeed: String = baseSeed
    private(set) var ternarityModulation: [Float] = []
    private(set) var isFetching = false
    private var fetchTimer: Timer?
    
    // 🎵 Frequency bands mapped to {-1,0,+1} modulation
    enum FrequencyBand: String, CaseIterable {
        case bass = "Bass"       // -1: deep, grounding, past
        case mid = "Mid"          // 0: present, balance, now
        case treble = "Treble"    // +1: high, ascending, future
        
        var ternarity: Float {
            switch self {
            case .bass: return -1.0
            case .mid: return 0.0
            case .treble: return 1.0
            }
        }
    }
    
    // 🎼 Current playing track simulation (from music.vaked.dev API)
    struct Track {
        let title: String
        let artist: String
        let frequency: String
        let bpm: Int
        let dominantBand: FrequencyBand
        let seedSuffix: String
    }
    
    private let playlist: [Track] = [
        Track(title: "Kottazűr", artist: "Akkezdet Phiai", frequency: "∞ Hz", bpm: 87, dominantBand: .bass, seedSuffix: "KOTTAZUR"),
        Track(title: "Kocsi", artist: "Belga", frequency: "420 Hz", bpm: 120, dominantBand: .mid, seedSuffix: "KOCSI"),
        Track(title: "Vegyetek jót ha tudtok", artist: "NKS", frequency: "333 Hz", bpm: 94, dominantBand: .treble, seedSuffix: "VEGYETEKJOT"),
        Track(title: "Megalázó És Felszabadító", artist: "Akkezdet Phiai", frequency: "777 Hz", bpm: 78, dominantBand: .bass, seedSuffix: "MEGALAZO"),
        Track(title: "Nincs baj", artist: "Sub Bass Monster", frequency: "111 Hz", bpm: 88, dominantBand: .mid, seedSuffix: "NINCSBAJ"),
    ]
    
    private var currentTrackIndex = 0
    
    // 🎵 Start fetching dynamic seeds from music.vaked.dev
    func startFetching() {
        isFetching = true
        fetchCurrentTrack()
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 4.2, repeats: true) { [weak self] _ in
            self?.fetchCurrentTrack()
        }
    }
    
    func stopFetching() {
        isFetching = false
        fetchTimer?.invalidate()
        fetchTimer = nil
    }
    
    // 🎵 Fetch current track from music.vaked.dev API
    private func fetchCurrentTrack() {
        // Rotate through playlist (simulating music.vaked.dev API)
        currentTrackIndex = (currentTrackIndex + 1) % playlist.count
        let track = playlist[currentTrackIndex]
        
        currentTrack = "\(track.artist) — \(track.title)"
        currentFrequency = track.frequency
        
        // Generate dynamic seed: baseSeed + track suffix + frequency
        dynamicSeed = "\(Self.baseSeed)_\(track.seedSuffix)_\(track.frequency.replacingOccurrences(of: " ", with: ""))"
        
        // Generate ternarity modulation from track
        ternarityModulation = generateTernarityModulation(from: track)
    }
    
    // 🎵 Track → {-1,0,+1} modulation vector
    private func generateTernarityModulation(from track: Track) -> [Float] {
        var mod: [Float] = []
        let seedBytes = dynamicSeed.data(using: .utf8) ?? Data()
        var xoshiro = Xoshiro128StarStar(seedData: seedBytes)
        
        // 16-dim ternarity vector modulated by music
        for i in 0..<16 {
            let r = xoshiro.next()
            let base: Float
            
            // BPM influences quantization threshold
            let bpmFactor = Float(track.bpm) / 120.0
            
            if r < 0.33 * bpmFactor {
                base = track.dominantBand.ternarity // Dominant from music
            } else if r < 0.66 {
                base = 0.0 // Silence (zen)
            } else {
                base = -track.dominantBand.ternarity // Counter-dominant
            }
            mod.append(base)
        }
        
        return mod
    }
    
    // 🎵 Apply music seed modulation to animal translation
    func modulateTranslation(_ translation: String) -> String {
        let mod = ternarityModulation
        guard !mod.isEmpty else { return translation }
        
        let avgTernarity = mod.reduce(0, +) / Float(mod.count)
        
        // Music influences translation tone
        if avgTernarity > 0.3 {
            return "🎵 \(translation) [ascending]"
        } else if avgTernarity < -0.3 {
            return "🎵 \(translation) [grounded]"
        } else {
            return "🎵 \(translation) [present]"
        }
    }
    
    // 🎵 Generate seed for MLX-QUANT based on current music
    func currentMLXSeed() -> Data {
        return dynamicSeed.data(using: .utf8) ?? Self.baseSeed.data(using: .utf8)!
    }
}
