import SwiftUI
import AVFoundation

struct MarleyView: View {
    @Environment(MarleyTranslator.self) private var translator
    @State private var isListening = false
    @State private var session: AVCaptureSession?
    
    var body: some View {
        ZStack {
            // Front-facing camera preview
            CameraPreview(session: $session)
                .ignoresSafeArea()
            
            // Ternarity overlay at bottom
            VStack {
                Spacer()
                
                // {-1,0,+1} matrix display
                if !translator.ternarityMatrix.isEmpty {
                    VStack(spacing: 2) {
                        Text("MARLEY · {-1,0,+1}")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.6))
                        ForEach(translator.ternarityMatrix.indices, id: \.self) { row in
                            HStack(spacing: 2) {
                                ForEach(translator.ternarityMatrix[row].indices, id: \.self) { col in
                                    let val = translator.ternarityMatrix[row][col]
                                    Circle()
                                        .fill(val == 1 ? Color.green : val == -1 ? Color.red : Color.gray.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .cornerRadius(12)
                }
                
                // Translation display
                if !translator.translation.isEmpty {
                    VStack(spacing: 4) {
                        Text(translator.detectedSound)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.cyan)
                        Text(translator.translation)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Listen button
                Button(action: {
                    isListening.toggle()
                    if isListening {
                        translator.startListening()
                        startCamera()
                    } else {
                        translator.stopListening()
                        session?.stopRunning()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isListening ? Color.red.opacity(0.8) : Color.cyan.opacity(0.8))
                            .frame(width: 72, height: 72)
                            .shadow(color: isListening ? .red.opacity(0.5) : .cyan.opacity(0.5), radius: 20)
                        
                        if isListening {
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .scaleEffect(isListening ? 1.2 : 1.0)
                                .opacity(isListening ? 0.5 : 0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isListening)
                        }
                        
                        Image(systemName: isListening ? "pawprint.fill" : "pawprint")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 40)
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
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
