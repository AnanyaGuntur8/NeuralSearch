import SwiftUI
import AppKit

@main
struct NeuralSearchApp: App {
    var body: some Scene {
        WindowGroup("NeuralSearch") {
            ContentView()
                .frame(minWidth: 760, minHeight: 560)
        }
        .windowStyle(.titleBar)
    }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = "find where we discussed machine learning"
    @Published var results: [SearchResult] = []
    @Published var documentCount = 0
    @Published var engineDetail = "Starting local search…"
    @Published var semantic = false
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var sourceName = "Demo documents"

    private let engine = SearchEngine()
    private var revision = 0

    func loadDemo() async {
        isBusy = true
        let status = await engine.loadDemo()
        apply(status)
        sourceName = "Demo documents"
        isBusy = false
        await search()
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Index Folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await loadFolder(url) }
    }

    private func loadFolder(_ url: URL) async {
        isBusy = true
        errorMessage = nil
        do {
            let status = try await engine.loadFolder(url)
            apply(status)
            sourceName = url.lastPathComponent
            await search()
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    func search() async {
        revision += 1
        let currentRevision = revision
        let found = await engine.search(query)
        if revision == currentRevision { results = found }
    }

    func open(_ result: SearchResult) {
        guard !result.isDemo else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: result.id))
    }

    private func apply(_ status: EngineStatus) {
        documentCount = status.documentCount
        semantic = status.usesSemanticEmbedding
        engineDetail = status.detail
    }
}

struct ContentView: View {
    @StateObject private var model = SearchViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 34)).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("NeuralSearch").font(.largeTitle.bold())
                    Text("A local Swift + Objective-C search engine")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Demo Data") { Task { await model.loadDemo() } }
                Button("Index Folder…") { model.chooseFolder() }
                    .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search by meaning, not just keywords", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit { Task { await model.search() } }
                Button("Search") { Task { await model.search() } }
                    .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Label("\(model.documentCount) documents · \(model.sourceName)", systemImage: "doc.text")
                Spacer()
                Image(systemName: model.semantic ? "checkmark.shield.fill" : "exclamationmark.triangle")
                    .foregroundStyle(model.semantic ? .green : .orange)
                Text(model.engineDetail)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if model.isBusy { ProgressView().frame(maxWidth: .infinity) }
            if let error = model.errorMessage {
                Text(error).foregroundStyle(.red)
            }
            Text("SEARCH RESULTS")
                .font(.caption.bold()).foregroundStyle(.secondary)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 11) {
                    ForEach(model.results) { hit in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(hit.title).font(.headline)
                                Spacer()
                                Text(String(format: "Similarity %.3f", hit.score))
                                    .monospacedDigit().font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(hit.snippet)
                                .font(.subheadline).foregroundStyle(.secondary)
                                .lineLimit(3)
                            if !hit.isDemo {
                                Button("Open file") { model.open(hit) }
                                    .buttonStyle(.link).font(.caption)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background, in: RoundedRectangle(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(.primary.opacity(0.09)))
                    }
                    if model.results.isEmpty && !model.isBusy {
                        ContentUnavailableView("No results", systemImage: "doc.text.magnifyingglass",
                                               description: Text("Load a folder or try a different search."))
                    }
                }
            }
        }
        .padding(24)
        .task { await model.loadDemo() }
    }
}
