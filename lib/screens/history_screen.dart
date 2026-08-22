import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/emergency_model.dart';
import '../repositories/emergency_repository.dart';
import '../services/notification_service.dart';
import '../widgets/video_player_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final EmergencyRepository _repository = EmergencyRepository();
  final NotificationService _notificationService = NotificationService();

  List<EmergencyModel> _history = [];
  bool _isLoading = true;
  String _themePreset = 'cyber_dark';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await _repository.loadHistory();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = list;
      _themePreset = prefs.getString(AppConstants.keyThemePreset) ?? 'cyber_dark';
      _isLoading = false;
    });
  }

  Future<void> _deleteLog(String id) async {
    await _repository.deleteEmergencyLog(id);
    _loadData();
  }

  void _showDetailModal(EmergencyModel item) {
    final colors = AppTheme.getColors(_themePreset);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Emergency Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteLog(item.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: VideoPlayerWidget(
                      localPath: item.localVideoPath,
                      publicUrl: item.publicVideoUrl,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow("Emergency ID", item.id, colors),
                  _buildDetailRow("Time", item.timestamp.toString().substring(0, 19), colors),
                  _buildDetailRow("Location", item.address, colors),
                  _buildDetailRow("Coordinates", "${item.latitude}, ${item.longitude}", colors),
                  _buildDetailRow("Device", item.deviceModel, colors),
                  _buildDetailRow("Battery Level", "${item.batteryPercentage}%", colors),
                  _buildDetailRow("Cloud Upload", item.uploadStatus.toUpperCase(), colors),
                  _buildDetailRow("Guardian Alert", item.guardianStatus.toUpperCase(), colors),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accentCyan,
                          ),
                          onPressed: () async {
                            final mapsUri = Uri.parse(item.googleMapsUrl);
                            if (await canLaunchUrl(mapsUri)) {
                              await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.map_rounded, color: Colors.black),
                          label: const Text("OPEN MAPS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryRed,
                          ),
                          onPressed: () async {
                            final guardian = await _repository.loadGuardian();
                            await _notificationService.sendGuardianNotification(
                              emergency: item,
                              guardian: guardian,
                              method: 'share',
                            );
                          },
                          icon: const Icon(Icons.share_rounded, color: Colors.white),
                          label: const Text("SHARE AGAIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, SafeStepThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(_themePreset);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Emergency History"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 80, color: colors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        "No emergency logs recorded",
                        style: TextStyle(fontSize: 16, color: colors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return Card(
                      color: colors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colors.cardBorder),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _showDetailModal(item),
                        leading: CircleAvatar(
                          backgroundColor: colors.primaryRed.withOpacity(0.15),
                          child: Icon(Icons.videocam_rounded, color: colors.primaryRed),
                        ),
                        title: Text(
                          item.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        subtitle: Text(
                          "${item.timestamp.toString().substring(0, 16)} • ${item.uploadStatus.toUpperCase()}",
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                      ),
                    );
                  },
                ),
    );
  }
}
