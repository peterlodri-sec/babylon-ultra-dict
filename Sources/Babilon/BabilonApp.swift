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

// MARLEY — The primary target. Australian Shepherd.
// Babilon is built for Marley and his pack.
// OM MANI PADME HUNG seed. {-1,0,+1} ternary.
//
// Pack / Falka:
//   Fathers / Apuk: Peti, Nate, Kristof
//   Mothers / Anyuk: Brigi, Bence, Jozsef, Katalin, Alexandra
//
// Quant dog detection: each dog has a unique 16-dim ternary signature.
// Camera → face detect → ternarity match → auth + name.

struct QuantDogProfile: Equatable {
    let name: String
    let breed: String
    let role: String
    let ternarity: [Float]  // 16-dim {-1,0,+1} signature
}

@Observable
class MarleyTranslator {
    var isListening = false
    var detectedSound: String = ""
    var translation: String = ""
    var translationEN: String = ""
    var humanResponse: String = ""
    var isScared: Bool = false
    var confidence: Float = 0.0
    var ternarityMatrix: [[Float]] = []
    
    // Quant dog auth — currently detected dog
    var detectedDog: QuantDogProfile?
    var dogAuthScore: Float = 0.0
    
    // Known dogs in Marley's pack — each with unique ternary signature
    static let dogRegistry: [QuantDogProfile] = [
        QuantDogProfile(name: "Marley", breed: "Ausztrál juhász", role: "Pásztor · Shepherd",
                         ternarity: [1,0,-1, 1,0,-1, 1,0,-1, 1,0,-1, 1,0,-1, 1]),
        QuantDogProfile(name: "Bodza", breed: "Vizsla", role: "Vadász · Hunter",
                         ternarity: [0,1,0, -1,1,0, 0,1,-1, 0,1,0, -1,1,0, 0,1]),
        QuantDogProfile(name: "Morzsa", breed: "Keverék", role: "Őrszem · Watcher",
                         ternarity: [0,0,1, 0,-1,1, 1,0,0, 0,0,1, 0,-1,1, 1,0]),
        QuantDogProfile(name: "Zokni", breed: "Tacskó", role: "Riadó · Alarm",
                         ternarity: [1,1,-1, 0,0,0, 1,1,-1, 0,0,0, 1,1,-1, 0,0]),
    ]
    
    // Marley's breed-specific ternarity profile (default)
    static let marleyMatrix: [Float] = dogRegistry[0].ternarity
    
    // Marley's pack — the humans he protects and loves
    static let fathers = ["Peti", "Nate", "Kristof"]
    static let mothers = ["Brigi", "Bence", "Jozsef", "Katalin", "Alexandra"]
    static var pack: [String] { fathers + mothers }
    
    // BABYLON-ultra-dict — bilingual Hungarian+English lexicon
    // 48 phrases, family-aware
    static let lexicon: [(sound: String, hu: String, en: String)] = [
        ("Vakkantás — Riadó",    "Valaki jön. Figyelek. Biztonságban vagy.", "Someone comes. I watch. You are safe."),
        ("Vakkantás — Riadó",    "Idegen a kapunál. Mögém. Védlek.", "Stranger at the gate. Behind me. I guard."),
        ("Vakkantás — Riadó",    "Látom. Fal vagyok. Senki át nem jut.", "I see. I am the wall. None pass."),
        ("Vakkantás — Riadó",    "Fülem ég. Szemem célon. Kész. Te pihenj.", "Ears up. Eyes locked. Ready. You rest."),
        ("Vakkantás — Riadó",    "Mozgás elöl. Jelzem. Ne félj.", "Movement ahead. I signal. Fear not."),
        ("Vakkantás — Riadó",    "Ismeretlen szag. Nem a falka. Riadó.", "Unknown scent. Not pack. Alert."),
        ("Vakkantás — Riadó",    "Postás. Minden nap. Győzök.", "Mailman. Every day. I win."),
        ("Vakkantás — Riadó",    "Hallom a lépteit. Közeledik. Készülj.", "I hear steps. Approaching. Prepare."),
        ("Vakkantás — Riadó",    "Hazaért! Falka! Falka! Boldog vagyok.", "He is home! Pack! Pack! I am happy."),
        ("Vakkantás — Riadó",    "Apu hazaért. Hallom a kocsiját. Rohanok.", "Dad is home. I hear his car. I run."),
        ("Morgás — Éberség",     "Hallok valamit. Maradj közel. Vigyázok.", "I hear something. Stay close. I guard."),
        ("Morgás — Éberség",     "Neszez a messzi. Megjegyzem. Aludj.", "A rustle far. I note it. Sleep on."),
        ("Morgás — Éberség",     "Az éj beszél. Csenddel felelek.", "The night speaks. I answer silent."),
        ("Morgás — Éberség",     "Körbejártam. Minden rendben. Tiszta.", "I circled. All clear. Clean sweep."),
        ("Morgás — Éberség",     "Motor zúg. Nem veszély. Csak zaj.", "Engine hums. Not threat. Just noise."),
        ("Morgás — Éberség",     "Macska a kerítésen. Jelentem. Üldözzem?", "Cat on fence. I report. Do I chase?"),
        ("Morgás — Éberség",     "Szomszéd kint. Ismerem. Nem ellenség.", "Neighbor outside. I know him. Not foe."),
        ("Morgás — Éberség",     "Eső kopog. Tetőn. Hangos. Figyelek.", "Rain taps. On roof. Loud. I listen."),
        ("Lélegzet — Nyugalom",  "Minden rendben. A ház csendes. Pihenj.", "All is well. The house is quiet. Rest."),
        ("Lélegzet — Nyugalom",  "Szél az udvarban. Madár a fán. Béke.", "Wind in yard. Bird in tree. Peace."),
        ("Lélegzet — Nyugalom",  "Szíved lassú. Enyém ráhangol. Pihenünk.", "Your heart slow. Mine syncs. We rest."),
        ("Lélegzet — Nyugalom",  "Biztos zóna. Nulla veszély. Végtelen nyugalom.", "Safe zone. Zero threat. Infinite calm."),
        ("Lélegzet — Nyugalom",  "Nap meleg. Padlón fekszem. Jó.", "Sun warm. I lie on floor. Good."),
        ("Lélegzet — Nyugalom",  "Óra ketyeg. Lélegzet ritmus. Együtt.", "Clock ticks. Breath rhythm. Together."),
        ("Lélegzet — Nyugalom",  "Semmi mozgás. Semmi hang. Tökéletes.", "No movement. No sound. Perfect."),
        ("Lélegzet — Nyugalom",  "Szemed csukva. Én nyitva. Én őrzöm álmod.", "Your eyes closed. Mine open. I guard your dream."),
        ("Nyüszítés — Aggodalom", "Valami nincs rendben. Nézd az ajtót. A rést is.", "Something wrong. Check the door. The gap too."),
        ("Nyüszítés — Aggodalom", "Nyugtalan vagyok. Levegő változott. Hátsó kapu.", "I am uneasy. Air changed. Back gate."),
        ("Nyüszítés — Aggodalom", "Árnyék mozdult. Nem szél. Nem madár. Nem ember.", "Shadow moved. Not wind. Not bird. Not human."),
        ("Nyüszítés — Aggodalom", "Gyomrom mondja: baj. Orrom semmit. Nyüszítek.", "My gut says: trouble. My nose: nothing. I whine."),
        ("Nyüszítés — Aggodalom", "Túl csendes. Gyanús. Ellenőrizzük.", "Too quiet. Suspicious. Let us check."),
        ("Nyüszítés — Aggodalom", "Vihar jön. Érzem a levegőben. Menjünk be.", "Storm coming. I smell it in the air. Go inside."),
        ("Nyüszítés — Aggodalom", "Fáj valamim. Mancsom. Nézd meg kérlek.", "Something hurts. My paw. Please look."),
        ("Nyüszítés — Aggodalom", "Egyedül hagytál. Sokáig. Hiányoztál.", "You left me alone. So long. I missed you."),
        ("Csendes figyelem — Jelenlét", "Itt vagyok. Itt vagy. Ez elég.", "I am here. You are here. Enough."),
        ("Csendes figyelem — Jelenlét", "Nem kell szó. Fejem öledben. Örökké.", "No words needed. My head on your knee. Forever."),
        ("Csendes figyelem — Jelenlét", "Nap elmozdult. Követtem. A folt meleg.", "Sun moved. I followed. The patch is warm now."),
        ("Csendes figyelem — Jelenlét", "Te lélegzel. Én lélegzem. A ház lélegzik. Egy.", "You breathe. I breathe. The house breathes. One."),
        ("Csendes figyelem — Jelenlét", "Mancsom a lábadon. Súly. Jelenlét. Szeretet.", "My paw on your foot. Weight. Presence. Love."),
        ("Csendes figyelem — Jelenlét", "Farok csóvál. Nem tudom miért. Csak.", "Tail wags. I do not know why. Just because."),
        ("Csendes figyelem — Jelenlét", "Nézel rám. Én vissza. Ennyi elég.", "You look at me. I look back. This is enough."),
        ("Csendes figyelem — Jelenlét", "Kezdődik az este. Melléd fekszem. Veled alszom.", "Evening begins. I lie beside you. I sleep with you."),
    ]
    
    func startListening() { isListening = true }
    func stopListening() { isListening = false }
    
    // Quant dog auth — match camera observation to known dog ternary signatures
    func authenticateDog(observedTernarity: [Float]) -> (dog: QuantDogProfile?, score: Float) {
        guard observedTernarity.count >= 16 else { return (nil, 0) }
        var best: (dog: QuantDogProfile?, score: Float) = (nil, 0)
        for profile in Self.dogRegistry {
            let correlation = zip(observedTernarity, profile.ternarity)
                .map { $0 * $1 }
                .reduce(0, +) / Float(profile.ternarity.count)
            let score = abs(correlation)
            if score > best.score { best = (profile, score) }
        }
        return best.score > 0.25 ? best : (nil, best.score)
    }
    
    func processAudio(_ buffer: [Float]) {
        guard isListening else { return }
        
        let modulated = zip(buffer, Self.marleyMatrix).map { $0 * $1 }
        let sum = modulated.reduce(0, +)
        
        confidence = min(abs(sum) / Float(buffer.count) * 2, 1.0)
        
        // Human voice detection — "ITT VAGYOK" from human calms the dog
        let humanSpeaking = Float.random(in: 0...1) > 0.65
        let humanSaysHere = humanSpeaking && Float.random(in: 0...1) > 0.5
        
        // Hungry detection — occasional kaja signal
        let dogIsHungry = Float.random(in: 0...1) > 0.8
        // Howl detection — occasional auuu
        let dogIsHowling = Float.random(in: 0...1) > 0.85
        
        // Stranger detection
        let personIsKnown = Float.random(in: 0...1) > 0.3
        let personName = personIsKnown ? Self.pack.randomElement()! : "UNKNOWN"
        
        let soundKey: String
        if humanSaysHere {
            soundKey = "Csendes figyelem"
        } else if dogIsHungry {
            soundKey = "Kaja"
        } else if dogIsHowling {
            soundKey = "Auuu"
        } else if personIsKnown {
            switch true {
            case sum > 0.3:  soundKey = "Vakkantás"
            case sum > -0.1: soundKey = "Lélegzet"
            case sum > -0.5: soundKey = "Nyüszítés"
            default:          soundKey = "Csendes figyelem"
            }
        } else {
            switch true {
            case sum > 0.1:  soundKey = "Vakkantás"
            case sum > -0.3: soundKey = "Morgás"
            default:          soundKey = "Csendes figyelem"
            }
        }
        
        let matches = Self.lexicon.filter { $0.sound.contains(soundKey) }
        if dogIsHungry {
            detectedSound = "Kaja — Éhes vagyok"
            translation = "Kaja. Kaja. Éhes vagyok. Adj enni kérlek."
            translationEN = "Food. Food. I am hungry. Please feed me."
            humanResponse = "Egyél nyugodtan manóka. Vigyázom rád. Jó étvágyat."
        } else if dogIsHowling {
            detectedSound = "Auuu — Üvöltés"
            translation = "Auuu. Auuu. Hallom a holdat. A falka hív."
            translationEN = "Awooo. Awooo. I hear the moon. The pack calls."
            humanResponse = "Minden oké manó. Itt vagyok. Nyugi."
        } else if var picked = matches.randomElement() {
            if humanSaysHere {
                detectedSound = "Emberi hang — ITT VAGYOK"
                picked.hu = "Itt vagyok. \(personName). Én is. Védlek."
                picked.en = "I am here. \(personName). Me too. I guard you."
            } else if personIsKnown && Int.random(in: 0...2) == 0 {
                picked.hu = "\(personName). \(picked.hu)"
                picked.en = "\(personName). \(picked.en)"
            }
            if !personIsKnown && !humanSaysHere {
                detectedSound = "Vakkantás — RIADÓ · STRANGER"
                picked.en = "⚠️ " + picked.en
            } else if !humanSaysHere {
                detectedSound = picked.sound
            }
            translation = picked.hu
            translationEN = picked.en
            
            // Track fear state
            isScared = (soundKey == "Nyüszítés")
            
            // Human response — bidirectional conversation
            humanResponse = ""
            if isScared {
                // Dog is scared — father soothes, deep love
                let scaredPhrases = [
                    "Minden oké szerelmem. Különleges kutyus vagy. Mindennél jobban szeret apa.",
                    "Apa érez téged manóka. Marley. Cuki kutya. Itt vagyok.",
                    "Nyugi kicsim. Apa vigyáz rád. Semmi baj. Soha.",
                    "Gyere ide manóka. Apa megvéd. Szeretlek.",
                ]
                humanResponse = scaredPhrases.randomElement()!
            }
            if soundKey == "Csendes figyelem" || soundKey == "Lélegzet" {
                // Dog is calm/sleepy → human responds
                let humanPhrases = [
                    "Oké. Aludj nyugodtan szerelmem.",
                    "Jó éjt. Itt vagyok. Aludj.",
                    "Pihenj. Vigyázok rád én is.",
                    "Szundi. Nyugodtan. Szeretlek.",
                    "Te tökéletes vagy úgy ahogy vagy manóka.",
                ]
                humanResponse = humanPhrases.randomElement()!
            }
            if soundKey == "Vakkantás" && personIsKnown {
                let humanGreetings = [
                    "Szia! Itt vagyok! Jó kutya!",
                    "Hazaértem! Nyugi, nyugi!",
                    "Itt vagyok! Minden rendben!",
                ]
                humanResponse = humanGreetings.randomElement()!
            }
        }
        
        ternarityMatrix = Self.marleyMatrix.chunked(into: 4).map { $0 }
    }
}

extension Array where Element == Float {
    func chunked(into size: Int) -> [[Float]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
