import 'dart:convert';
import 'dart:io';

class ProgressKeys {
  static String doctorsSearch = 'doctors_search';
}

class ProgressChecker {
  ProgressChecker() {
    // Ensure the progress file exists
    File file = File(filePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      file.writeAsStringSync('{}'); // Initialize with an empty JSON object
    }
  }
  final String filePath = 'progress/progress.json';

  int checkProgress(String key) {
    File file = File(filePath);
    if (!file.existsSync()) {
      return -1;
    }
    String content = file.readAsStringSync();
    Map<String, dynamic> json = jsonDecode(content);
    return json[key] ?? -1;
  }

  void updateProgress(String key, int value) {
    File file = File(filePath);
    Map<String, dynamic> progressData = {};

    if (file.existsSync()) {
      String content = file.readAsStringSync();
      progressData = jsonDecode(content);
    }

    progressData[key] = value;
    file.writeAsStringSync(jsonEncode(progressData));
  }
}
