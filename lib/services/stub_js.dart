// Stub JS implementation for non-web platforms

// Create a stub JsObject that mirrors the JS interface
class JsObject {
  bool hasProperty(String name) => false;
  dynamic callMethod(String name, List<dynamic> args) => null;
  static JsObject fromBrowserObject(dynamic object) => JsObject();
}

// Make a stub js.context object
final _context = _JsContext();
class _JsContext {
  bool hasProperty(String prop) => false;
  dynamic operator [](String prop) => null;
}

// Export these as if they were from dart:js
final context = _context;