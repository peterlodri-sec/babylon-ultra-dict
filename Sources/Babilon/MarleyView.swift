import SwiftUI
import AVFoundation

struct MarleyView: View {
    @Environment(MarleyTranslator.self) private var translator
    @State private var session: AVCaptureSession?
    @State private var thinkingProgress: Double = 0.0
    @State private var showTranslation: Bool = false
    @State private var thinkingTimer: Timer?
    
    var body: some View {
        ZStack {
            // Front-facing camera preview
            CameraPreview(session: $session)
                .ignoresSafeArea()
            
            // Selfie mirror — top right
            VStack {
                HStack {
                    Spacer()
                    SelfieMirror(session: $session)
                        .frame(width: 80, height: 120)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                        .shadow(color: .cyan.opacity(0.15), radius: 8)
                        .padding(.top, 48).padding(.trailing, 16)
                }
                Spacer()
            }
            
            // THINKING STATE — visible delay indicator
            VStack {
                Spacer()
                
                // Thinking ring — shows MLX-QUANT computation
                if translator.isListening {
                    VStack(spacing: 4) {
                        Text(thinkingProgress >= 1.0 ? "translated" : "thinking...")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundStyle(thinkingProgress >= 1.0 ? Color.green.opacity(0.6) : Color.cyan.opacity(0.4))
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 2)
                                .frame(width: 52, height: 52)
                            Circle()
                                .trim(from: 0, to: thinkingProgress)
                                .stroke(
                                    thinkingProgress >= 1.0 ? Color.green : Color.cyan,
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                )
                                .frame(width: 52, height: 52)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: thinkingProgress)
                            
                            // OM MANI PADME HUM seed indicator
                            Text("ॐ")
                                .font(.system(size: 12, design: .serif))
                                .foregroundStyle(thinkingProgress >= 1.0 ? Color.green.opacity(0.6) : Color.cyan.opacity(0.4))
                        }
                        
                        Text("OM MANI PADME HUNG")
                            .font(.system(size: 5, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.3))
                    }
                    .padding(.bottom, 8)
                }
                
                // {-1,0,+1} matrix — always visible while listening
                if translator.isListening && !translator.ternarityMatrix.isEmpty {
                    VStack(spacing: 2) {
                        Text("MARLEY · {-1,0,+1}")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.5))
                        ForEach(translator.ternarityMatrix.indices, id: \.self) { row in
                            HStack(spacing: 2) {
                                ForEach(translator.ternarityMatrix[row].indices, id: \.self) { col in
                                    let val = translator.ternarityMatrix[row][col]
                                    Circle()
                                        .fill(val == 1 ? Color.green : val == -1 ? Color.red : Color.gray.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                    .padding(6)
                    .background(.ultraThinMaterial.opacity(0.4))
                    .cornerRadius(10)
                }
                
                // DELAYED TRANSLATION — appears after thinking completes
                if showTranslation && !translator.translation.isEmpty {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text(translator.detectedSound)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.cyan)
                        }
                        Text(translator.translation)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.6), value: showTranslation)
                }
                
                // Always-on paw button
                Button(action: {
                    translator.isListening.toggle()
                    if translator.isListening {
                        translator.startListening()
                        startCamera()
                        startThinkingCycle()
                    } else {
                        translator.stopListening()
                        session?.stopRunning()
                        thinkingTimer?.invalidate()
                        showTranslation = false
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(translator.isListening ? Color.red.opacity(0.7) : Color.cyan.opacity(0.7))
                            .frame(width: 64, height: 64)
                            .shadow(color: translator.isListening ? .red.opacity(0.4) : .cyan.opacity(0.4), radius: 16)
                        
                        if translator.isListening {
                            Circle()
                                .stroke(Color.red, lineWidth: 1.5)
                                .frame(width: 72, height: 72)
                                .scaleEffect(1.15)
                                .opacity(0.4)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: translator.isListening)
                        }
                        
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            translator.isListening = true
            translator.startListening()
            startCamera()
            startThinkingCycle()
        }
    }
    
    // Thinking cycle: simulate MLX-QUANT processing delay
    func startThinkingCycle() {
        thinkingProgress = 0
        showTranslation = false
        thinkingTimer?.invalidate()
        
        thinkingTimer = Timer.scheduledTimer(withTimeInterval: 0.042, repeats: true) { timer in
            guard translator.isListening else {
                timer.invalidate()
                return
            }
            
            // Slow progress toward 1.0 (thinking)
            if thinkingProgress < 1.0 {
                thinkingProgress += 0.025 // ~1.68s to complete
            } else if !showTranslation {
                // Translation ready — show it
                showTranslation = true
                
                // Hold translation for 3 seconds, then reset thinking
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if translator.isListening {
                        thinkingProgress = 0
                        showTranslation = false
                    }
                }
            }
        }
    }
    
    func startCamera() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .low
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else { return }
        captureSession.addInput(input)
        DispatchQueue.global(qos: .userInitiated).async { captureSession.startRunning() }
        session = captureSession
    }
}

struct CameraPreview: NSViewRepresentable {
    @Binding var session: AVCaptureSession?
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct SelfieMirror: NSViewRepresentable {
    @Binding var session: AVCaptureSession?
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        view.layer?.cornerRadius = 12
        let label = NSTextField(labelWithString: "marley sees you")
        label.font = NSFont.monospacedSystemFont(ofSize: 5, weight: .regular)
        label.textColor = NSColor.systemGray
        label.frame = NSRect(x: 4, y: 4, width: 72, height: 8)
        view.addSubview(label)
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
