# Freewrite iPad - Distraction-Free Writing

A minimalist, distraction-free writing app for iPadOS inspired by the Freewrite aesthetic.

## Features

### ✨ Core Writing Experience
- **Full-screen editor** - Clean, distraction-free interface
- **Centered page layout** - White canvas with subtle 2px rounded border and 8pt shadow
- **Cursor positioning** - Starts at top-left for immediate writing
- **Tap to focus** - Tap inside page to focus keyboard and hide status bar
- **Tap outside to exit** - Brings back UI controls

### 🎨 Typography & Fonts
- **Font picker** - Located at bottom left
- **5 Font options**: 18px Lato (default), Arial, System, Serif, Random
- **Adaptive sizing** - Responsive to device orientation and size classes

### 🔧 Bottom Toolbar
- **Font display** - Shows current font size and name (e.g., "18px • Lato")
- **Live time** - Updates every second in HH:mm format
- **Chat icon** - Placeholder for future messaging features
- **Fullscreen toggle** - Hide/show status bar and toolbar
- **New Entry button** - Clear current document (long press to export)
- **Autosave spinner** - Visual indicator when saving

### 💾 Data Management
- **Autosave** - Automatically saves every 2 seconds
- **Persistent storage** - Content saved to UserDefaults
- **Export functionality** - Long press "New Entry" to export as .txt file
- **Document recovery** - Restores last session on app launch

### 🌙 Dark Mode Support
- **Adaptive theming** - Automatically switches with system settings
- **Dark canvas** - #121212 background with #f2f2f2 text
- **Minimal shadows** - Borders and shadows removed in dark mode

### 📱 iPad Optimization
- **Size class aware** - Adapts to different iPad sizes and orientations
- **Safe area support** - Respects notches and home indicators
- **Keyboard handling** - Adjusts layout when keyboard appears
- **Gesture support** - Intuitive tap gestures for focus management

## Usage

1. **Start Writing** - App launches directly into the editor with placeholder text
2. **Focus Mode** - Tap inside the writing area to enter distraction-free mode
3. **Font Selection** - Use the font picker in the bottom left to change typography
4. **Export** - Long press the "New Entry" button to save your work as a text file
5. **New Document** - Tap "New Entry" to start fresh (your work is auto-saved)

## Technical Details

- **Framework**: SwiftUI + Combine
- **Target**: iPadOS 15.0+
- **Dependencies**: None (pure SwiftUI implementation)
- **Architecture**: MVVM with ObservableObject state management
- **Storage**: UserDefaults for persistence, Files app integration for export

## Installation

1. Open the project in Xcode
2. Select an iPad simulator or connected iPad device
3. Build and run (⌘+R)

## Customization

The app is designed to be easily customizable:

- **Fonts**: Add new fonts in the `FontOption` enum
- **Colors**: Modify the hex color extensions for custom themes
- **Layout**: Adjust page dimensions and spacing in the `writingArea` function
- **Autosave interval**: Change the timer interval in `WritingDocument.scheduleAutosave()`

---

*Inspired by the Freewrite aesthetic - because sometimes the best writing happens when everything else disappears.* 