# Sample Markdown Document

This is a sample local Markdown file to demonstrate Vertext's local file support.

## Local File Features

Vertext can display local Markdown files from:

1. The application's assets directory
2. Your local filesystem with `file://` URLs
3. Relative paths within the application

## Code Sample

Here's a simple code sample:

```dart
void main() {
  print('Hello from Vertext!');
  
  // Load a local file
  final file = File('sample.md');
  final content = file.readAsStringSync();
  
  print('Loaded ${content.length} characters');
}
```

## Image Example

If you include local images in your markdown files, Vertext can display them too!

## Tables

| Feature | Support Status |
|---------|---------------|
| Local files | ✅ Supported |
| Relative paths | ✅ Supported |
| Asset files | ✅ Supported |
| File:// protocol | ✅ Supported |

## Math Equations

When using a Markdown renderer that supports it, you can include math equations:

The quadratic formula is: $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$

## Interactive Elements

- [ ] Todo items
- [x] Completed items

## Local Navigation

You can also navigate between local files:

- [Go back to Welcome](welcome.md)
- [Learn about Markdown](about_markdown.md)