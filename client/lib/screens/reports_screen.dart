import 'package:flutter/material.dart';
import '../services/api.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  final ApiClient api;
  ReportsScreen({required this.api});
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime start = DateTime.now().subtract(Duration(days: 7));
  DateTime end = DateTime.now();
  List data = [];
  bool _loading = false;

  void _load() async {
    setState(()=>_loading=true);
    final s = start.toIso8601String();
    final e = end.toIso8601String();
    final r = await widget.api.getTimeEntries(start: s, end: e);
    setState(()=>data=r);
    setState(()=>_loading=false);
  }

  void _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (ctx) {
      return pw.Column(children: [
        pw.Text('Timesheet Report', style: pw.TextStyle(fontSize: 18)),
        pw.Text('From \${start.toIso8601String().split('T')[0]} to \${end.toIso8601String().split('T')[0]}'),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(context: ctx, data: <List<String>>[
          <String>['Date','User ID','Project','Minutes','Notes'],
          ...data.map((d) => [d['date'].toString().split('T')[0], d['user_id'].toString(), d['project_name'] ?? d['project_id'].toString(), d['minutes'].toString(), (d['notes'] ?? '').toString()])
        ])
      ]);
    }));
    final bytes = await doc.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'timesheet_report_\${start.toIso8601String().split('T')[0]}_to_\${end.toIso8601String().split('T')[0]}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  void initState() { super.initState(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Text('Start:'),
          TextButton(child: Text(start.toIso8601String().split('T')[0]), onPressed: () async { final d = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d!=null) setState(()=>start=d); _load(); }),
          SizedBox(width: 12),
          Text('End:'),
          TextButton(child: Text(end.toIso8601String().split('T')[0]), onPressed: () async { final d = await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d!=null) setState(()=>end=d); _load(); }),
          Spacer(),
          ElevatedButton(onPressed: _exportPdf, child: Text('Export PDF'))
        ]),
        SizedBox(height: 12),
        _loading ? CircularProgressIndicator() : Expanded(child: ListView.builder(itemCount: data.length, itemBuilder: (_,i){ final d = data[i]; return ListTile(title: Text('${d['date'].toString().split('T')[0]} — ${d['project_name'] ?? ''}'), subtitle: Text('${d['minutes']} min — ${d['notes'] ?? ''}')); }))
      ]),
    );
  }
}
