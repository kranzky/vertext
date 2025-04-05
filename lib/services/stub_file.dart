// Stub file implementation for web platform
// This provides minimal implementations of the File API to prevent compilation errors

class File {
  final String path;
  
  File(this.path);
  
  Future<bool> exists() async => false;
  
  Future<String> readAsString() async {
    throw UnsupportedError('File I/O is not supported on web platform');
  }
}

class Directory {
  final String path;
  
  Directory(this.path);
  
  static Directory get current => Directory('.');
}

// Stub exception class
class FileSystemException implements Exception {
  final String message;
  final String? path;
  final OSError? osError;
  
  FileSystemException([this.message = '', this.path, this.osError]);
  
  @override
  String toString() => message;
}

class OSError {
  final String message;
  final int? errorCode;
  
  OSError([this.message = '', this.errorCode]);
}