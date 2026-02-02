import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  final BackendService _backendService = BackendService();
  Map<String, bool>? _connectionStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
    });

    final status = await _backendService.getConnectionStatus();
    
    setState(() {
      _connectionStatus = status;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backend Connection Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _checkConnectionStatus,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_connectionStatus != null) ...[
              _buildStatusRow('Firebase', _connectionStatus!['firebase'] ?? false),
              _buildStatusRow('Authentication', _connectionStatus!['authentication'] ?? false),
              _buildStatusRow('Backend API', _connectionStatus!['backend_api'] ?? false),
              const SizedBox(height: 16),
              _buildOverallStatus(),
            ] else
              const Text('Failed to check connection status'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Row(
            children: [
              Icon(
                isConnected ? Icons.check_circle : Icons.error,
                color: isConnected ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatus() {
    final allConnected = _connectionStatus!.values.every((status) => status);
    final anyConnected = _connectionStatus!.values.any((status) => status);
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (allConnected) {
      statusColor = Colors.green;
      statusText = 'All services connected';
      statusIcon = Icons.cloud_done;
    } else if (anyConnected) {
      statusColor = Colors.orange;
      statusText = 'Partial connection';
      statusIcon = Icons.cloud_queue;
    } else {
      statusColor = Colors.red;
      statusText = 'No connection';
      statusIcon = Icons.cloud_off;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
