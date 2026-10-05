import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/chat_user_model.dart';
import '../../shared/widgets/ms_skeleton.dart';

class NgoManagementScreen extends StatefulWidget {
  const NgoManagementScreen({super.key});

  @override
  State<NgoManagementScreen> createState() => _NgoManagementScreenState();
}

class _NgoManagementScreenState extends State<NgoManagementScreen> {
  final Dio _dio = DioClient.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  List<ChatUser> _ngos = [];
  bool _isLoading = false;
  String? _errorMsg;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchNgos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNgos([String? query]) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final q = (query != null && query.trim().isNotEmpty) ? query.trim() : 'NGO';
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/chat/users/search',
        queryParameters: {'q': q},
      );

      if (response.data != null && response.data['success'] == true) {
        final List raw = response.data['data'] ?? [];
        final parsed = raw.map((j) => ChatUser.fromJson(j as Map<String, dynamic>)).toList();

        // Filter to only include users with role NGO
        final filtered = parsed.where((u) => u.role.toUpperCase() == 'NGO').toList();

        if (mounted) {
          setState(() {
            _ngos = filtered;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMsg = response.data?['message'] ?? 'Failed to load NGO records.';
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = DioClient.handleError(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'An unexpected error occurred: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateVerificationStatus(String userId, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.baseUrl}/profile/verify/$userId',
        data: {'status': newStatus},
      );

      if (response.data != null && response.data['success'] == true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('NGO status updated to $newStatus.'),
            backgroundColor: newStatus == 'VERIFIED'
                ? AppColors.success
                : newStatus == 'REJECTED'
                    ? AppColors.error
                    : Colors.orange,
          ),
        );
        _fetchNgos(_searchCtrl.text);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(response.data?['message'] ?? 'Failed to update status.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(DioClient.handleError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<ChatUser> get _filteredList {
    if (_selectedStatus == 'All') return _ngos;
    return _ngos
        .where((u) => (u.verificationStatus ?? 'PENDING').toUpperCase() == _selectedStatus.toUpperCase())
        .toList();
  }

  Color _getStatusColor(String? status) {
    final s = status ?? 'PENDING';
    switch (s.toUpperCase()) {
      case 'VERIFIED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  void _showNgoDetailsSheet(ChatUser ngo) {
    final currentStatus = ngo.verificationStatus ?? 'PENDING';
    final statusColor = _getStatusColor(currentStatus);
    final phoneText = (ngo.phone != null && ngo.phone!.isNotEmpty) ? ngo.phone! : 'Not Provided';
    final createdText = (ngo.createdAt != null && ngo.createdAt!.isNotEmpty)
        ? ngo.createdAt!.split('T').first
        : 'N/A';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.foundation_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngo.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: context.borderColor),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: Text('Email Address', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
              subtitle: Text(ngo.email, style: TextStyle(fontSize: 14, color: context.textPrimaryColor)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined, color: Colors.green),
              title: Text('Phone Number', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
              subtitle: Text(phoneText, style: TextStyle(fontSize: 14, color: context.textPrimaryColor)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined, color: Colors.purple),
              title: Text('Role / Type', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
              subtitle: Text(ngo.role, style: TextStyle(fontSize: 14, color: context.textPrimaryColor)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined, color: Colors.orange),
              title: Text('Registered Date', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
              subtitle: Text(createdText, style: TextStyle(fontSize: 14, color: context.textPrimaryColor)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateVerificationStatus(ngo.id, 'REJECTED');
                    },
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateVerificationStatus(ngo.id, 'VERIFIED');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Approve NGO'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'NGO Management',
          style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchNgos(_searchCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: context.surfaceBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _fetchNgos,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'Search NGO by name, email, or phone...',
                    hintStyle: TextStyle(color: context.textSecondaryColor),
                    prefixIcon: Icon(Icons.search, color: context.textSecondaryColor),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetchNgos('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'PENDING', 'VERIFIED', 'REJECTED'].map((st) {
                      final isSel = _selectedStatus.toUpperCase() == st.toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            st == 'All' ? 'All Status' : st,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? AppColors.primary : context.textPrimaryColor,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          backgroundColor: context.inputBg,
                          side: BorderSide(
                            color: isSel ? AppColors.primary : context.borderColor,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedStatus = st;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchNgos(_searchCtrl.text),
              child: _buildBody(list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<ChatUser> list) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: MsSkeleton(height: 100),
        ),
      );
    }

    if (_errorMsg != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.error_outline, size: 54, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _fetchNgos(_searchCtrl.text),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.foundation_outlined, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'No NGO Partners Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No registered NGOs match your search parameters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final ngo = list[idx];
        final currentStatus = ngo.verificationStatus ?? 'PENDING';
        final statusColor = _getStatusColor(currentStatus);
        final phoneText = (ngo.phone != null && ngo.phone!.isNotEmpty) ? ngo.phone! : 'No Phone';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showNgoDetailsSheet(ngo),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(Icons.foundation_outlined, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ngo.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ngo.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          currentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: context.borderColor),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            phoneText,
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (currentStatus.toUpperCase() != 'VERIFIED')
                            TextButton.icon(
                              onPressed: () => _updateVerificationStatus(ngo.id, 'VERIFIED'),
                              icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                              label: const Text('Approve', style: TextStyle(fontSize: 12, color: AppColors.success)),
                            ),
                          if (currentStatus.toUpperCase() != 'REJECTED')
                            TextButton.icon(
                              onPressed: () => _updateVerificationStatus(ngo.id, 'REJECTED'),
                              icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                              label: const Text('Reject', style: TextStyle(fontSize: 12, color: AppColors.error)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
