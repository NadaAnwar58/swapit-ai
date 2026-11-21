import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/swapit_supabase_service.dart';
import '../theme/app_colors.dart';

class SwapRequestsScreen extends StatelessWidget {
  const SwapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primary),
          title: const Text(
            'Swap Requests',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.secondary,
            tabs: <Widget>[
              Tab(text: 'Incoming'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _RequestsList(incoming: true),
            _RequestsList(incoming: false),
          ],
        ),
      ),
    );
  }
}

class _RequestsList extends StatefulWidget {
  const _RequestsList({required this.incoming});

  final bool incoming;

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> data = widget.incoming
          ? await SwapitSupabaseService.fetchIncomingRequests()
          : await SwapitSupabaseService.fetchOutgoingRequests();
      if (!mounted) return;
      setState(() {
        _requests = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
        content: Text(text),
      ),
    );
  }

  Future<void> _decide(String requestId, String status) async {
    if (_busyId != null) return;
    setState(() => _busyId = requestId);

    try {
      await SwapitSupabaseService.updateRequestStatus(
        requestId: requestId,
        status: status,
      );
      if (!mounted) return;
      _showMessage(
        status == 'accepted'
            ? 'Request accepted. You can now contact them on WhatsApp.'
            : 'Request rejected.',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not update the request: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openWhatsapp(String otherUserId) async {
    try {
      final Map<String, dynamic>? profile =
          await SwapitSupabaseService.fetchProfile(otherUserId);
      final String number = (profile?['whatsapp'] ?? '').toString().trim();

      if (!mounted) return;

      if (number.isEmpty) {
        _showMessage(
          'The other person has not added a WhatsApp number yet.',
          isError: true,
        );
        return;
      }

      final bool opened = await launchUrl(
        Uri.parse(SwapitSupabaseService.whatsappLink(number)),
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage('Could not open WhatsApp.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not open WhatsApp: $e', isError: true);
    }
  }

  Widget _statusPill(String status) {
    Color bg = AppColors.softBox;
    Color fg = AppColors.muted;
    String label = status;

    if (status == 'pending') {
      bg = AppColors.warnBg;
      fg = AppColors.warnText;
      label = 'Pending';
    } else if (status == 'accepted') {
      bg = AppColors.softGreen;
      fg = AppColors.secondary;
      label = 'Accepted';
    } else if (status == 'rejected') {
      bg = const Color(0xFFFBE4E4);
      fg = AppColors.error;
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> request) {
    final String id = request['id'].toString();
    final String status = (request['status'] ?? 'pending').toString();
    final String targetTitle =
        ((request['target'] as Map?)?['title'] ?? 'Item').toString();
    final String? offeredTitle =
        (request['offered'] as Map?)?['title']?.toString();
    final String message = (request['message'] ?? '').toString().trim();
    final String otherUserId = (widget.incoming
            ? request['requester_id']
            : request['target_owner_id'])
        .toString();
    final bool busy = _busyId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.incoming
                      ? 'Request for: $targetTitle'
                      : 'You requested: $targetTitle',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusPill(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.incoming
                ? 'They offer: ${offeredTitle ?? 'No item selected'}'
                : 'You offered: ${offeredTitle ?? 'No item selected'}',
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          if (message.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              '"$message"',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
              ),
            ),
          ],
          if (widget.incoming && status == 'pending') ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _decide(id, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => _decide(id, 'accepted'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'accepted') ...<Widget>[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openWhatsapp(otherUserId),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Contact on WhatsApp'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Text(
          widget.incoming
              ? 'No incoming requests yet.'
              : 'You have not sent any requests yet.',
          style: const TextStyle(color: AppColors.muted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (BuildContext context, int index) =>
            _card(_requests[index]),
      ),
    );
  }
}