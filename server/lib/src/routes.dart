import 'dart:convert';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'db.dart';
import 'ws_hub.dart';
import 'auth.dart';

class Api {
  final Db db;
  final WSHub ws;
  Api(this.db, this.ws);

  Router get router {
    final router = Router();

    router.get('/api/health', (Request req) => Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'}));

    router.post('/api/login', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final username = body['username'];
      final password = body['password'];
      final r = db.db.select('SELECT * FROM users WHERE username = ? LIMIT 1', [username]);
      if (r.isEmpty) return Response.forbidden(jsonEncode({'error':'invalid_credentials'}), headers: {'content-type':'application/json'});
      final row = r.first;
      if (row['enabled'] == 0) return Response.forbidden(jsonEncode({'error':'user_disabled'}), headers: {'content-type':'application/json'});
      if (!verifyPassword(password as String, row['password_hash'] as String)) return Response.forbidden(jsonEncode({'error':'invalid_credentials'}), headers: {'content-type':'application/json'});
      final token = generateJwt({'sub': row['id'], 'username': row['username'], 'iat': DateTime.now().millisecondsSinceEpoch});
      return Response.ok(jsonEncode({'token': token, 'user': {'id': row['id'], 'username': row['username']}}), headers: {'content-type':'application/json'});
    });

    // Users CRUD
    router.post('/api/users', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final username = body['username'];
      final password = body['password'];
      final enabled = body['enabled'] == false ? 0 : 1;
      final hash = hashPassword(password as String);
      db.db.execute('INSERT INTO users (username,password_hash,enabled,created_at) VALUES (?,?,?,?)', [username, hash, enabled, DateTime.now().toIso8601String()]);
      ws.broadcast('user_created', {'username': username});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

//    router.get('/api/users', (Request req) async {
//      final rows = db.db.select('SELECT id,username,enabled,created_at FROM users');
//      return Response.ok(jsonEncode(rows.map((r)=>r.toJson()).toList()), headers: {'content-type':'application/json'});
//    });

    router.get('/api/users', (Request req) async {
      final rows = db.db.select('SELECT id,username,enabled,created_at FROM users');
      return Response.ok(
        jsonEncode(rows.toList()),
        headers: {'content-type': 'application/json'},
      );
    });

    router.put('/api/users/<id|[0-9]+>', (Request req, String id) async {
      final body = jsonDecode(await req.readAsString());
      final enabled = body['enabled'] == false ? 0 : 1;
      if (body.containsKey('password')) {
        final hash = hashPassword(body['password'] as String);
        db.db.execute('UPDATE users SET password_hash=?, enabled=? WHERE id=?', [hash, enabled, int.parse(id)]);
      } else {
        db.db.execute('UPDATE users SET enabled=? WHERE id=?', [enabled, int.parse(id)]);
      }
      ws.broadcast('user_updated', {'id': int.parse(id)});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

    router.delete('/api/users/<id|[0-9]+>', (Request req, String id) async {
      db.db.execute('DELETE FROM users WHERE id=?', [int.parse(id)]);
      ws.broadcast('user_deleted', {'id': int.parse(id)});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

    // Projects CRUD
    router.post('/api/projects', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final name = body['name'];
      final description = body['description'];
      final enabled = body['enabled'] == false ? 0 : 1;
      db.db.execute('INSERT INTO projects (name,description,enabled,created_at) VALUES (?,?,?,?)', [name, description, enabled, DateTime.now().toIso8601String()]);
      ws.broadcast('project_created', {'name': name});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

    router.get('/api/projects', (Request req) async {
      final rows = db.db.select('SELECT id,name,description,enabled,created_at FROM projects');
//      return Response.ok(jsonEncode(rows.map((r)=>r.toJson()).toList()), headers: {'content-type':'application/json'});
      return Response.ok(
        jsonEncode(rows.toList()),
        headers: {'content-type': 'application/json'},
      );
    });

    router.put('/api/projects/<id|[0-9]+>', (Request req, String id) async {
      final body = jsonDecode(await req.readAsString());
      final name = body['name'];
      final description = body['description'];
      final enabled = body['enabled'] == false ? 0 : 1;
      db.db.execute('UPDATE projects SET name=?, description=?, enabled=? WHERE id=?', [name, description, enabled, int.parse(id)]);
      ws.broadcast('project_updated', {'id': int.parse(id)});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

    router.delete('/api/projects/<id|[0-9]+>', (Request req, String id) async {
      db.db.execute('DELETE FROM projects WHERE id=?', [int.parse(id)]);
      ws.broadcast('project_deleted', {'id': int.parse(id)});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

    // Time entries
    router.post('/api/time_entries', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final userId = body['user_id'];
      final projectId = body['project_id'];
      final date = body['date'];
      final minutes = body['minutes'];
      final notes = body['notes'];
      db.db.execute('INSERT INTO time_entries (user_id,project_id,date,minutes,notes,created_at) VALUES (?,?,?,?,?,?)', [userId, projectId, date, minutes, notes, DateTime.now().toIso8601String()]);
      ws.broadcast('time_entry_created', {'user_id': userId, 'project_id': projectId, 'date': date, 'minutes': minutes});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

    router.get('/api/time_entries', (Request req) async {
      final q = req.url.queryParametersAll;
      final userId = q['user_id']?.first;
      final start = q['start']?.first;
      final end = q['end']?.first;
      var sql = 'SELECT t.id,t.user_id,t.project_id,t.date,t.minutes,t.notes,p.name as project_name FROM time_entries t JOIN projects p ON p.id=t.project_id';
      final params = <dynamic>[];
      final wheres = <String>[];
      if (userId != null) { wheres.add('t.user_id = ?'); params.add(int.parse(userId)); }
      if (start != null) { wheres.add('date(t.date) >= date(?)'); params.add(start); }
      if (end != null) { wheres.add('date(t.date) <= date(?)'); params.add(end); }
      if (wheres.isNotEmpty) sql += ' WHERE ' + wheres.join(' AND ');
      final rows = db.db.select(sql, params);
//      return Response.ok(jsonEncode(rows.map((r)=>r.toJson()).toList()), headers: {'content-type':'application/json'});
      return Response.ok(
        jsonEncode(rows.toList()),
        headers: {'content-type': 'application/json'},
      );
    });

    router.put('/api/time_entries/<id|[0-9]+>', (Request req, String id) async {
      final body = jsonDecode(await req.readAsString());
      final minutes = body['minutes'];
      final notes = body['notes'];
      db.db.execute('UPDATE time_entries SET minutes=?, notes=? WHERE id=?', [minutes, notes, int.parse(id)]);
      ws.broadcast('time_entry_updated', {'id': int.parse(id)});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

    router.delete('/api/time_entries/<id|[0-9]+>', (Request req, String id) async {
      db.db.execute('DELETE FROM time_entries WHERE id=?', [int.parse(id)]);
      ws.broadcast('time_entry_deleted', {'id': int.parse(id)});
      return Response.ok(jsonEncode({'ok': true}), headers: {'content-type':'application/json'});
    });

    return router;
  }
}
