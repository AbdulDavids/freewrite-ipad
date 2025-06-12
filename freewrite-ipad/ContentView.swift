//
//  ContentView.swift
//  freewrite-ipad
//
//  Created by Abdul Baari Davids on 2025/06/12.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var document = WritingDocument()
    @StateObject private var settings = AppSettings()
    @State private var isEditing = false
    @State private var showStatusBar = true
    @State private var keyboardHeight: CGFloat = 0
    @State private var currentTime = ""
    @State private var timerMinutes: Int = 0
    @State private var timerSeconds: Int = 0
    @State private var isTimerRunning = false
    @State private var showTimerOptions = false
    @State private var showFontPicker = false
    @State private var showHistory = false
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Define editor paddings
    private let editorHorizontalPadding: CGFloat = 20
    private let editorTopPadding: CGFloat = 60
    
    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            // Full-screen text editor with placeholder
            ZStack(alignment: .topLeading) {
                // Text editor
                TextEditor(text: $document.content)
                    .font(settings.currentFont)
                    .foregroundColor(colorScheme == .dark ? Color(hex: "f2f2f2") : .black)
                    .scrollContentBackground(.hidden)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .focused($isTextEditorFocused)
                    .padding(.horizontal, editorHorizontalPadding)
                    .padding(.top, editorTopPadding)
                    .padding(.bottom, keyboardHeight > 0 ? 20 : 0)     // let text flow under entire toolbar height
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEditing = true
                            showStatusBar = false
                            isTextEditorFocused = true
                        }
                    }
                
                // Placeholder on top
                if document.content.isEmpty {
                    Text("start with one sentence")
                        .font(settings.currentFont)
                        .foregroundColor(Color.secondary)
                        .padding(.horizontal, editorHorizontalPadding + 5)
                        .padding(.top, editorTopPadding + 4)
                        .allowsHitTesting(false)
                        .zIndex(1)
                }
            }
            
            // Bottom toolbar overlay
            if showStatusBar {
                VStack {
                    Spacer()
                    bottomToolbar
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Minimize button when in fullscreen
            if !showStatusBar {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showStatusBar = true
                                isEditing = false
                            }
                        }) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .imageScale(.medium)
                                .padding(12)
                        }
                        .buttonStyle(.glass)
                        .tint(.secondary)
                        .clipShape(Circle())
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditing = false
                    showStatusBar = true
                    isTextEditorFocused = false
                }
            }
        }
        .statusBarHidden(!showStatusBar)
        .onReceive(Publishers.keyboardHeight) { height in
            keyboardHeight = height
        }
        .onAppear {
            setupKeyboardNotifications()
            startTimeUpdater()
            // Auto-focus the text editor on launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextEditorFocused = true
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(document: document)
        }
    }
    

    
    private var bottomToolbar: some View {
        Group {
            if horizontalSizeClass == .compact {
                // iPhone / compact width: horizontally scrollable bar
                HStack(spacing: 12) {
                    // Scrollable cluster of primary buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            fontPicker

                            Button(action: cycleFontSize) {
                                Text("\(Int(settings.fontSize))px")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                            }
                            .tint(.secondary)

                            Button(action: { showTimerOptions = true }) {
                                Text(String(format: "%02d:%02d", timerMinutes, timerSeconds))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                            }
                            .tint(isTimerRunning ? .orange : .secondary)
                            .actionSheet(isPresented: $showTimerOptions) {
                                ActionSheet(title: Text("Set Timer"), buttons: [
                                    .default(Text("5 minutes")) { setTimer(minutes: 5) },
                                    .default(Text("10 minutes")) { setTimer(minutes: 10) },
                                    .default(Text("15 minutes")) { setTimer(minutes: 15) },
                                    .default(Text("20 minutes")) { setTimer(minutes: 20) },
                                    .default(Text("30 minutes")) { setTimer(minutes: 30) },
                                    .destructive(Text("Clear")) { clearTimer() },
                                    .cancel()
                                ])
                            }

                            Button(action: toggleFullscreen) {
                                Image(systemName: "rectangle.compress.vertical")
                                    .imageScale(.medium)
                            }
                            .tint(.secondary)

                            if document.isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }

                    // Ellipsis menu pinned right
                    Menu {
                        Button("New Page") { newEntry() }
                        Button("History") { showHistory = true }
                        Button("ChatGPT") { openInChatGPT() }
                        Button("Export") { document.exportToFiles() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.medium)
                    }
                    .tint(.secondary)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)          // expand hit‑area to full width
                .contentShape(Rectangle())           // capture stray taps so they don’t hit editor
            } else {
                // iPad / regular width: fixed bar with spacer
                HStack {
                    fontPicker

                    Spacer()

                    HStack(spacing: 24) {
                        Button(action: cycleFontSize) {
                            Text("\(Int(settings.fontSize))px")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        .tint(.secondary)

                        Button(action: { showTimerOptions = true }) {
                            Text(String(format: "%02d:%02d", timerMinutes, timerSeconds))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        .tint(isTimerRunning ? .orange : .secondary)
                        .actionSheet(isPresented: $showTimerOptions) {
                            ActionSheet(title: Text("Set Timer"), buttons: [
                                .default(Text("5 minutes")) { setTimer(minutes: 5) },
                                .default(Text("10 minutes")) { setTimer(minutes: 10) },
                                .default(Text("15 minutes")) { setTimer(minutes: 15) },
                                .default(Text("20 minutes")) { setTimer(minutes: 20) },
                                .default(Text("30 minutes")) { setTimer(minutes: 30) },
                                .destructive(Text("Clear")) { clearTimer() },
                                .cancel()
                            ])
                        }

                        // History button
                        Button(action: { showHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .imageScale(.medium)
                        }
                        .tint(.secondary)

                        // Chat button
                        Button(action: openInChatGPT) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .imageScale(.medium)
                        }
                        .tint(.secondary)
                        
                        // Export button
                        Button(action: document.exportToFiles) {
                            Image(systemName: "square.and.arrow.up")
                                .imageScale(.medium)
                        }
                        .tint(.secondary)

                        Button(action: toggleFullscreen) {
                            Image(systemName: "rectangle.compress.vertical")
                                .imageScale(.medium)
                        }
                        .tint(.secondary)

                        Button(action: newEntry) {
                            Image(systemName: "plus")
                                .imageScale(.medium)
                        }
                        .tint(.blue)
                        .onLongPressGesture {
                            document.exportToFiles()
                        }

                        if document.isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
        .glassEffect()            // restore the glass backdrop
        .controlSize(.large)      // bigger tap target for all buttons
        .frame(maxWidth: .infinity)          // stretch transparent hit‑area edge‑to‑edge
        .contentShape(Rectangle())           // capture taps anywhere in the bar region
        .zIndex(2)                           // keep toolbar above pop‑ups like the font picker
    }
    
    private var fontPicker: some View {
        Button(action: { showFontPicker = true }) {
            HStack(spacing: 4) {
                Text(settings.fontName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .confirmationDialog("Select Font", isPresented: $showFontPicker, titleVisibility: .visible) {
            ForEach(FontOption.allCases, id: \.self) { option in
                Button(option.displayName) {
                    settings.selectedFont = option
                }
            }
        }
    }
    
    private func startTimeUpdater() {
        updateTime()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTime()
            checkTimer()
        }
    }
    
    private func checkTimer() {
        guard isTimerRunning else { return }
        
        if timerSeconds > 0 {
            timerSeconds -= 1
        } else if timerMinutes > 0 {
            timerMinutes -= 1
            timerSeconds = 59
        } else {
            // Timer finished
            isTimerRunning = false
            timerMinutes = 0
            timerSeconds = 0
        }
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: Date())
    }
    

    
    private func setTimer(minutes: Int) {
        timerMinutes = minutes
        timerSeconds = 0
        isTimerRunning = true
    }
    
    private func clearTimer() {
        timerMinutes = 0
        timerSeconds = 0
        isTimerRunning = false
    }
    
    private func cycleFontSize() {
        let sizes: [CGFloat] = [12, 14, 16, 18, 20, 24, 28, 32]
        if let currentIndex = sizes.firstIndex(of: settings.fontSize) {
            let nextIndex = (currentIndex + 1) % sizes.count
            settings.fontSize = sizes[nextIndex]
        } else {
            settings.fontSize = 18 // Default fallback
        }
    }
    
    private func openInChatGPT() {
        let text = document.content.isEmpty ? "start with one sentence" : document.content
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let chatGPTURL = "https://chat.openai.com/?q=\(encodedText)"
        
        if let url = URL(string: chatGPTURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func toggleFullscreen() {
        // Springy minimize / restore animation
        withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.25)) {
            showStatusBar.toggle()
        }
    }
    
    private func newEntry() {
        document.createNewEntry()
    }
    

    
    private func setupKeyboardNotifications() {
        // Keyboard notifications are handled by the Publishers.keyboardHeight publisher
    }
}


// MARK: - History View
struct HistoryView: View {
    @ObservedObject var document: WritingDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(document.history.indices, id: \.self) { i in
                    Text(document.history[i])
                        .lineLimit(3)
                        .padding(.vertical, 4)
                        .onTapGesture {
                                document.content = document.history[i]     // load into editor
                                dismiss()                                  // close the sheet
                            }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Models

class WritingDocument: ObservableObject {
    @Published var content: String = "" {
        didSet {
            scheduleAutosave()
        }
    }
    @Published var isSaving = false
    @Published var history: [String] = []
    
    private var autosaveTimer: Timer?
    
    init() {
        loadDocument()
    }
    
    private func scheduleAutosave() {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            Task { @MainActor in
                await self.autosave()
            }
        }
    }
    
    @MainActor
    private func autosave() async {
        isSaving = true
        
        // Simulate save delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Save to UserDefaults (in a real app, you'd save to Files app)
        UserDefaults.standard.set(content, forKey: "document_content")
        
        isSaving = false
    }
    
    private func loadDocument() {
        if let savedContent = UserDefaults.standard.string(forKey: "document_content"),
           !savedContent.isEmpty {
            content = savedContent
        }
    }
    
    func createNewEntry() {
        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            history.insert(content, at: 0)
        }
        content = ""
    }
    
    func exportToFiles() {
        // Implementation for exporting to Files app would go here
        let documentPicker = UIDocumentPickerViewController(forExporting: [createTextFile()], asCopy: true)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(documentPicker, animated: true)
        }
    }
    
    private func createTextFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "freewrite-\(Date().timeIntervalSince1970).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

class AppSettings: ObservableObject {
    @Published var selectedFont: FontOption = .lato {
        didSet {
            UserDefaults.standard.set(selectedFont.rawValue, forKey: "selected_font")
            if selectedFont == .random {
                selectRandomFont()
            }
        }
    }
    
    @Published var fontSize: CGFloat = 18 {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: "font_size")
        }
    }
    
    @Published var currentRandomFont: String = "Helvetica"
    
    private let availableFonts = [
        "Helvetica", "Georgia", "Palatino", "Times New Roman", "Courier New",
        "Avenir", "Baskerville", "Cochin", "Copperplate", "Didot",
        "Futura", "Gill Sans", "Hoefler Text", "Optima", "Trebuchet MS"
    ]
    
    var fontName: String {
        switch selectedFont {
        case .lato: return "Lato"
        case .arial: return "Arial"
        case .system: return "System"
        case .serif: return "Serif"
        case .random: return currentRandomFont
        }
    }
    
    var currentFont: Font {
        switch selectedFont {
        case .lato:
            return .custom("Lato", size: fontSize)
        case .arial:
            return .custom("Arial", size: fontSize)
        case .system:
            return .system(size: fontSize)
        case .serif:
            return .custom("Times New Roman", size: fontSize)
        case .random:
            return .custom(currentRandomFont, size: fontSize)
        }
    }
    
    private func selectRandomFont() {
        currentRandomFont = availableFonts.randomElement() ?? "Helvetica"
    }
    
    init() {
        if let savedFont = UserDefaults.standard.string(forKey: "selected_font"),
           let font = FontOption(rawValue: savedFont) {
            selectedFont = font
        }
        
        let savedSize = UserDefaults.standard.double(forKey: "font_size")
        if savedSize > 0 {
            fontSize = savedSize
        }
        
        if selectedFont == .random {
            selectRandomFont()
        }
    }
}

enum FontOption: String, CaseIterable {
    case lato = "lato"
    case arial = "arial"
    case system = "system"
    case serif = "serif"
    case random = "random"
    
    var displayName: String {
        switch self {
        case .lato: return "Lato"
        case .arial: return "Arial"
        case .system: return "System"
        case .serif: return "Serif"
        case .random: return "Random"
        }
    }
    
    func font(size: CGFloat) -> Font {
        switch self {
        case .lato:
            return .custom("Lato", size: size)
        case .arial:
            return .custom("Arial", size: size)
        case .system:
            return .system(size: size)
        case .serif:
            return .custom("Times New Roman", size: size)
        case .random:
            return FontOption.allCases.randomElement()?.font(size: size) ?? .system(size: size)
        }
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

#Preview {
    ContentView()
}
