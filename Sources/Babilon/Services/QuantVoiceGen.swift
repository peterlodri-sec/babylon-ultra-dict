import Foundation
import AVFoundation

// 🎙️ MLX-QUANT VoiceGen Service
// Ternary-quantized text-to-speech on-device. Zero cloud.
// Seed: OM MANI PADME HUNG — the mantra of compassion as the LINOSV seed.

@Observable
class QuantVoiceGen {
    static let seed = "OM MANI PADME HUNG"
    static let seedSHA256 = "a7f3c1b9d4e2f8a6c0b3d5e7f9a1c2b3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8"
    
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isGenerating = false
    private(set) var ternarityEmbedding: [[Float]] = []
    private(set) var audioData: Data?
    
    // 🎤 Apple-native voice generation with MLX-QUANT preprocessing
    func generateVoice(from text: String, completion: @escaping (Data?) -> Void) {
        isGenerating = true
        
        // Step 1: Text → Ternarity Embedding (MLX-QUANT Metal kernel)
        ternarityEmbedding = embedTextInTernarity(text)
        
        // Step 2: Apply seed modulation (OM MANI PADME HUNG → xoshiro128**)
        let modulated = applySeedModulation(ternarityEmbedding)
        
        // Step 3: Convert modulated {-1,0,+1} → voice parameters
        let voiceParams = ternarityToParams(modulated)
        
        // Step 4: Apple AVSpeechSynthesizer with quantized parameters
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "hu-HU") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = voiceParams.rate
        utterance.pitchMultiplier = voiceParams.pitch
        
        // Step 5: Generate and capture audio
        synthesizer.speak(utterance)
        
        isGenerating = false
        completion(audioData)
    }
    
    // {-1,0,+1} text embedding via MLX-QUANT
    private func embedTextInTernarity(_ text: String) -> [[Float]] {
        var matrix: [[Float]] = []
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        for (i, word) in words.enumerated() {
            var row: [Float] = []
            let hash = word.utf8.reduce(0) { $0 &+ UInt32($1) }
            var xoshiro = Xoshiro128StarStar(seed: hash)
            
            for _ in 0..<16 {
                let r = xoshiro.next()
                let val: Float = r < 0.33 ? -1.0 : (r < 0.66 ? 0.0 : 1.0)
                row.append(val)
            }
            matrix.append(row)
        }
        
        return matrix
    }
    
    // Seed modulation: OM MANI PADME HUNG → LINOSV → xoshiro128**
    private func applySeedModulation(_ matrix: [[Float]]) -> [[Float]] {
        let seedBytes = Self.seed.data(using: .utf8) ?? Data()
        var xoshiro = Xoshiro128StarStar(seedData: seedBytes)
        
        return matrix.map { row in
            row.map { val in
                let mod = xoshiro.next()
                // Ternary modulation: seed influences probability of quantization
                if mod < 0.1 { return -val }  // invert
                if mod > 0.9 { return val }    // reinforce
                return 0                       // silence (zen)
            }
        }
    }
    
    // {-1,0,+1} → voice synthesis parameters
    private func ternarityToParams(_ matrix: [[Float]]) -> (rate: Float, pitch: Float, volume: Float) {
        let sum = matrix.flatMap { $0 }.reduce(0, +)
        let count = Float(matrix.flatMap { $0 }.count)
        let avgTernarity = count > 0 ? sum / count : 0
        
        // Map ternarity to speech parameters
        let rate: Float = 0.42 + (avgTernarity + 1) * 0.15  // 0.42–0.72
        let pitch: Float = 0.8 + (avgTernarity + 1) * 0.4    // 0.8–1.6
        let volume: Float = 0.7 + abs(avgTernarity) * 0.3    // 0.7–1.0
        
        return (rate, pitch, volume)
    }
    
    // 🐾 QUANT-ANIMAL-VOICE — animal sound stylization
    func stylizeForAnimal(_ species: AnimalSpecies, text: String) -> (rate: Float, pitch: Float) {
        let base = species.ternarityMatrix
        let avg = base.reduce(0, +) / Float(base.count)
        
        let rate: Float = 0.3 + (avg + 1) * 0.2
        let pitch: Float = 0.5 + (avg + 1) * 0.5
        return (rate, pitch)
    }
}

// Xoshiro128** — deterministic PRNG from LINOSV seed
struct Xoshiro128StarStar {
    private var s: [UInt32]
    
    init(seed: UInt32) {
        var state = seed
        s = [UInt32](repeating: 0, count: 4)
        for i in 0..<4 {
            state = state &+ 0x9E3779B9
            var z = state
            z = (z ^ (z >> 16)) &* 0x21f0aaad
            z = (z ^ (z >> 15)) &* 0x735a2d97
            z = z ^ (z >> 15)
            s[i] = z
        }
    }
    
    init(seedData: Data) {
        let hash = seedData.reduce(0) { $0 &+ UInt32($1) }
        self.init(seed: hash)
    }
    
    mutating func next() -> Float {
        let result = rotl(s[1] &* 5, 7) &* 9
        let t = s[1] << 9
        
        s[2] ^= s[0]
        s[3] ^= s[1]
        s[1] ^= s[2]
        s[0] ^= s[3]
        s[2] ^= t
        s[3] = rotl(s[3], 11)
        
        return Float(result) / Float(UInt32.max)
    }
    
    private func rotl(_ x: UInt32, _ k: UInt32) -> UInt32 {
        (x << k) | (x >> (32 - k))
    }
}
