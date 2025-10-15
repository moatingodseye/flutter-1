import 'package:flutter/material.dart';
import '../services/api.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _client = ApiClient(baseUrl: Uri.base.origin);
  bool _loading = false;
  String? _error;

  void _login() async {
    setState(()=>_loading=true);
    try {
      final res = await _client.login(_username.text, _password.text);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DashboardScreen(apiClient: _client, user: res['user'])));
    } catch (e) {
      setState(()=>_error=e.toString());
    } finally { setState(()=>_loading=false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _username, decoration: InputDecoration(labelText: 'Username')),
              TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              if (_error!=null) Text(_error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 12),
              ElevatedButton(onPressed: _loading?null:_login, child: _loading?CircularProgressIndicator():Text('Login'))
            ]),
          ),
        ),
      ),
    );
  }
}
