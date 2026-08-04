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
            detectedSound = "Vakkantás — Riadó"
            translation = [
                "Valaki jön. Én figyelek. Te biztonságban vagy.",
                "Idegen a kapunál. Mögém bújj. Én védelek.",
                "Látom őket. Én vagyok a fal. Senki nem jut át.",
                "Fülem égnek. Szemem a célon. Készen állok. Te pihenj.",
            ].randomElement()!
        case sum > 0.1:
            detectedSound = "Mély morgás — Éberség"
            translation = [
                "Hallok valamit. Maradj közel. Én vigyázok rád.",
                "Egy neszez a messzi. Megjegyzem. Aludj tovább.",
                "Az éj beszél. Én csenddel felelek neki.",
                "Körbejártam. Minden rendben. Jelentem: tiszta.",
            ].randomElement()!
        case sum > -0.1:
            detectedSound = "Halk lélegzet — Nyugalom"
            translation = [
                "Minden rendben. A ház csendes. Pihenjünk.",
                "Szél az udvarban. Madár a fán. Béke van.",
                "A szíved lassú. Az enyém ráhangolódik. Pihenünk.",
                "Biztos zóna. Nulla veszély. Végtelen nyugalom. Lélegezz.",
            ].randomElement()!
        case sum > -0.5:
            detectedSound = "Nyüszítés — Aggodalom"
            translation = [
                "Valami nincs rendben. Nézz az ajtóra. A résre is.",
                "Nyugtalan vagyok. A levegő megváltozott. Nézz a hátsó kapura.",
                "Egy árnyék mozdult. Nem szél. Nem madár. Nem ember. Nézd meg.",
                "A gyomrom azt mondja: baj. Az orrom semmit. Nyüszítek.",
            ].randomElement()!
        default:
            detectedSound = "Csendes figyelem — Jelenlét"
            translation = [
                "Itt vagyok. Itt vagy. Ez elég.",
                "Nem kell szó. A fejem az öledben. Örökké.",
                "A nap elmozdult. Követtem. A folt most meleg.",
                "Te lélegzel. Én lélegzem. A ház lélegzik. Egyek vagyunk.",
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
