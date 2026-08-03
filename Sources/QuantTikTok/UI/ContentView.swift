import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    
    var body: some View {
        TabView(selection: Binding(get: { state.currentTab }, set: { state.currentTab = $0 })) {
            CameraView()
                .tabItem { Label("Camera", systemImage: "camera.fill") }
                .tag(AppState.Tab.camera)
            
            AnimalTranslateView()
                .tabItem { Label("Animal", systemImage: "pawprint.fill") }
                .tag(AppState.Tab.animal)
            
            MediaLibraryView()
                .tabItem { Label("Library", systemImage: "photo.stack") }
                .tag(AppState.Tab.library)
            
            VoiceGenView()
                .tabItem { Label("Voice", systemImage: "waveform") }
                .tag(AppState.Tab.voice)
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(AppState.Tab.settings)
        }
    }
}

struct CameraView: View {
    var body: some View {
        VStack {
            Text("📸 Camera")
                .font(.title)
            Text("AVFoundation · 4K60 · HDR")
                .foregroundStyle(.secondary)
            Text("{-1,0,+1} Ternarity Filter Active")
                .font(.caption)
                .foregroundStyle(.cyan)
        }
    }
}

struct MediaLibraryView: View {
    var body: some View {
        VStack {
            Text("📚 Media Library")
                .font(.title)
            Text("MEM8 Wave Memory · On-Device")
                .foregroundStyle(.secondary)
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var state
    
    var body: some View {
        VStack {
            Text("⚙️ Settings")
                .font(.title)
            Picker("Ternarity Filter", selection: Binding(get: { state.ternarityFilter }, set: { state.ternarityFilter = $0 })) {
                ForEach(TernarityLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .padding()
        }
    }
}

struct QuickCaptureView: View {
    var body: some View {
        VStack {
            Text("QuantTikTok")
                .font(.headline)
            Button("Quick Capture") {}
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
