import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

class Db {
  final Database db;
  Db._(this.db);

  factory Db.open(String path) {
    final db = sqlite3.open(path);
    db.execute('PRAGMA foreign_keys = ON;');
    return Db._(db);
  }

  static void runMigrations(Database db, String migrationsDir) {
    final dir = Directory(migrationsDir);
    if (!dir.existsSync()) return;
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a,b)=>a.path.compareTo(b.path));
    for (final f in files) {
      final sql = f.readAsStringSync();
      if (sql.trim().isEmpty) continue;
      db.execute(sql);
    }
  }
}
