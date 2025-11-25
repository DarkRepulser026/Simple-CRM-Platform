import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../models/attachment.dart';
import '../../services/service_locator.dart';
import '../../services/tickets_service.dart';
import '../../navigation/app_router.dart';
import 'ticket_edit_screen.dart';
import '../../services/attachments_service.dart';
import '../../widgets/role_visibility.dart';
import 'package:flutter/services.dart';
import '../../utils/picker_stub.dart' show PickedFile;
import '../../utils/picker.dart' show pickFile;
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class TicketDetailArgs {
  const TicketDetailArgs({required this.ticketId});
  final String ticketId;
}

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late final TicketsService _ticketsService;
  bool _isLoading = true;
  String? _error;
  Ticket? _ticket;
  final _filePathCtrl = TextEditingController();
  String? _selectedFileName;
  String? _selectedFilePath;
  PickedFile? _selectedPickedFile;
  bool _uploading = false;
  List<Attachment>? _attachments;

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
    // Attachments service
    locator.isReady<AttachmentsService>().then((_) {});
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _ticketsService.getTicket(widget.ticketId);
      if (res.isSuccess) {
        setState(() { _ticket = res.value; _isLoading = false; });
        // Load attachments for the ticket
        _loadAttachments();
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() { _error = 'Failed to load ticket: $e'; _isLoading = false; });
    }
  }

  Future<void> _loadAttachments() async {
    try {
      final attService = locator<AttachmentsService>();
      final res = await attService.listForEntity(entityType: 'ticket', entityId: widget.ticketId);
      if (res.isSuccess) {
        setState(() { _attachments = res.value; });
      }
    } catch (e) {
      // Non-fatal - attachments unavailable
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading ticket...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    if (_ticket == null) return const Scaffold(body: Center(child: Text('No ticket data')));
    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket!.subject),
        actions: [
          // Only allow editing for Admin/Manager roles
          ManagerOrAdminOnly(child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => AppRouter.navigateTo(context, AppRouter.ticketEdit, arguments: TicketEditArgs(ticketId: _ticket!.id)),
          )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status: ${_ticket!.status.value}'),
          const SizedBox(height: 8),
          Text('Priority: ${_ticket!.priority.value}'),
          const SizedBox(height: 20),
            Row(children: [
            Expanded(child: Text(_selectedFileName ?? 'No file selected')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Select'),
              onPressed: () async {
                final res = await pickFile();
                if (res == null) return;
                setState(() {
                  _selectedFileName = res.name;
                  _selectedFilePath = null;
                  _selectedPickedFile = res;
                });
              },
            ),
          ]),
          const SizedBox(height: 8),
          _uploading
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Upload Attachment (dev-only)'),
                  onPressed: () async {
                    final path = _selectedFilePath ?? _filePathCtrl.text.trim();
                    if (path.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file')));
                      return;
                    }
                    setState(() => _uploading = true);
                    final attService = locator<AttachmentsService>();
                    final bytes = _selectedPickedFile?.bytes;
                    final fileName = _selectedPickedFile?.name ?? _selectedFileName ?? _filePathCtrl.text.trim();
                    final res = await attService.uploadFile(filePath: path, fileBytes: bytes, fileName: fileName, entityType: 'ticket', entityId: _ticket!.id, mimeType: _selectedPickedFile?.mimeType);
                    setState(() => _uploading = false);
                      if (res.isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment uploaded')));
                      setState(() {
                        _selectedFileName = null;
                        _selectedFilePath = null;
                          _selectedPickedFile = null;
                      });
                      _filePathCtrl.clear();
                      await _loadAttachments();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${res.error}')));
                    }
                  },
                ),
          const SizedBox(height: 16),
          if (_attachments != null) ...[
            const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final a in _attachments!) ListTile(
              leading: const Icon(Icons.attachment),
              title: Text(a.filename),
              subtitle: Text('${a.uploadedBy ?? 'Unknown'} • ${a.uploadedAt.toLocal()}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final uri = Uri.parse(a.url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open URL')));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: a.url));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
                  },
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
