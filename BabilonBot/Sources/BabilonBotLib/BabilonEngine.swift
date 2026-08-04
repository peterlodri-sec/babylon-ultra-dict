import Foundation
import AVFoundation

// MARK: - Xoshiro128StarStar (core PRNG)

public struct Xoshiro128StarStar: Sendable {
    private var s: [UInt32]

    public init(seedString: String) {
        let data = seedString.data(using: .utf8) ?? Data()
        let hash = data.reduce(0) { $0 &+ UInt32($1) }
        var state = hash
        s = [UInt32](repeating: 0, count: 4)
        for i in 0..<4 {
            state = state &+ 0x9E3779B9
            var z = state; z = (z ^ (z >> 16)) &* 0x21f0aaad
            z = (z ^ (z >> 15)) &* 0x735a2d97; z = z ^ (z >> 15)
            s[i] = z
        }
    }

    public mutating func next() -> Float {
        let result = rotl(s[1] &* 5, 7) &* 9
        let t = s[1] << 9
        s[2] ^= s[0]; s[3] ^= s[1]; s[1] ^= s[2]; s[0] ^= s[3]; s[2] ^= t
        s[3] = rotl(s[3], 11)
        return Float(result) / Float(UInt32.max)
    }

    private func rotl(_ x: UInt32, _ k: UInt32) -> UInt32 { (x << k) | (x >> (32 - k)) }
}

// MARK: - Quant Dog Profiles

public struct QuantDogProfile: Codable, Sendable, Equatable {
    public let name: String
    public let breed: String
    public let role: String
    public let ternarity: [Float]

    public static let registry: [QuantDogProfile] = [
        QuantDogProfile(name: "Marley", breed: "Ausztrál juhász", role: "Pásztor",
                         ternarity: [1,0,-1, 1,0,-1, 1,0,-1, 1,0,-1, 1,0,-1, 1]),
        QuantDogProfile(name: "Bodza", breed: "Vizsla", role: "Vadász",
                         ternarity: [0,1,0, -1,1,0, 0,1,-1, 0,1,0, -1,1,0, 0,1]),
        QuantDogProfile(name: "Morzsa", breed: "Keverék", role: "Őrszem",
                         ternarity: [0,0,1, 0,-1,1, 1,0,0, 0,0,1, 0,-1,1, 1,0]),
        QuantDogProfile(name: "Zokni", breed: "Tacskó", role: "Riadó",
                         ternarity: [1,1,-1, 0,0,0, 1,1,-1, 0,0,0, 1,1,-1, 0,0]),
    ]
}

// MARK: - Translation Record (for MLX learning)

public struct TranslationRecord: Codable, Sendable {
    public let timestamp: Date
    public let soundType: String
    public let hungarian: String
    public let english: String
    public let confidence: Float
    public let seed: String
    public let dogName: String
    public let eyeDetected: Bool

    public init(soundType: String, hu: String, en: String, confidence: Float, seed: String, dogName: String, eyeDetected: Bool) {
        self.timestamp = Date()
        self.soundType = soundType
        self.hungarian = hu
        self.english = en
        self.confidence = confidence
        self.seed = seed
        self.dogName = dogName
        self.eyeDetected = eyeDetected
    }
}

// MARK: - Lexicon

public struct LexiconEntry: Sendable {
    public let sound: String
    public let hu: String
    public let en: String
}

public let BabilonLexicon: [LexiconEntry] = [
    LexiconEntry(sound: "Vakkantás", hu: "Valaki jön. Figyelek. Biztonságban vagy.", en: "Someone comes. I watch. You are safe."),
    LexiconEntry(sound: "Vakkantás", hu: "Idegen a kapunál. Mögém. Védlek.", en: "Stranger at the gate. Behind me. I guard."),
    LexiconEntry(sound: "Vakkantás", hu: "Látom. Fal vagyok. Senki át nem jut.", en: "I see. I am the wall. None pass."),
    LexiconEntry(sound: "Vakkantás", hu: "Fülem ég. Szemem célon. Kész. Pihenj.", en: "Ears up. Eyes locked. Ready. Rest."),
    LexiconEntry(sound: "Vakkantás", hu: "Mozgás elöl. Jelzem. Ne félj.", en: "Movement ahead. I signal. Fear not."),
    LexiconEntry(sound: "Vakkantás", hu: "Hazaért! Falka! Boldog vagyok.", en: "He is home! Pack! I am happy."),
    LexiconEntry(sound: "Morgás", hu: "Hallok valamit. Maradj közel. Vigyázok.", en: "I hear something. Stay close. I guard."),
    LexiconEntry(sound: "Morgás", hu: "Az éj beszél. Csenddel felelek.", en: "The night speaks. I answer silent."),
    LexiconEntry(sound: "Morgás", hu: "Körbejártam. Minden rendben. Tiszta.", en: "I circled. All clear. Clean."),
    LexiconEntry(sound: "Morgás", hu: "Macska a kerítésen. Jelentem. Üldözzem?", en: "Cat on fence. I report. Chase?"),
    LexiconEntry(sound: "Lélegzet", hu: "Minden rendben. A ház csendes. Pihenj.", en: "All well. House quiet. Rest."),
    LexiconEntry(sound: "Lélegzet", hu: "Szíved lassú. Enyém ráhangol. Pihenünk.", en: "Your heart slow. Mine syncs. We rest."),
    LexiconEntry(sound: "Lélegzet", hu: "Nap meleg. Padlón fekszem. Jó.", en: "Sun warm. Floor. Good."),
    LexiconEntry(sound: "Lélegzet", hu: "Szemed csukva. Én nyitva. Őrzöm álmod.", en: "Your eyes closed. Mine open. I guard your dream."),
    LexiconEntry(sound: "Nyüszítés", hu: "Valami nincs rendben. Nézd az ajtót.", en: "Something wrong. Check the door."),
    LexiconEntry(sound: "Nyüszítés", hu: "Árnyék mozdult. Nem szél. Nem madár.", en: "Shadow moved. Not wind. Not bird."),
    LexiconEntry(sound: "Nyüszítés", hu: "Vihar jön. Érzem. Menjünk be.", en: "Storm coming. I feel it. Go inside."),
    LexiconEntry(sound: "Nyüszítés", hu: "Egyedül hagytál. Sokáig. Hiányoztál.", en: "You left me. So long. I missed you."),
    LexiconEntry(sound: "Csendes", hu: "Itt vagyok. Itt vagy. Ez elég.", en: "I am here. You are here. Enough."),
    LexiconEntry(sound: "Csendes", hu: "Nem kell szó. Fejem öledben. Örökké.", en: "No words. My head on your knee. Forever."),
    LexiconEntry(sound: "Csendes", hu: "Mancsom a lábadon. Súly. Szeretet.", en: "My paw on your foot. Weight. Love."),
    LexiconEntry(sound: "Csendes", hu: "Este van. Melléd fekszem. Veled alszom.", en: "Evening. Beside you. I sleep with you."),
]

// MARK: - Baby Drift (phonetic transformation)

public func babyDrift(_ word: String, prng: inout Xoshiro128StarStar, hash: Float) -> String {
    let vowels: Set<Character> = ["a", "e", "i", "o", "u", "á", "é", "í", "ó", "ú", "ü", "ű", "ö", "ő"]
    let babyMap: [Character: String] = ["r": "w", "l": "y", "s": "sh", "t": "tch", "p": "b", "b": "b", "v": "b", "f": "ff", "c": "k", "g": "g", "d": "d", "m": "m", "n": "n", "h": "h", "w": "w", "j": "y", "z": "z"]
    var out = ""
    var lastChar: Character = "\0"
    var jit = prng.next()
    for ch in word.lowercased() {
        let drift = Int((jit * hash * 7).truncatingRemainder(dividingBy: 3))
        jit = prng.next()
        guard out.count < 8 else { break }
        if vowels.contains(ch) {
            if drift == 0 && lastChar != ch { out.append(ch); out.append(ch) }
            else if lastChar != ch { out.append(ch) }
            lastChar = ch
        } else if let baby = babyMap[ch] {
            if drift == 2 { continue }
            if out.hasSuffix(baby) { continue }
            out += baby; lastChar = ch
        } else { out.append(ch); lastChar = ch }
    }
    return out.isEmpty ? "mm" : out
}

// MARK: - Quant Translation Engine

public func makeQuantTranslation(sound: String, meaning: String, seed: String, dog: String = "Marley") -> (text: String, feeling: String, quality: Float) {
    var prng = Xoshiro128StarStar(seedString: seed + sound + meaning)
    let words = meaning.components(separatedBy: .whitespacesAndNewlines.union(.punctuationCharacters)).filter { !$0.isEmpty && $0.count > 1 }

    let sl = sound.lowercased()
    let babblePool: [String]
    if sl.contains("vakkant") { babblePool = ["brrr", "grrr", "vau", "awoo"] }
    else if sl.contains("nyüsz") { babblePool = ["nnng", "nyih", "mmm", "baba"] }
    else if sl.contains("morg") { babblePool = ["grrr", "gah", "vauu", "brrr"] }
    else if sl.contains("lélegz") || sl.contains("nyugal") { babblePool = ["mmm", "óóó", "baba", "szu"] }
    else { babblePool = ["gaga", "szu", "vau", "mmm", "baba"] }

    let feelings = ["bizti", "figyi", "csend", "szundi", "védlek", "szeret", "boldog", "riadó", "játék", "otthon", "marad", "véd", "kaja", "meleg", "falka", "pihi", "jó", "most"]

    let b1 = babblePool[Int(prng.next() * Float(babblePool.count)) % babblePool.count]
    let feeling = feelings[Int(prng.next() * Float(feelings.count)) % feelings.count]

    let fragments = words.enumerated().compactMap { i, word -> String? in
        guard word.count >= 2 else { return nil }
        let hash = Float(abs(word.hashValue) % 100) / 100.0
        var drift = babyDrift(word, prng: &prng, hash: hash)
        if (i % 3) == 2, let midBabble = babblePool.randomElement() {
            drift += "… " + midBabble
        }
        return drift
    }
    let mid = fragments.isEmpty ? b1 : fragments.joined(separator: "… ")
    let text = "\(b1)… \(mid) …\(feeling)."
    let quality = min(0.65 + Float(fragments.count) * 0.03 + prng.next() * 0.1, 0.99)
    return (text, feeling, quality)
}

// MARK: - Bot Engine — headless continuous translation

@MainActor
public class BabilonBotEngine {
    public private(set) var isRunning = false
    public private(set) var records: [TranslationRecord] = []
    public private(set) var currentDog: QuantDogProfile?
    public var onTranslation: ((TranslationRecord) -> Void)?

    private let seedBase = "OM_MANI_PADME_HUNG"
    private var musicTrackIndex = 0
    private let playlist = [
        ("Akkezdet Phiai", "Kottazűr"), ("Belga", "Kocsi"),
        ("NKS", "Vegyetek jót ha tudtok"), ("Akkezdet Phiai", "Megalázó És Felszabadító"),
        ("Sub Bass Monster", "Nincs baj"), ("Belga", "Nemzeti Hiphop"),
        ("Akkezdet Phiai", "Akkezdet"), ("NKS", "Nincsen Kegyelem Soha"),
        ("Solomun", "Nobody Is Not Loved"),
    ]

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        currentDog = QuantDogProfile.registry[0] // Default: Marley

        Task { @MainActor in
            while isRunning {
                generateTranslation()
                try? await Task.sleep(nanoseconds: UInt64((1_500_000_000...3_500_000_000).randomElement()!))
            }
        }
    }

    public func stop() { isRunning = false }

    private func generateTranslation() {
        let soundTypes = ["Vakkantás", "Morgás", "Lélegzet", "Nyüszítés", "Csendes"]
        let sound = soundTypes.randomElement()!

        let matches = BabilonLexicon.filter { $0.sound == sound }
        guard let picked = matches.randomElement() else { return }

        let track = playlist[musicTrackIndex % playlist.count]
        let seed = "\(seedBase)_\(track.1.uppercased().replacingOccurrences(of: " ", with: "_"))"
        musicTrackIndex += 1

        var combinedSeed = seed
        let eyeDetected = Float.random(in: 0...1) > 0.4
        if eyeDetected {
            let ex = Int.random(in: 0...255)
            let ey = Int.random(in: 0...255)
            combinedSeed += "_EYE_\(ex)x\(ey)"
        }

        let dog = currentDog?.name ?? "Marley"
        let (quantText, feeling, quality) = makeQuantTranslation(sound: sound, meaning: picked.hu, seed: combinedSeed, dog: dog)

        let record = TranslationRecord(
            soundType: sound, hu: quantText, en: picked.en,
            confidence: quality, seed: combinedSeed, dogName: dog,
            eyeDetected: eyeDetected
        )
        records.append(record)
        onTranslation?(record)
    }

    public func exportRecordsAsJSONL() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return records.compactMap { try? String(data: encoder.encode($0), encoding: .utf8) }.joined(separator: "\n")
    }
}
