# NeuralSearch — macOS AI search demo

A real native macOS app using **SwiftUI + Swift + Objective-C**. Runs locally, with no API key, login, server, or package dependencies.

## Requirements

- **Mac running macOS 14 (Sonoma) or newer**
- **Xcode 15.4 or newer** (current Xcode recommended)
- Does **not** run on Windows/Linux as written; it uses Apple-only APIs.

## Run it

1. Unzip `NeuralSearch.zip` on your Mac.
2. Double-click **`NeuralSearch.xcodeproj`** to open in Xcode.
3. Select the **NeuralSearch** scheme and **My Mac** as the run destination.
4. Press **Command-R** (or Product → Run).
5. Try the preloaded demo documents, then choose **Index Folder…** to search your own files.

If Xcode asks about trust, review the source code before opening. The project has no external dependencies or build scripts.

## How it works

- **SwiftUI** powers the Mac interface.
- **Swift actor** (`SearchEngine.swift`) handles local file reading, sentence embeddings, and search orchestration.
- **Apple NaturalLanguage (`NLEmbedding`)** provides an on-device English sentence embedding *if supported on your Mac*. If it is not available, the interface clearly labels the deterministic keyword-based fallback. The fallback is **not semantic AI**.
- **Objective-C** (`PKSearchIndex.m`) stores vectors and ranks search results using cosine similarity.
- **PDFKit** extracts text from text-based PDFs. Scanned PDFs need OCR, which is not included.

## Files and privacy

Supports `.txt`, `.md`, `.markdown`, `.swift`, `.m`, `.h`, `.json`, `.csv`, and text-based `.pdf` files. It indexes up to **300 files** per selected folder, skips files over **2 MB**, and keeps index contents **in memory only**. No files leave the Mac, and no data is written to a server.

The search uses one document-level vector per file. This is a **portfolio prototype**, not a production search engine: future improvements include document chunking, a persistent index, approximate nearest-neighbor algorithms, multilingual embeddings, and evaluation datasets.

## Troubleshooting

- If your Mac says it cannot open the project, confirm Xcode (not only Command Line Tools) is installed.
- If the UI reports "Lexical fallback," Apple's sentence embedding is not available on that machine. The app remains functional but uses word-based similarity rather than semantic understanding.
- If your results seem generic, try more specific queries or index a folder with several distinct documents.
- The project cannot be compiled in this environment because macOS SDK/Xcode are unavailable here; its Xcode build should be verified on a Mac.
