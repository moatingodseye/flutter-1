import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String httpUrl;
  final String dbUrl;
  String? token;
  ApiClient({required this.httpUrl, required this.dbUrl});

  Map<String,String> get _headers {
    final h = {'content-type':'application/json'};
    if (token != null) h['authorization'] = 'Bearer $token';
    return h;
  }

  Future<Map<String,dynamic>> login(String username, String password) async {
    final r = await http.post(Uri.parse('$dbUrl/api/login'), headers: {'content-type':'application/json'}, body: jsonEncode({'username':username,'password':password}));
    if (r.statusCode != 200) throw Exception('Login failed: ${r.body}');
    final data = jsonDecode(r.body) as Map<String,dynamic>;
    token = data['token'] as String;
    return data;
  }

  Future<List<dynamic>> getProjects() async {
    final r = await http.get(Uri.parse('$dbUrl/api/projects'), headers: _headers);
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> createProject(Map<String,dynamic> project) async {
    final r = await http.post(Uri.parse('$dbUrl/api/projects'), headers: _headers, body: jsonEncode(project));
    if (r.statusCode != 200) throw Exception('Create project failed');
  }

  Future<void> updateProject(int id, Map<String,dynamic> project) async {
    final r = await http.put(Uri.parse('$dbUrl/api/projects/\$id'), headers: _headers, body: jsonEncode(project));
    if (r.statusCode != 200) throw Exception('Update project failed');
  }

  Future<void> deleteProject(int id) async {
    final r = await http.delete(Uri.parse('$dbUrl/api/projects/\$id'), headers: _headers);
    if (r.statusCode != 200) throw Exception('Delete project failed');
  }

  Future<void> createUser(Map<String,dynamic> user) async {
    final r = await http.post(Uri.parse('$dbUrl/api/users'), headers: _headers, body: jsonEncode(user));
    if (r.statusCode != 200) throw Exception('Create user failed');
  }

  Future<void> updateUser(int id, Map<String,dynamic> user) async {
    final r = await http.put(Uri.parse('$dbUrl/api/users/\$id'), headers: _headers, body: jsonEncode(user));
    if (r.statusCode != 200) throw Exception('Update user failed');
  }

  Future<void> deleteUser(int id) async {
    final r = await http.delete(Uri.parse('$dbUrl/api/users/\$id'), headers: _headers);
    if (r.statusCode != 200) throw Exception('Delete user failed');
  }

  Future<void> addTimeEntry(Map<String,dynamic> entry) async {
    final r = await http.post(Uri.parse('$dbUrl/api/time_entries'), headers: _headers, body: jsonEncode(entry));
    if (r.statusCode != 200) throw Exception('Add time entry failed');
  }

  Future<List<dynamic>> getTimeEntries({int? userId, String? start, String? end}) async {
    final params = <String>[];
    if (userId != null) params.add('user_id=$userId');
    if (start != null) params.add('start=$start');
    if (end != null) params.add('end=$end');
    final url = '$dbUrl/api/time_entries' + (params.isNotEmpty ? '?'+params.join('&') : '');
    final r = await http.get(Uri.parse(url), headers: _headers);
    if (r.statusCode != 200) throw Exception('Get time entries failed: ${r.body}');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> updateTimeEntry(int id, Map<String,dynamic> entry) async {
    final r = await http.put(Uri.parse('$dbUrl/api/time_entries/$id'), headers: _headers, body: jsonEncode(entry));
    if (r.statusCode != 200) throw Exception('Update time entry failed');
  }

  Future<void> deleteTimeEntry(int id) async {
    final r = await http.delete(Uri.parse('$dbUrl/api/time_entries/$id'), headers: _headers);
    if (r.statusCode != 200) throw Exception('Delete time entry failed');
  }
}
