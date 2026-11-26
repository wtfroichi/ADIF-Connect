import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readLocalFileBytes(String path) => File(path).readAsBytes();

Future<bool> localFileExists(String path) => File(path).exists();

Future<void> deleteLocalFile(String path) => File(path).delete();
