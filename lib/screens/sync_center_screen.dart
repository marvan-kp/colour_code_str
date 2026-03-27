import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../services/firestore_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/glass_container.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<Map<String, dynamic>> _otherDevices = [];
  bool _isLoadingDevices = false;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    if (!mounted) return;
    setState(() => _isLoadingDevices = true);
    final devices = await _firestore.getAllDevicesStatus();
    if (mounted) {
      setState(() {
        _otherDevices = devices;
        _isLoadingDevices = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF03070C), Color(0xFF0A111A)],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      _thisDeviceCard(provider),
                      const SizedBox(height: 24),
                      _networkStatus(provider),
                      const SizedBox(height: 32),
                      _otherDevicesSection(),
                      const SizedBox(height: 100), // Buffer for FAB
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Force Sync Button
          Positioned(
            bottom: 30, right: 30, left: 30,
            child: SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: provider.isSyncing ? null : () => provider.refresh(isFullSync: true),
                icon: provider.isSyncing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.sync_rounded),
                label: Text(provider.isSyncing ? 'SYNCING...' : 'FORCE FULL SYNC', 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  shadowColor: Colors.cyanAccent.withOpacity(0.4),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      const SizedBox(width: 8),
      Text('Sync Center', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      const Spacer(),
      IconButton(
        icon: Icon(Icons.refresh_rounded, color: Colors.cyanAccent.withOpacity(0.6)),
        onPressed: _fetchDevices,
      ),
    ]),
  ).animate().fadeIn().slideY(begin: -0.2, end: 0);

  Widget _thisDeviceCard(OrderProvider provider) {
    final metrics = provider.syncMetrics;
    final lastSyncStr = metrics.lastSyncTime != null 
        ? DateFormat('hh:mm a').format(metrics.lastSyncTime!)
        : 'Never';

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIS TERMINAL', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(provider.deviceId.substring(0, 8).toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.smartphone_rounded, color: Colors.white.withOpacity(0.2), size: 40),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _statItem('Unsynced', metrics.unsyncedCount.toString(), Icons.cloud_upload_outlined, Colors.orangeAccent),
              const SizedBox(width: 24),
              _statItem('Last Sync', lastSyncStr, Icons.access_time_rounded, Colors.greenAccent),
            ],
          ),
          if (metrics.lastError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(metrics.lastError!, style: GoogleFonts.outfit(color: Colors.redAccent.withOpacity(0.8), fontSize: 11))),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _networkStatus(OrderProvider provider) {
    final isOnline = provider.networkStatus == NetworkStatus.online;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: (isOnline ? Colors.greenAccent : Colors.redAccent).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isOnline ? Colors.greenAccent : Colors.redAccent).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: isOnline ? Colors.greenAccent : Colors.redAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(isOnline ? 'CLOUD CONNECTED' : 'OFFLINE MODE', 
            style: GoogleFonts.outfit(color: isOnline ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const Spacer(),
          Text(isOnline ? 'Active' : 'Disconnected', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _otherDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('NETWORK TERMINALS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const Spacer(),
            if (_isLoadingDevices) 
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
          ],
        ),
        const SizedBox(height: 16),
        if (_otherDevices.isEmpty && !_isLoadingDevices)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.hub_outlined, color: Colors.white10, size: 48),
                  const SizedBox(height: 12),
                  Text('No other devices found', style: GoogleFonts.outfit(color: Colors.white24)),
                ],
              ),
            ),
          )
        else
          ..._otherDevices.where((d) => d['id'] != context.read<OrderProvider>().deviceId).map((device) => _deviceTile(device)),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _deviceTile(Map<String, dynamic> device) {
    final lastSync = device['lastSync'] != null ? DateTime.parse(device['lastSync']) : null;
    final timeStr = lastSync != null ? DateFormat('MMM d, hh:mm a').format(lastSync) : 'Unknown';
    final isRecent = lastSync != null && DateTime.now().difference(lastSync).inMinutes < 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.computer_rounded, color: Colors.cyanAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device['id'].toString().substring(0, 8).toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Last Sync: $timeStr', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${device['orderCount'] ?? 0} Orders', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isRecent ? Colors.greenAccent : Colors.white12).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isRecent ? 'ONLINE' : 'AWAY', 
                  style: GoogleFonts.outfit(color: isRecent ? Colors.greenAccent : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
