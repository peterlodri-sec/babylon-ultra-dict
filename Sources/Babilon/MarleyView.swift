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
    
    // Marley's 16-dim ternarity matrix — OM MANI PADME HUNG
    let marleyTernary: [Float] = [1, 0, -1, 1, 0, -1, 1, 0, -1, 1, 0, -1, 1, 0, -1, 1]

    var body: some View {
        ZStack {
            CameraPreview(session: $session)
            Rectangle().fill(.black.opacity(0.55))
            SelfieMirror(session: $session)
            
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("CUKI KUTYA")
                        .font(.system(size: 28, design: .monospaced)).fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.5), radius: 4)
                    if dogDetected {
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("dog · \(Int(dogConfidence * 100))%")
                                .font(.system(size: 16, design: .monospaced))
                                .foregroundStyle(.green.opacity(0.7))
                            if eyeDetected {
                                Circle().fill(Color.yellow).frame(width: 6, height: 6)
                                Text("eyes · \(dogEyeSeed.dropFirst(5))")
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundStyle(.yellow.opacity(0.7))
                            }
                        }
                    }
                }
                .padding(.leading, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                
                if showTranslation {
                    VStack(spacing: 6) {
                        Text(translator.translation)
                            .font(.system(size: 18, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .transition(.opacity)
                    .padding(.bottom, 20)
                }
                
                // OM MANI PADME HUNG footer + dynamic seed
                VStack(spacing: 2) {
                    Text(dynamicSeed.seed)
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.4))
                        .lineLimit(1)
                    Text("🎵 \(dynamicSeed.track)")
                        .font(.system(size: 6, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.2))
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
                let translation = makeQuantTranslation(
                    sound: translator.detectedSound,
                    meaning: translator.translation,
                    seed: combinedSeed
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
    func makeQuantTranslation(sound: String, meaning: String, seed: String) -> String {
        var prng = Xoshiro128StarStar(seedString: seed + sound + meaning)
        
        let words = meaning.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty && $0.count > 1 }
        
        let sl = sound.lowercased()
        let soundBabble: [String]
        if sl.contains("woof") || sl.contains("bark") { soundBabble = ["brrr", "grrr", "woof", "awoo"] }
        else if sl.contains("whine") || sl.contains("hungry") { soundBabble = ["nnng", "wah", "mmm", "baba"] }
        else if sl.contains("growl") || sl.contains("alert") { soundBabble = ["grrr", "gah", "gaga", "brrr"] }
        else if sl.contains("happy") { soundBabble = ["baba", "goo", "ooo", "mama"] }
        else { soundBabble = ["gaga", "goo", "wah", "brrr", "mmm", "baba", "mama", "ooo", "grrr", "awoo", "nnng", "gah"] }
        
        let feelings = ["safe", "watch", "quiet", "sleep", "guard", "love", "happy", "alert", "play", "home", "stay", "protect", "food", "warm"]
        
        let b1 = soundBabble[Int(prng.next() * Float(soundBabble.count)) % soundBabble.count]
        let feeling = feelings[Int(prng.next() * Float(feelings.count)) % feelings.count]
        
        let fragments = words.enumerated().compactMap { i, word -> String? in
            guard (i % 2) == 1, word.count >= 2 else { return nil }
            let hash = Float(abs(word.hashValue) % 100) / 100.0
            return word.babyDrift(prng: &prng, hash: hash)
        }
        let mid = fragments.isEmpty ? b1 : fragments.joined(separator: "… ")
        return "\(b1)… \(mid) …\(feeling)."
    }
    
    // Random baby coo/babble before TTS
    func playBabySound() {
        let babble = ["goo", "gah", "baba", "mama", "brrr", "wah", "mmm", "ooo"]
        let picked = babble.randomElement()!
        let utterance = AVSpeechUtterance(string: picked)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.25
        utterance.pitchMultiplier = 1.3
        utterance.volume = 0.4
        BabilonApp.speech.speak(utterance)
    }
    
    func speakTranslation(_ text: String, seed: String = "OM MANI PADME HUNG") {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let seedHash = abs(seed.hashValue % 100)
        utterance.rate = 0.38 + Float(seedHash) / 500.0
        utterance.pitchMultiplier = 0.8 + Float(seedHash) / 1000.0
        utterance.volume = 0.8
        BabilonApp.speech.speak(utterance)
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
