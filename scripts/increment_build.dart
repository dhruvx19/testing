import 'dart:io';

void main() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found in the root directory.');
    exit(1);
  }

  final lines = pubspecFile.readAsLinesSync();
  final newLines = <String>[];
  bool updated = false;

  for (var line in lines) {
    if (line.trim().startsWith('version:')) {
      final versionMatch = RegExp(r'version:\s*([^\s]+)').firstMatch(line);
      if (versionMatch != null) {
        final versionStr = versionMatch.group(1)!;
        final parts = versionStr.split('+');
        
        String newVersion;
        if (parts.length == 2) {
          final buildNumber = int.tryParse(parts[1]);
          if (buildNumber != null) {
            newVersion = '${parts[0]}+${buildNumber + 1}';
          } else {
            newVersion = '${parts[0]}+1';
          }
        } else {
          newVersion = '$versionStr+1';
        }
        
        final leadingWhitespace = line.substring(0, line.indexOf('version:'));
        newLines.add('${leadingWhitespace}version: $newVersion');
        print('Updated app version: $versionStr -> $newVersion');
        updated = true;
        continue;
      }
    }
    newLines.add(line);
  }

  if (updated) {
    pubspecFile.writeAsStringSync(newLines.join('\n') + '\n');
    print('pubspec.yaml updated successfully.');
  } else {
    print('Error: Could not find version entry in pubspec.yaml.');
    exit(1);
  }
}
