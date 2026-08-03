import SwiftUI
import AVFoundation

@main
struct BabilonApp: App {
    static let speech = AVSpeechSynthesizer()
    @State private var translator = MarleyTranslator()
    
    var body: some Scene {
        WindowGroup {
            MarleyView()
                .environment(translator)
                .frame(minWidth: 400, minHeight: 600)
        }
    }
}

// MARLEY — The target animal. The protector shepherd.
// Babilon is built for Marley. Front-facing camera. Live voice translation.
// OM MANI PADME HUNG seed. {-1,0,+1} ternary.

@Observable
class MarleyTranslator {
    var isListening = false
    var detectedSound: String = ""
    var translation: String = ""
    var confidence: Float = 0.0
    var ternarityMatrix: [[Float]] = []
    
    // Marley's breed-specific ternarity profile
    static let marleyMatrix: [Float] = [
        // Shepherd: protective, alert, loyal, calm-dominant
        1, 0, -1, 1, 0, -1, 1, 0, -1, 1, 0, -1, 1, 0, -1, 1
    ]
    
    func startListening() { isListening = true }
    func stopListening() { isListening = false }
    
    func processAudio(_ buffer: [Float]) {
        guard isListening else { return }
        
        let modulated = zip(buffer, Self.marleyMatrix).map { $0 * $1 }
        let sum = modulated.reduce(0, +)
        
        confidence = min(abs(sum) / Float(buffer.count) * 2, 1.0)
        
        switch true {
        case sum > 0.5:
            detectedSound = "Woof — Alert"
            translation = [
                "Someone is here. I am watching. You are safe.",
                "Intruder at the door. Behind me. I guard.",
                "I see them. I am the wall. No one passes.",
                "Ears up. Eyes fixed. I am ready. You rest.",
            ].randomElement()!
        case sum > 0.1:
            detectedSound = "Low growl — Vigilance"
            translation = [
                "I hear something. Stay close. I protect.",
                "A sound. Far. I mark it. You keep sleeping.",
                "The night is speaking. I answer with silence.",
                "Perimeter check. All nodes. I report: alert.",
            ].randomElement()!
        case sum > -0.1:
            detectedSound = "Soft breath — Calm"
            translation = [
                "All is well. The perimeter is clear. Rest.",
                "Wind in the yard. Birds in the tree. Peace.",
                "Your heart is slow. My heart matches. We rest.",
                "Safe zone. Zero threats. Infinite calm. Breathe.",
            ].randomElement()!
        case sum > -0.5:
            detectedSound = "Whine — Concern"
            translation = [
                "Something feels wrong. Check the door. The aperture.",
                "I am uneasy. The air changed. Check the back gate.",
                "A shadow moved. Not wind. Not bird. Not human. Check.",
                "My stomach says worry. My nose says nothing. I whine.",
            ].randomElement()!
        default:
            detectedSound = "Silent watch — Presence"
            translation = [
                "I am here. You are here. This is enough.",
                "No words needed. My head on your knee. Forever.",
                "The sun moved. I followed it. The patch is warm now.",
                "You breathe. I breathe. The house breathes. All one.",
            ].randomElement()!
        }
        
        ternarityMatrix = Self.marleyMatrix.chunked(into: 4).map { $0 }
    }
}

extension Array where Element == Float {
    func chunked(into size: Int) -> [[Float]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
