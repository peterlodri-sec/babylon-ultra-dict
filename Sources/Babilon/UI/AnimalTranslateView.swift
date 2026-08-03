import SwiftUI

struct AnimalTranslateView: View {
    @State private var translator = AnimalTranslator()
    @State private var isListening = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🐾 Quant-Animal-Translate")
                .font(.title)
            
            Picker("Select Animal", selection: $translator.selectedSpecies) {
                ForEach(AnimalSpecies.allCases, id: \.self) { species in
                    Text(species.rawValue).tag(species)
                }
            }
            .pickerStyle(.menu)
            
            // Listening indicator
            ZStack {
                Circle()
                    .stroke(isListening ? Color.green : Color.gray, lineWidth: 3)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isListening ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isListening)
                
                Text(isListening ? "🎙️" : "⏺️")
                    .font(.system(size: 40))
            }
            
            Button(isListening ? "Stop Listening" : "Start Listening") {
                isListening.toggle()
                if isListening { translator.startListening() } else { translator.stopListening() }
            }
            .buttonStyle(.borderedProminent)
            .tint(isListening ? .red : .cyan)
            
            // Detected vocalization
            if let vocal = translator.detectedVocalization, isListening {
                VStack {
                    Text("Detected:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(vocal.rawValue)
                        .font(.headline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            
            // Translation
            if !translator.translation.isEmpty {
                VStack {
                    Text("Translation:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(translator.translation)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Text("Confidence: \(Int(translator.confidence * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            
            // Ternarity Matrix Visualization
            if !translator.ternarityVisualization.isEmpty {
                VStack {
                    Text("{-1,0,+1} Matrix")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    ForEach(translator.ternarityVisualization.indices, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(translator.ternarityVisualization[row].indices, id: \.self) { col in
                                let val = translator.ternarityVisualization[row][col]
                                Text("\(val)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(val == 1 ? .green : val == -1 ? .red : .gray)
                                    .frame(width: 20, height: 20)
                                    .background(val == 1 ? Color.green.opacity(0.2) : val == -1 ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}
