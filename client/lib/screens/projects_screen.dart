import 'package:flutter/material.dart';
import '../services/api.dart';

class ProjectsScreen extends StatefulWidget {
  final ApiClient api;
  ProjectsScreen({required this.api});
  @override
  _ProjectsScreenState createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List projects = [];
  final _name = TextEditingController();
  final _desc = TextEditingController();

  void _load() async {
    final p = await widget.api.getProjects();
    setState(()=>projects = p);
  }

  void _create() async {
    await widget.api.createProject({'name': _name.text, 'description': _desc.text, 'enabled': true});
    _name.clear(); _desc.clear();
    _load();
  }

  void _edit(Map p) async {
    final nameController = TextEditingController(text: p['name']);
    final descController = TextEditingController(text: p['description'] ?? '');
    bool enabled = p['enabled'] == 1;
    final res = await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Edit Project'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
        TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
        Row(children: [Text('Enabled'), Switch(value: enabled, onChanged: (v){ enabled = v; setState((){});} )])
      ]),
      actions: [TextButton(onPressed: ()=>Navigator.of(context).pop(null), child: Text('Cancel')), TextButton(onPressed: ()=>Navigator.of(context).pop({'name': nameController.text, 'description': descController.text, 'enabled': enabled}), child: Text('Save'))],
    ));
    if (res != null) {
      await widget.api.updateProject(p['id'] as int, res);
      _load();
    }
  }

  void _delete(Map p) async {
    final ok = await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Delete Project'),
      content: Text('Delete project "\${p['name']}"? This cannot be undone.'),
      actions: [TextButton(onPressed: ()=>Navigator.of(context).pop(false), child: Text('Cancel')), TextButton(onPressed: ()=>Navigator.of(context).pop(true), child: Text('Delete'))],
    ));
    if (ok == true) {
      await widget.api.deleteProject(p['id'] as int);
      _load();
    }
  }

  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [Expanded(child: TextField(controller: _name, decoration: InputDecoration(labelText: 'Name'))), SizedBox(width:8), Expanded(child: TextField(controller: _desc, decoration: InputDecoration(labelText: 'Description'))), ElevatedButton(onPressed: _create, child: Text('Add'))]),
        Expanded(child: ListView.builder(itemCount: projects.length, itemBuilder: (_,i){ final p = projects[i]; return ListTile(title: Text(p['name']), subtitle: Text(p['description'] ?? ''), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(p['enabled']==1?'Enabled':'Disabled'), IconButton(icon: Icon(Icons.edit), onPressed: ()=>_edit(p)), IconButton(icon: Icon(Icons.delete), onPressed: ()=>_delete(p))])); }))
      ]),
    );
  }
}
