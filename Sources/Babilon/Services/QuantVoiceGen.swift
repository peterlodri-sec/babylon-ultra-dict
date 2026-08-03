import Foundation

// Xoshiro128** — deterministic PRNG from LINOSV seed
// Used by MarleyTranslator for {-1,0,+1} ternary embedding
// OM MANI PADME HUNG is the base seed
struct Xoshiro128StarStar {
    private var s: [UInt32]
    
    init(seed: UInt32) {
        var state = seed
        s = [UInt32](repeating: 0, count: 4)
        for i in 0..<4 {
            state = state &+ 0x9E3779B9
            var z = state; z = (z ^ (z >> 16)) &* 0x21f0aaad; z = (z ^ (z >> 15)) &* 0x735a2d97; z = z ^ (z >> 15)
            s[i] = z
        }
    }
    
    init(seedData: Data) {
        let hash = seedData.reduce(0) { $0 &+ UInt32($1) }
        self.init(seed: hash)
    }
    
    init(seedString: String) {
        self.init(seedData: seedString.data(using: .utf8) ?? Data())
    }
    
    mutating func next() -> Float {
        let result = rotl(s[1] &* 5, 7) &* 9
        let t = s[1] << 9
        s[2] ^= s[0]; s[3] ^= s[1]; s[1] ^= s[2]; s[0] ^= s[3]; s[2] ^= t
        s[3] = rotl(s[3], 11)
        return Float(result) / Float(UInt32.max)
    }
    
    private func rotl(_ x: UInt32, _ k: UInt32) -> UInt32 { (x << k) | (x >> (32 - k)) }
}
