import SwiftUI
import AVFoundation

struct MarleyView: View {
    @Environment(MarleyTranslator.self) private var translator
    @State private var session: AVCaptureSession?
    @State private var thinkingProgress: Double = 0
    @State private var showTranslation: Bool = false
    @State private var thinkingTimer: Task<Void, Never>?
    @State private var dogDetected: Bool = false
    @State private var dogConfidence: Float = 0.0
    @State private var eyeDetected: Bool = false
    @State private var dogEyeSeed: String = ""
    @State private var dynamicSeed = DynamicSeed()
    @State private var authDog: QuantDogProfile?
    @State private var wavePhases: [Float] = (0..<16).map { _ in Float.random(in: -1...1) }
    @State private var calmWavePhase: Double = 0
    
    // Marley's 16-dim ternarity matrix — OM MANI PADME HUNG
    let marleyTernary: [Float] = [1, 0, -1, 1, 0, -1, 1, 0, -1, 1, 0, -1, 1, 0, -1, 1]

    var body: some View {
        ZStack {
            CameraPreview(session: $session)
            Rectangle().fill(.black.opacity(0.55))
            
            // Calming waves → toward dog (appears in calm states)
            if translator.translation.contains("Nyugalom") || translator.translation.contains("Jelenlét") || translator.detectedSound.contains("Lélegzet") || translator.detectedSound.contains("Csendes") {
                CalmWavesView(phase: calmWavePhase)
                    .allowsHitTesting(false)
            }
            
            SelfieMirror(session: $session)
            
            // Waveform — top right 256×256
            VStack {
                HStack {
                    Spacer()
                    QuantWaveView(phases: wavePhases, confidence: translator.confidence)
                        .frame(width: 256, height: 256)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.cyan.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.leading, 24)
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
            
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    // Detected dog — quant auth
                    if let dog = authDog {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dog.name.uppercased())
                                .font(.system(size: 52, weight: .black, design: .monospaced))
                                .foregroundStyle(.cyan)
                                .shadow(color: .cyan.opacity(0.4), radius: 12)
                            Text("\(dog.breed) · \(dog.role)")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundStyle(.cyan.opacity(0.5))
                        }
                        .padding(.bottom, 8)
                    } else {
                        Text("CUKI KUTYA")
                            .font(.system(size: 42, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.8), radius: 8)
                    }
                    if dogDetected {
                        HStack(spacing: 8) {
                            Circle().fill(Color.green).frame(width: 12, height: 12)
                                .shadow(color: .green.opacity(0.6), radius: 4)
                            Text("dog · \(Int(dogConfidence * 100))%")
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundStyle(.green)
                                .shadow(color: .black.opacity(0.7), radius: 3)
                            if eyeDetected {
                                Circle().fill(Color.yellow).frame(width: 10, height: 10)
                                    .shadow(color: .yellow.opacity(0.6), radius: 4)
                                Text("eyes · \(dogEyeSeed.dropFirst(5))")
                                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.yellow)
                                    .shadow(color: .black.opacity(0.7), radius: 3)
                            }
                        }
                    }
                }
                .padding(.leading, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                
                if showTranslation {
                    VStack(spacing: 8) {
                        Text(translator.translation)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.9), radius: 6)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                        Text(translator.translationEN)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.7), radius: 4)
                            .padding(.horizontal, 32)
                    }
                    .transition(.opacity)
                    .padding(.bottom, 20)
                }
                
                // BABYLON-ultra-dict footer — Marley's pack
                VStack(spacing: 2) {
                    Text("falka · \(MarleyTranslator.fathers.joined(separator: ", ")) · \(MarleyTranslator.mothers.joined(separator: ", "))")
                        .font(.system(size: 5, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.15))
                    Text("BABYLON-ultra-dict")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.3))
                        .lineLimit(1)
                    Text(dynamicSeed.seed)
                        .font(.system(size: 6, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.2))
                        .lineLimit(1)
                    Text("🎵 \(dynamicSeed.track)")
                        .font(.system(size: 6, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.15))
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            startCamera()
            dynamicSeed.start()
            translator.isListening = true
            translator.startListening()
            startContinuousTranslation()
            startWaveAnimation()
            authenticateDogOnStartup()
        }
    }
    
    // Quant dog auth at startup — match observation to registry
    func authenticateDogOnStartup() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            // Simulate dog observation — use current ternarity + random jitter
            let observed = marleyTernary.enumerated().map { i, v in
                v + Float.random(in: -0.3...0.3)
            }
            let (dog, score) = translator.authenticateDog(observedTernarity: observed)
            authDog = dog
            translator.dogAuthScore = score
        }
    }
    
    // Always streaming voice — Marley→human with 1-3s delay
    // Plays only when dog + eye detected above 51%
    func startContinuousTranslation() {
        thinkingProgress = 0; showTranslation = false
        thinkingTimer?.cancel()
        thinkingTimer = Task { @MainActor in
            while translator.isListening {
                let delay = UInt64((1_000_000_000...3_000_000_000).randomElement()!)
                try? await Task.sleep(nanoseconds: delay)
                guard translator.isListening else { break }
                
                // Gate: play only when dog + eye both above 51%
                guard dogDetected && eyeDetected && dogConfidence > 0.51 else { continue }
                
                thinkingProgress = 0
                for _ in 0..<12 {
                    try? await Task.sleep(nanoseconds: 42_000_000)
                    thinkingProgress += 0.083
                }
                
                let combinedSeed = dynamicSeed.seed + dogEyeSeed
                let dogName = authDog?.name ?? "Marley"
                let translation = makeQuantTranslation(
                    sound: translator.detectedSound,
                    meaning: translator.translation,
                    seed: combinedSeed,
                    dog: dogName
                )
                translator.translation = translation
                showTranslation = true
                
                playBabySound()
                speakTranslation(translation, seed: combinedSeed)
                
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if translator.isListening { thinkingProgress = 0; showTranslation = false }
            }
        }
    }
    
    // Quant transformation: raw sound + seed → baby-babble dog speech
    func makeQuantTranslation(sound: String, meaning: String, seed: String, dog: String = "Marley") -> String {
        var prng = Xoshiro128StarStar(seedString: seed + sound + meaning)
        
        let words = meaning.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty && $0.count > 1 }
        
        // Sound-specific babble — Hungarian dog sounds
        let sl = sound.lowercased()
        let babblePool: [String]
        if sl.contains("vakkant") || sl.contains("woof") { babblePool = ["brrr", "grrr", "vau", "awoo"] }
        else if sl.contains("nyüsz") || sl.contains("whine") { babblePool = ["nnng", "nyih", "mmm", "baba"] }
        else if sl.contains("morg") || sl.contains("growl") { babblePool = ["grrr", "gah", "vauu", "brrr"] }
        else if sl.contains("lélegz") || sl.contains("nyugal") { babblePool = ["mmm", "óóó", "baba", "szu"] }
        else { babblePool = ["gaga", "szu", "vau", "mmm", "baba"] }
        
        // Hungarian emotional end-words
        let feelings = ["bizti", "figyi", "csend", "szundi", "védlek", "szeret", "boldog", "riadó", "játék", "otthon", "marad", "véd", "kaja", "meleg", "falka", "pihi", "jó", "most"]
        
        let b1 = babblePool[Int(prng.next() * Float(babblePool.count)) % babblePool.count]
        let b2 = babblePool[Int(prng.next() * Float(babblePool.count)) % babblePool.count]
        let feeling = feelings[Int(prng.next() * Float(feelings.count)) % feelings.count]
        
        let fragments = words.enumerated().compactMap { i, word -> String? in
            guard word.count >= 2 else { return nil }
            let hash = Float(abs(word.hashValue) % 100) / 100.0
            let drift = word.babyDrift(prng: &prng, hash: hash)
            // Interleave mid-babble every ~3rd word
            if (i % 3) == 2, let midBabble = babblePool.randomElement() {
                return drift + "… " + midBabble
            }
            return drift
        }
        let mid = fragments.isEmpty ? b2 : fragments.joined(separator: "… ")
        return "\(b1)… \(mid) …\(feeling)."
    }
    
    // Random baby coo/babble — bilingual EN+HU
    func playBabySound() {
        let huBabble = ["vau", "nyih", "brr", "mmm", "hau", "szű", "óó", "gá"]
        let enBabble = ["woof", "brrr", "mmm", "baba", "gah", "ooo", "wah"]
        let picked = (Bool.random() ? huBabble : enBabble).randomElement()!
        let utterance = AVSpeechUtterance(string: picked)
        let useHU = huBabble.contains(picked)
        utterance.voice = AVSpeechSynthesisVoice(language: useHU ? "hu-HU" : "en-US")
        utterance.rate = useHU ? 0.22 : 0.25
        utterance.pitchMultiplier = 1.35
        utterance.volume = 0.4
        BabilonApp.speech.speak(utterance)
    }
    
    // Bilingual TTS — alternates EN+HU per cycle
    func speakTranslation(_ text: String, seed: String = "OM MANI PADME HUNG") {
        guard !text.isEmpty else { return }
        let seedHash = abs(seed.hashValue % 100)
        
        // Speak in alternate language based on seed parity
        let useHungarian = (seedHash % 2) == 0
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: useHungarian ? "hu-HU" : "en-US")
        utterance.rate = useHungarian ? 0.35 + Float(seedHash) / 500.0 : 0.40 + Float(seedHash) / 500.0
        utterance.pitchMultiplier = useHungarian ? 0.75 + Float(seedHash) / 1000.0 : 0.85 + Float(seedHash) / 1000.0
        utterance.volume = 0.85
        BabilonApp.speech.speak(utterance)
        
        // Speak the other language with slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let utt2 = AVSpeechUtterance(string: text)
            utt2.voice = AVSpeechSynthesisVoice(language: useHungarian ? "en-US" : "hu-HU")
            utt2.rate = useHungarian ? 0.40 : 0.35
            utt2.pitchMultiplier = useHungarian ? 0.85 : 0.75
            utt2.volume = 0.7
            BabilonApp.speech.speak(utt2)
        }
    }
    
    func startCamera() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else { return }
        captureSession.addInput(input)
        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           captureSession.canAddInput(micInput) {
            captureSession.addInput(micInput)
        }
        let cs = captureSession
        DispatchQueue.global(qos: .userInitiated).async { cs.startRunning() }
        session = captureSession
        
        // Dog + eye detection — ML model placeholder
        Task { @MainActor in
            while true {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                dogConfidence = Float.random(in: 0.3...0.95)
                dogDetected = dogConfidence > 0.5
                eyeDetected = dogDetected && Float.random(in: 0...1) > 0.4
                if eyeDetected {
                    let eyeX = Int.random(in: 0...255)
                    let eyeY = Int.random(in: 0...255)
                    dogEyeSeed = "_EYE_\(eyeX)x\(eyeY)"
                } else {
                    dogEyeSeed = ""
                }
                if dogDetected && !translator.isListening {
                    translator.isListening = true; translator.startListening()
                }
            }
        }
    }
    
    // Live waveform animation — ternary bars driven by translator
    func startWaveAnimation() {
        Task { @MainActor in
            while true {
                try? await Task.sleep(nanoseconds: 100_000_000)
                let tern = translator.ternarityMatrix.flatMap { $0 }
                let conf = translator.confidence
                wavePhases = tern.enumerated().map { i, t in
                    let base = Float(t) * conf
                    let jitter = Float.random(in: -0.2...0.2)
                    let wave = sin(Float(i) * 0.7 + Float(DispatchTime.now().uptimeNanoseconds) / 800_000_000)
                    return base + jitter + wave * 0.15
                }
                if tern.isEmpty {
                    wavePhases = (0..<16).map { i in
                        sin(Float(i) * 0.6 + Float.random(in: -0.5...0.5)) * conf * 0.8
                    }
                }
                // Calm wave animation
                let now = DispatchTime.now().uptimeNanoseconds
                calmWavePhase = Double(now) / 3_000_000_000
            }
        }
    }
}

// BABYLON-ultra-dict — 16-bar ternary waveform
struct QuantWaveView: View {
    let phases: [Float]
    let confidence: Float
    
    var body: some View {
        Canvas { context, size in
            let barW = size.width / CGFloat(phases.count)
            let midY = size.height / 2
            let maxH = size.height * 0.45
            
            // Glow background
            context.fill(
                Path(ellipseIn: CGRect(x: size.width * 0.1, y: midY - 4, width: size.width * 0.8, height: 8)),
                with: .color(.cyan.opacity(0.08))
            )
            
            for (i, phase) in phases.enumerated() {
                let height = CGFloat(abs(phase)) * maxH
                let x = CGFloat(i) * barW + barW * 0.15
                let y = midY - height
                let rect = CGRect(x: x, y: y, width: barW * 0.7, height: height * 2)
                
                // Ternarity color: +1=green, 0=cyan, -1=red
                let color: Color = phase > 0.1 ? .green.opacity(0.7) :
                                    phase < -0.1 ? .orange.opacity(0.7) :
                                    .cyan.opacity(0.5)
                
                let bar = Path(roundedRect: rect, cornerRadius: 2)
                context.fill(bar, with: .color(color))
                
                // Glow bar
                if abs(phase) > 0.3 {
                    let glowRect = CGRect(x: x, y: y - 2, width: barW * 0.7, height: height * 2 + 4)
                    let glow = Path(roundedRect: glowRect, cornerRadius: 2)
                    context.fill(glow, with: .color(color.opacity(0.3)))
                }
            }
            
            // Confidence ring
            let ringRadius: CGFloat = 12
            let ringRect = CGRect(x: size.width - 30, y: 10, width: ringRadius * 2, height: ringRadius * 2)
            let ringPath = Path(ellipseIn: ringRect)
            context.stroke(ringPath, with: .color(.cyan.opacity(0.5)), lineWidth: 2)
            context.fill(Path(ellipseIn: ringRect.insetBy(dx: 4, dy: 4)), with: .color(.green.opacity(Double(confidence))))
            
            // Confidence text
            let text = Text("\(Int(confidence * 100))%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.cyan.opacity(0.7))
            context.draw(text, at: CGPoint(x: size.width - 42, y: size.height - 10))
        }
    }
}

struct CameraPreview: NSViewRepresentable {
    @Binding var session: AVCaptureSession?
    func makeNSView(context: Context) -> NSView {
        let v = NSView(); v.wantsLayer = true; v.layer?.backgroundColor = NSColor.black.cgColor
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let s = session, s.isRunning else { return }
        if nsView.layer?.sublayers?.first is AVCaptureVideoPreviewLayer {
            (nsView.layer!.sublayers!.first as! AVCaptureVideoPreviewLayer).frame = nsView.bounds
        } else {
            let p = AVCaptureVideoPreviewLayer(session: s)
            p.videoGravity = .resizeAspectFill; p.frame = nsView.bounds
            p.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            nsView.layer?.addSublayer(p)
        }
    }
}

struct SelfieMirror: NSViewRepresentable {
    @Binding var session: AVCaptureSession?
    func makeNSView(context: Context) -> NSView {
        let v = NSView(); v.wantsLayer = true; v.layer?.cornerRadius = 20; v.layer?.masksToBounds = true; v.layer?.backgroundColor = NSColor.black.cgColor
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let s = session, s.isRunning else { return }
        if nsView.layer?.sublayers?.first is AVCaptureVideoPreviewLayer {
            (nsView.layer!.sublayers!.first as! AVCaptureVideoPreviewLayer).frame = nsView.bounds
        } else {
            let p = AVCaptureVideoPreviewLayer(session: s)
            p.videoGravity = .resizeAspectFill; p.frame = nsView.bounds
            p.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            p.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
            nsView.layer?.addSublayer(p)
        }
    }
}

// Calming waves — radiating toward the dog in calm states
struct CalmWavesView: View {
    let phase: Double
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.82, y: size.height * 0.25)
                let maxRadius = size.width * 0.7
                
                for i in 0..<5 {
                    let radius = (phase.truncatingRemainder(dividingBy: 1.0) + Double(i) * 0.2)
                        .truncatingRemainder(dividingBy: 1.0) * maxRadius
                    let opacity = 0.15 - (radius / maxRadius) * 0.12
                    let path = Path(ellipseIn: CGRect(
                        x: center.x - radius,
                        y: center.y - radius * 0.3,
                        width: radius * 2,
                        height: radius * 0.6
                    ))
                    context.stroke(path, with: .color(.cyan.opacity(opacity)), lineWidth: 1.5)
                }
                
                // Gentle sine wave lines
                for i in 0..<6 {
                    let offset = phase * 60 + Double(i) * 30
                    let path = Path { p in
                        p.move(to: CGPoint(x: 0, y: center.y + sin(offset * 0.05) * 20))
                        for x in stride(from: 0, through: size.width, by: 2) {
                            let y = center.y + sin((x + offset) * 0.02) * 15 + sin((x * 0.7 + offset) * 0.03) * 8
                            p.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    context.stroke(path, with: .color(.cyan.opacity(0.06 - Double(i) * 0.008)), lineWidth: 1)
                }
            }
        }
    }
}

// Quant baby drift: adult word → baby-talk phoneme cascade
extension String {
    func babyDrift(prng: inout Xoshiro128StarStar, hash: Float) -> String {
        let lower = self.lowercased()
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        let babyMap: [Character: String] = [
            "r": "w", "l": "y", "s": "sh", "t": "tch", "k": "k", "p": "b",
            "b": "b", "v": "b", "f": "ff", "c": "k", "g": "g", "d": "d",
            "m": "m", "n": "n", "h": "h", "w": "w", "j": "y", "z": "z",
        ]
        var out = ""
        var lastChar: Character = "\0"
        var jit = prng.next()
        for c in lower {
            let drift = Int((jit * hash * 7).truncatingRemainder(dividingBy: 3))
            jit = prng.next()
            guard out.count < 8 else { break }
            if vowels.contains(c) {
                if drift == 0 && lastChar != c { out.append(c); out.append(c) }
                else if lastChar != c { out.append(c) }
                lastChar = c
            } else if let baby = babyMap[c] {
                if drift == 2 { continue }
                if out.hasSuffix(baby) { continue }
                out += baby
                lastChar = c
            } else {
                out.append(c)
                lastChar = c
            }
        }
        return out.isEmpty ? "mm" : out
    }
}
