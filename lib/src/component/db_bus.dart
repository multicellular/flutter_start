import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;
import 'dart:convert';

class DBCommon {
  DBCommon._internal();
  static DBCommon _singleton = new DBCommon._internal();

  factory DBCommon() {
    return _singleton;
  }
  Database _db;
  String table = 'local_messages';
  initMessageDB() async {
    var databasePath = await getDatabasesPath();
    String path = Path.join(databasePath, 'message.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
            create table $table(
              localid integer primary key autoincrement,
              msg text not null,
              read integer not null default 0,
              groupid integer,
              private integer
            )
          ''');
    });
  }

  Future<int> insertMessage(message, {bool isRead = false}) async {
    
    if (_db == null || !_db.isOpen) {
      await initMessageDB();
    }
    var msgJson = json.decode(message);
    int localeID = await _db.insert('$table', {
      'msg': message,
      'groupid': msgJson['roomid'],
      'private': msgJson['private'] ? 1 : 0,
      'read': isRead ? 1 : 0
    });
    return localeID;
  }

  Future<List<Map<String, dynamic>>> queryMessage(
      {bool distinct,
      List<String> columns,
      String where,
      List<dynamic> whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) async {
    if (_db == null || !_db.isOpen) {
      await initMessageDB();
    }
    return await _db.query(
      '$table',
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  dispose() {
    if (_db != null) {
      _db.close();
    }
  }
}

var dbBus = new DBCommon();
