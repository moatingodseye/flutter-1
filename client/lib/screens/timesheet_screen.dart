import 'package:flutter/material.dart';
import '../services/api.dart';

class TimesheetScreen extends StatefulWidget {
  final ApiClient api;
  final Map<String,dynamic> user;
  TimesheetScreen({required this.api, required this.user});
  @override
  _TimesheetScreenState createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  List projects = [];
  DateTime selectedDate = DateTime.now();
  int? selectedProjectId;
  final _minutes = TextEditingController();
  final _notes = TextEditingController();

  void _load() async {
    final p = await widget.api.getProjects();
    setState(()=>projects = p.where((e) => e['enabled']==1).toList());
  }

  void _add() async {
    if (selectedProjectId==null) return;
    final entry = {'user_id': widget.user['id'], 'project_id': selectedProjectId, 'date': selectedDate.toIso8601String(), 'minutes': int.parse(_minutes.text), 'notes': _notes.text};
    await widget.api.addTimeEntry(entry);
    _minutes.clear(); _notes.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Time added')));
  }

  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [Text('Date: '), TextButton(child: Text('${selectedDate.toLocal().toIso8601String().split('T')[0]}'), onPressed: () async { final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d!=null) setState(()=>selectedDate=d); })]),
        DropdownButton<int?>(value: selectedProjectId, hint: Text('Select project'), items: projects.map<DropdownMenuItem<int>>((p) => DropdownMenuItem(value: p['id'] as int, child: Text(p['name']))).toList(), onChanged: (v)=>setState(()=>selectedProjectId=v)),
        TextField(controller: _minutes, decoration: InputDecoration(labelText: 'Minutes'), keyboardType: TextInputType.number),
        TextField(controller: _notes, decoration: InputDecoration(labelText: 'Notes')),
        ElevatedButton(onPressed: _add, child: Text('Add Time'))
      ]),
    );
  }
}
