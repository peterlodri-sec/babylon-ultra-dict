import SwiftUI

struct VoiceGenView: View {
    @State private var textInput = ""
    @State private var generatedAudio = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🎙️ QUANT VoiceGen")
                .font(.title)
            Text("MLX-QUANT TTS · On-Device · Zero Cloud")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $textInput)
                .frame(height: 120)
                .border(.secondary)
                .padding()
            
            HStack {
                Button("Generate Voice") {
                    generatedAudio = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(textInput.isEmpty)
                
                if generatedAudio {
                    Button("▶️ Play") {}
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}
