import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await _repository.loadHistory();
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteLog(String id) async {
    await _repository.deleteEmergencyLog(id);
    _loadHistory();
  }

  void _showDetailModal(EmergencyModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        color: Colors.grey.withOpacity(0.4),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
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
                  _buildDetailRow("Emergency ID", item.id),
                  _buildDetailRow("Time", item.timestamp.toString().substring(0, 19)),
                  _buildDetailRow("Location", item.address),
                  _buildDetailRow("Coordinates", "${item.latitude}, ${item.longitude}"),
                  _buildDetailRow("Device", item.deviceModel),
                  _buildDetailRow("Battery Level", "${item.batteryPercentage}%"),
                  _buildDetailRow("Cloud Upload", item.uploadStatus.toUpperCase()),
                  _buildDetailRow("Guardian Alert", item.guardianStatus.toUpperCase()),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                          ),
                          onPressed: () async {
                            final mapsUri = Uri.parse(item.googleMapsUrl);
                            if (await canLaunchUrl(mapsUri)) {
                              await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.map_rounded, color: Colors.white),
                          label: const Text("OPEN MAPS", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
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
                          label: const Text("SHARE AGAIN", style: TextStyle(color: Colors.white)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      Icon(Icons.history_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        "No emergency logs recorded",
                        style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
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
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _showDetailModal(item),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
                          child: const Icon(Icons.videocam_rounded, color: AppTheme.primaryRed),
                        ),
                        title: Text(
                          item.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${item.timestamp.toString().substring(0, 16)} • ${item.uploadStatus.toUpperCase()}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                ),
    );
  }
}
