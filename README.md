# BABILON

📱 **Sovereign Video App** — iOS + macOS · On-Device · Zero Cloud

Take pictures. Record video. QUANT voice generation. Animal translation.
Powered by MLX-QUANT Metal kernels. All processing on-device. No server. No API key.

## Features

- 📸 **Camera**: AVFoundation native, 4K60, HDR
- 🐾 **Quant-Animal-Translate**: Real-time animal vocalization → human language via MLX-QUANT ternary inference
- 🎙️ **QUANT VoiceGen**: Ternary-quantized TTS on-device
- 🎨 **{-1,0,+1} Filters**: Real-time ternary matrix frame quantization
- 🧠 **MEM8 Wave Memory**: On-device wave interference media recall
- 🔐 **Honesty-Auth**: 17-field personality vector, no passwords

## Architecture

```
SwiftUI App
├── Features/
│   ├── Camera.swift          — AVFoundation capture pipeline
│   ├── AnimalTranslator.swift — Real-time animal vocalization translation
│   ├── VoiceGen.swift        — MLX-QUANT TTS engine
│   ├── TernarityFilter.swift — {-1,0,+1} real-time quantizer
│   └── QuickCapture.swift    — MenuBarExtra (macOS)
├── Services/
│   ├── MLXClient.swift       — MLX-QUANT Metal kernel bridge
│   ├── AyeosClient.swift     — MEMNET protocol (:9876)
│   ├── HonestAuth.swift      — 17-field personality vector
│   └── MEM8Client.swift      — Wave memory recall
├── UI/
│   ├── ContentView.swift     — TabView main interface
│   ├── AnimalView.swift      — Animal translate UI
│   ├── CameraView.swift      — Camera + filter overlay
│   └── LibraryView.swift     — Media library browser
└── Resources/
    ├── Info.plist
    └── Babilon.entitlements
```

## Stack

- SwiftUI + AVFoundation
- [MLX-QUANT](https://github.com/8b-is/MLX-QUANT) — Metal GPU kernels
- [ayeOS](https://github.com/8b-is/ayeos) — MEMNET ternary daemon
- [entheai](https://github.com/entropy-om/entheai) — Recursive agent
- [honest-irc](https://github.com/8b-is/honest-irc) — Honesty-auth
- [hf-mac](https://github.com/8b-is/hf-mac) — Model pulling
- [kokoro-tiny](https://github.com/8b-is/kokoro-tiny) — TTS engine

## License

Apache 2.0 · ALL OSS FREE FOR ALL · 🇭🇺 MADE IN HUNGARY

## Status

v0.1.0 — Scaffolded · Building soon
