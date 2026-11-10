import Foundation
import NaturalLanguage
import PDFKit

struct SearchResult: Identifiable, Sendable {
    let id: String
    let title: String
    let snippet: String
    let score: Double
    let isDemo: Bool
}

struct EngineStatus: Sendable {
    let documentCount: Int
    let usesSemanticEmbedding: Bool
    let detail: String
}

actor SearchEngine {
    private let index = PKSearchIndex()
    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)
    private var demoPaths = Set<String>()

    private var usesSemanticEmbedding: Bool { embedding != nil }

    // If the Apple sentence embedding isn't available on this Mac, fall back to
    // deterministic lexical feature hashing. This mode is NOT semantic AI.
    private func vector(for text: String) -> [NSNumber] {
        if let embedding, let values = embedding.vector(for: text) {
            return values.map { NSNumber(value: $0) }
        }
        var values = [Double](repeating: 0, count: 256)
        let words = text.lowercased().split { !$0.isLetter && !$0.isNumber }
        for word in words {
            var hash: UInt64 = 14_695_981_039_346_656_037
            for byte in word.utf8 { hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211 }
            values[Int(hash % 256)] += 1
        }
        return values.map { NSNumber(value: $0) }
    }

    private func status() -> EngineStatus {
        EngineStatus(documentCount: index.documentCount,
                     usesSemanticEmbedding: usesSemanticEmbedding,
                     detail: usesSemanticEmbedding
                        ? "Apple NaturalLanguage sentence embeddings · on-device"
                        : "Lexical fallback · Apple sentence model unavailable")
    }

    func loadDemo() -> EngineStatus {
        index.removeAllDocuments()
        demoPaths.removeAll()
        let samples: [(String, String)] = [
            ("Neural Networks", "Neural networks learn patterns from examples using weighted layers. Training uses backpropagation, gradient descent, and labeled data to reduce prediction error."),
            ("Vacation Planning", "Our summer vacation includes hiking in national parks, choosing a cabin near the mountains, and planning a scenic road trip."),
            ("Project Meeting", "We discussed the machine learning prototype at our engineering meeting. The team agreed to test model accuracy and improve inference latency."),
            ("Recipe Notes", "For dinner, cook pasta with roasted tomatoes, garlic, olive oil, basil, and parmesan cheese. Serve with fresh salad."),
            ("Security Checklist", "Protect sensitive customer files using encryption, access controls, private local storage, and minimal network permissions."),
            ("Performance Testing", "Benchmark CPU usage, memory allocation, response time, and search throughput. Use Instruments to find slow code and measure improvements."),
            ("Space Research", "Astronomers study distant galaxies, planets around other stars, and how gravity influences the universe."),
            ("Developer Documentation", "Swift and Objective-C interoperability allows modern code to call mature Cocoa APIs and legacy modules through a bridging header.")
        ]
        for (i, sample) in samples.enumerated() {
            let path = "demo://\(i)"
            demoPaths.insert(path)
            index.addDocument(withTitle: sample.0, path: path, snippet: sample.1,
                              vector: vector(for: sample.0 + ". " + sample.1))
        }
        return status()
    }

    func loadFolder(_ folder: URL) throws -> EngineStatus {
        let allowed = Set(["txt", "md", "markdown", "swift", "m", "h", "json", "csv", "pdf"])
        guard let walker = FileManager.default.enumerator(at: folder,
             includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
             options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            throw NSError(domain: "NeuralSearch", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not read the selected folder."])
        }
        index.removeAllDocuments()
        demoPaths.removeAll()
        var processed = 0
        for case let url as URL in walker {
            if processed >= 300 { break }
            guard allowed.contains(url.pathExtension.lowercased()),
                  let attrs = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  attrs.isRegularFile == true,
                  (attrs.fileSize ?? 0) < 2_000_000 else { continue }
            let content: String?
            if url.pathExtension.lowercased() == "pdf" {
                content = PDFDocument(url: url)?.string
            } else {
                content = try? String(contentsOf: url, encoding: .utf8)
            }
            guard let text = content?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { continue }
            let excerpt = String(text.prefix(1100))
            index.addDocument(withTitle: url.lastPathComponent, path: url.path,
                              snippet: excerpt,
                              vector: vector(for: url.lastPathComponent + ". " + String(text.prefix(4500))))
            processed += 1
        }
        return status()
    }

    func search(_ query: String) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return index.search(withVector: vector(for: trimmed), limit: 25).map { hit in
            SearchResult(id: hit.path, title: hit.title, snippet: hit.snippet,
                         score: hit.score, isDemo: demoPaths.contains(hit.path))
        }
    }
}
