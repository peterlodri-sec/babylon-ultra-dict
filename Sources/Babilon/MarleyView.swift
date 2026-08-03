import SwiftUI
@preconcurrency import AVFoundation

struct MarleyView: View {
    @Environment(MarleyTranslator.self) private var translator
    @State private var session: AVCaptureSession?
    @State private var thinkingProgress: Double = 0.0
    @State private var showTranslation: Bool = false
    @State private var thinkingTimer: Task<Void, Never>?
    @State private var dogDetected: Bool = false
    @State private var dogConfidence: Float = 0.0
    @State private var dogEyeSeed: String = ""
    @State private var eyeDetected: Bool = false
    @State private var dynamicSeed = DynamicSeed()
    
    var body: some View {
        ZStack {
            // Live camera — always on
            CameraPreview(session: $session)
                .ignoresSafeArea()
            
            // CUKI KUTYA label — bottom left
            VStack {
                Spacer()
                HStack {
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
                                    Text("eyes")
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundStyle(.yellow.opacity(0.7))
                                }
                            }
                        }
                    }
                    .padding(.leading, 24).padding(.bottom, 140)
                    Spacer()
                }
            }
            
            // Selfie mirror — top right
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        SelfieMirror(session: $session)
                            .frame(width: 256, height: 256)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.3), lineWidth: 1.5))
                            .shadow(color: .cyan.opacity(0.2), radius: 12)
                        VStack {
                            Spacer()
                            Text("KAMERA")
                                .font(.system(size: 22, design: .monospaced)).fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.bottom, 6)
                        }
                    }
                    .padding(.top, 48).padding(.trailing, 16)
                }
                Spacer()
            }
            
            // Live translation overlay — always visible
            VStack {
                Spacer()
                
                // Thinking → Translation stream
                VStack(spacing: 6) {
                    // Thinking ring
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 2).frame(width: 36, height: 36)
                            Circle()
                                .trim(from: 0, to: thinkingProgress)
                                .stroke(thinkingProgress >= 1.0 ? Color.green : Color.cyan, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .frame(width: 36, height: 36).rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: thinkingProgress)
                            Text("ॐ").font(.system(size: 16, design: .serif))
                                .foregroundStyle(thinkingProgress >= 1.0 ? Color.green.opacity(0.6) : Color.cyan.opacity(0.4))
                        }
                        Text("live translation")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.5))
                    }
                    
                    // Translation text
                    if showTranslation && !translator.translation.isEmpty {
                        VStack(spacing: 3) {
                            Text(translator.translation)
                                .font(.system(size: 28))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            HStack(spacing: 4) {
                                Text(translator.detectedSound)
                                    .font(.system(size: 18, design: .monospaced))
                                    .foregroundStyle(.cyan)
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.green.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.bottom, 20)
                
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
    func startContinuousTranslation() {
        thinkingProgress = 0; showTranslation = false
        thinkingTimer?.cancel()
        thinkingTimer = Task { @MainActor in
            while translator.isListening {
                // Variable delay: 1-3 seconds between translations
                let delay = UInt64((1_000_000_000...3_000_000_000).randomElement()!)
                try? await Task.sleep(nanoseconds: delay)
                guard translator.isListening else { break }
                
                // Quick think animation (0.5s)
                thinkingProgress = 0
                for _ in 0..<12 {
                    try? await Task.sleep(nanoseconds: 42_000_000)
                    thinkingProgress += 0.083
                }
                
                // Speak translation
                showTranslation = true
                speakTranslation(translator.translation, seed: dynamicSeed.seed + dogEyeSeed)
                
                // Hold display for 2s
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if translator.isListening { thinkingProgress = 0; showTranslation = false }
            }
        }
    }
    
    func speakTranslation(_ text: String, seed: String = "OM MANI PADME HUNG") {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        // Dynamic rate based on seed hash
        let seedHash = abs(seed.hashValue % 100)
        utterance.rate = 0.38 + Float(seedHash) / 500.0       // 0.38–0.58
        utterance.pitchMultiplier = 0.8 + Float(seedHash) / 1000.0 // 0.8–1.0
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
                // Dog eye as seed modifier
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
