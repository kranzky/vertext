# Vertext

A browser for the indie web and local markdown files, written in Flutter. The browser is lightweight and fast, designed for iOS, Android, Mac, Windows, Linux, and Web platforms.

## Current Features

- **Dual-column Layout**: Side-by-side columns for parallel browsing with tabs in each column
- **Tab Management**: 
  - Create, close, restore, and reorder tabs
  - Drag tabs between columns
  - Remember tab history and scroll position
- **Link Handling**: 
  - Markdown links styled in blue
  - External links styled in red
  - Anchor links styled in light blue (grey if invalid)
  - Clicking links opens content in the opposite column
- **Local File Support**:
  - Open files with file:// URLs
  - File picker for safe file access
  - Asset loading from application bundle
- **URL Features**:
  - Relative link handling for files, assets, and web content
  - Support for URL schemes: http://, https://, file://, asset://
  - Special protocols: about:, vertext:
- **Navigation**:
  - Forward/back history for each tab
  - Anchor link navigation with header detection
  - Custom anchor IDs with short-form support
- **State Persistence**:
  - Saves browser state between sessions
  - Remembers window size and position on desktop platforms

## MMM - Massive Markdown Matrix

Vertext is designed to browse the "Massive Markdown Matrix" (MMM), as opposed to the "World Wide Web" (WWW). It focuses exclusively on Markdown content and provides a streamlined interface for browsing interconnected markdown documents.

The browser starts with the following home page: https://mmm.kranzky.com

## Planned Features

* User-selected themes that change fonts, color and layout
* Caching of downloaded markdown documents and included images
* Pre-retrieval and caching of links to other markdown documents
* Print document functionality
* MathTex equation rendering support
* Enhanced anchor navigation
* Mobile-friendly interface improvements

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Launch with `flutter run`

## Usage

- Left-click links to navigate
- Use tab bar controls to manage tabs
- Type URLs directly or use the file picker for local files
- Click anchor links to navigate within a document
- Drag tabs to reorder or move between columns

