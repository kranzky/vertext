# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Vertext is a lightweight Flutter-based browser for markdown content, targeting mobile (iOS/Android) and desktop (Mac/Windows) platforms.

## Build Commands
- Setup: `flutter pub get`
- Run dev: `flutter run`
- Build: `flutter build <platform>`
- Test: `flutter test`
- Single test: `flutter test test/path_to_test.dart`

## Code Style Guidelines
- Use Dart language conventions with Flutter framework
- Formatting: Use `flutter format .` to ensure consistent formatting
- Imports order: dart:core first, then Flutter packages, then project imports
- Naming: camelCase for variables/methods, PascalCase for classes/widgets
- State management: Follow a consistent pattern (Provider, Bloc, or Riverpod)
- Error handling: Use try/catch with meaningful error messages
- Prefer strong typing with minimal use of dynamic
- Extract reusable widgets into separate components
- Document public APIs with dartdoc comments
- Follow SOLID principles, especially for complex components
- Tab/column layout should use a responsive design approach
