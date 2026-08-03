import SwiftUI

@main
struct BabilonApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
        #if os(macOS)
        MenuBarExtra("Babilon", systemImage: "camera.fill") {
            QuickCaptureView()
                .environment(appState)
        }
        #endif
    }
}

@Observable
class AppState {
    var currentTab: Tab = .camera
    var isRecording = false
    var selectedAnimal: AnimalSpecies = .dog
    var translatedText: String = ""
    var voiceOutput: String = ""
    var ternarityFilter: TernarityLevel = .full
    
    enum Tab: String, CaseIterable {
        case camera = "📸 Camera"
        case animal = "🐾 Animal Translate"
        case library = "📚 Library"
        case voice = "🎙️ VoiceGen"
        case settings = "⚙️ Settings"
    }
}

enum TernarityLevel: String, CaseIterable {
    case full = "{-1,0,+1} Full"
    case binary = "Binary Only"
    case raw = "Raw Feed"
}
