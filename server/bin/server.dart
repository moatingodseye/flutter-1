import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf/shelf.dart';
//import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as p;
import '../lib/src/db.dart';
import '../lib/src/routes.dart';
import '../lib/src/ws_hub.dart';

void main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final dbPath = Platform.environment['DB_PATH'] ?? p.join(Directory.current.path, 'data', 'timesheet.db');
  final migrations = p.join(Directory.current.path, 'lib', 'src', 'migrations');

  final database = Db.open(dbPath);
  Db.runMigrations(database.db, migrations);

  final ws = WSHub();
  final api = Api(database, ws);

  final cascade = Cascade().add(api.router).add(ws.handler()).add(createStaticHandler(p.join(Directory.current.path, '..', 'client', 'build', 'web'), defaultDocument: 'index.html'));
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(cascade.handler);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on port ${server.port}');
}
