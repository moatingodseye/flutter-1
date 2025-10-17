import 'package:flutter/material.dart';
import '../services/api.dart';
import 'projects_screen.dart';
import 'timesheet_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiClient apiClient;
  final Map<String,dynamic> user;
  DashboardScreen({required this.apiClient, required this.user});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final tabs = [TimesheetScreen(api: widget.apiClient, user: widget.user), ProjectsScreen(api: widget.apiClient), ReportsScreen(api: widget.apiClient)];
    return Scaffold(
//      appBar: AppBar(title: Text('Timesheet - \${widget.user['username']}')),
      appBar: AppBar(title: Text('Timesheet - ${widget.user['username']}')),
      body: tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i)=>setState(()=>_index=i),
        items: [BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timesheet'), BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Projects'), BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Reports')],
      ),
    );
  }
}
