import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/paint_order.dart';
import '../providers/order_provider.dart';
import '../services/connectivity_service.dart';
import '../widgets/glass_container.dart';
import '../services/biometric_service.dart';
import '../widgets/smooth_route.dart';
import 'sync_center_screen.dart';
import 'add_order_screen.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Advanced Multi-Layered Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF03070C), Color(0xFF0A0F1A)],
              ),
            ),
          ),
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned(top: -150, left: -100,
                  child: _glow(450, Colors.cyanAccent.withValues(alpha: 0.12))),
                Positioned(bottom: -150, right: -100,
                  child: _glow(500, Colors.purpleAccent.withValues(alpha: 0.1))),
                Positioned(top: 200, right: -100,
                  child: _glow(350, Colors.blueAccent.withValues(alpha: 0.08))),
                Positioned(bottom: 250, left: -80,
                  child: _glow(280, Colors.tealAccent.withValues(alpha: 0.06))),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                 RepaintBoundary(child: _TopBar()),
                 RepaintBoundary(child: _SearchBar()),
                 const Expanded(child: _OrderList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: -5)],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context, SmoothPageRoute(child: const AddOrderScreen())),
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add_rounded, weight: 700),
          label: Text('New Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          elevation: 0,
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.25))
         .boxShadow(begin: const BoxShadow(blurRadius: 10, color: Colors.cyanAccent), end: const BoxShadow(blurRadius: 25, color: Colors.cyanAccent)),
      ),
    );
  }

  Widget _glow(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35), child: const SizedBox.expand()),
  );
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();
    final isOnline = p.networkStatus == NetworkStatus.online;
    final syncing = p.isSyncing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2))),
          child: Image.asset('assets/logo.png', fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BRIGHTWAY SALES', 
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: syncing ? Colors.yellowAccent : (isOnline ? Colors.greenAccent : Colors.redAccent),
                  boxShadow: [BoxShadow(
                    color: (syncing ? Colors.yellowAccent : (isOnline ? Colors.greenAccent : Colors.redAccent)).withValues(alpha: 0.6),
                    blurRadius: 8,
                  )],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(syncing ? 'Syncingâ€¦' : (isOnline ? 'Active Online' : 'Offline Mode'),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.w500)),
              ),
            ]),
          ]),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _showSettings(context),
          child: GlassContainer(
            padding: const EdgeInsets.all(12), borderRadius: 14, opacity: 0.08,
            child: const Icon(Icons.settings_suggest_rounded, color: Colors.cyanAccent, size: 22)),
        ),
        const SizedBox(width: 10),
        syncing
            ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.cyanAccent))
            : GestureDetector(
                onTap: () => context.read<OrderProvider>().refresh(),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12), borderRadius: 14, opacity: 0.08,
                  child: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent, size: 22)),
              ),
      ]),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic);
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  final BiometricService _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isEnabled();
    setState(() {
      _isBiometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      borderRadius: 30,
      opacity: 0.15,
      applyBlur: true,
      blur: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SETTINGS', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          if (_isBiometricAvailable)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fingerprint_rounded, color: Colors.cyanAccent),
              title: Text('Biometric Login', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Unlock app using fingerprint/face', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
              trailing: Switch(
                value: _biometricEnabled,
                activeThumbColor: Colors.cyanAccent,
                onChanged: (val) async {
                  await _biometricService.setEnabled(val);
                  setState(() => _biometricEnabled = val);
                },
              ),
            )
          else
            Text('Biometric authentication is not supported on this device.', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
          
          const Divider(color: Colors.white10, height: 32),
          
          ListTile(
            onTap: () {
              Navigator.pop(context); // Close sheet
              Navigator.push(context, SmoothPageRoute(child: const SyncCenterScreen()));
            },
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.sync_rounded, color: Colors.purpleAccent, size: 20),
            ),
            title: Text('Sync Center', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('Manage multi-device cloud backup', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ),

          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: GoogleFonts.outfit(color: Colors.white38, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        borderRadius: 20, opacity: 0.05, applyBlur: true, blur: 15,
        child: TextField(
          onChanged: context.read<OrderProvider>().setSearchQuery,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, letterSpacing: 0.2),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search orders, codes, products...',
            hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.cyanAccent.withValues(alpha: 0.4), size: 20),
          ),
        ),
      ),
    ).animate()
     .fadeIn(delay: 200.ms, duration: 600.ms)
     .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList();
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    if (orders.isEmpty) {
      return Center(child: Text('No orders found', style: GoogleFonts.outfit(color: Colors.white24)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _OrderTile(order: orders[i]),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final PaintOrder order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: GlassContainer(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        opacity: 0.08, applyBlur: false, // Keep list scroll fast by disabling tile-level blur
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.1)),
            ),
            child: Text(order.canSize,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.cyanAccent, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.colorCode,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 0.5)),
            const SizedBox(height: 1),
            Row(children: [
              Text(order.product, style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38, fontWeight: FontWeight.w400)),
              if (order.base.isNotEmpty) ...[
                Text('  -  ', style: GoogleFonts.outfit(color: Colors.white10, fontSize: 13)),
                Text(order.base, style: GoogleFonts.outfit(fontSize: 14, color: Colors.white24)),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${order.totalCost.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.cyanAccent, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Icon(order.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              size: 14, color: order.isSynced ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.orangeAccent.withValues(alpha: 0.4)),
          ]),
        ]),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final PaintOrder order;
  const _OrderDetailSheet({required this.order});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  late int _editLiters;
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  late double _calcTotal;

  static const _literOptions = [1, 4, 10, 20];

  @override
  void initState() {
    super.initState();
    _editLiters = widget.order.liters;
    _priceCtrl = TextEditingController(text: widget.order.pricePerLiter.toStringAsFixed(2));
    _qtyCtrl = TextEditingController(text: widget.order.quantity.toString());
    _calcTotal = widget.order.totalCost;

    _priceCtrl.addListener(_recalc);
    _qtyCtrl.addListener(_recalc);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _recalc() {
    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    setState(() => _calcTotal = _editLiters * price * qty);
    _autoSave();
  }

  void _autoSave() {
    final price = double.tryParse(_priceCtrl.text) ?? widget.order.pricePerLiter;
    final qty = int.tryParse(_qtyCtrl.text) ?? widget.order.quantity;
    
    final updated = PaintOrder(
      id: widget.order.id,
      colorCode: widget.order.colorCode,
      base: widget.order.base,
      product: widget.order.product,
      subProduct: widget.order.subProduct,
      canSize: '${_editLiters}L',
      liters: _editLiters,
      pricePerLiter: price,
      quantity: qty,
      totalCost: _calcTotal,
      customer: widget.order.customer,
      createdAt: widget.order.createdAt,
      updatedAt: DateTime.now(),
      deviceId: widget.order.deviceId,
      isSynced: false,
    );

    context.read<OrderProvider>().addOrder(updated);
  }

  void _confirmDelete(BuildContext context) {
    final orderProvider = context.read<OrderProvider>();
    final orderId = widget.order.id;
    final productName = widget.order.product;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Order?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Remove "$productName"?', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              orderProvider.deleteOrder(orderId);
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pop();
            },
            child: Text('DELETE', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassContainer(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        borderRadius: 30,
        opacity: 0.15,
        applyBlur: true,
        blur: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.order.colorCode, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.cyanAccent)),
                  Row(children: [
                    Text(widget.order.product, style: GoogleFonts.outfit(fontSize: 18, color: Colors.white38, fontWeight: FontWeight.w500)),
                    if (widget.order.base.isNotEmpty) ...[
                      Text('  -  ', style: GoogleFonts.outfit(color: Colors.white12, fontSize: 16)),
                      Text(widget.order.base, style: GoogleFonts.outfit(fontSize: 18, color: Colors.white24)),
                    ],
                  ]),
                ],
              )),
              _actionBtn(
                icon: Icons.delete_forever_rounded,
                label: 'Delete',
                color: Colors.redAccent,
                onTap: () => _confirmDelete(context),
              ),
            ]),

            const Divider(color: Colors.white10, height: 30),

            Text('ADJUST VOLUME & PRICE', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 16),
            
            _editSection('Can Size', child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _editLiters, isExpanded: true,
                dropdownColor: const Color(0xFF0D1F2D),
                icon: const Icon(Icons.expand_more_rounded, color: Colors.cyanAccent),
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                items: _literOptions.map((l) => DropdownMenuItem(value: l, child: Text('$l Litre${l > 1 ? 's' : ''}'))).toList(),
                onChanged: (v) { if (v != null) { setState(() => _editLiters = v); _recalc(); } },
              ),
            )),
            
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _editField(_priceCtrl, 'Price/L (₹)', Icons.currency_rupee_rounded)),
              const SizedBox(width: 14),
              Expanded(child: _editField(_qtyCtrl, 'Qty', Icons.numbers_rounded)),
            ]),
            
            const SizedBox(height: 24),
            // Updated Total Highlight
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TOTAL ESTIMATE', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('${_editLiters}L x ${_qtyCtrl.text} x ₹${_priceCtrl.text}', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ]),
                Text('₹${_calcTotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
              ]),
            ),
            
            const SizedBox(height: 10),
            Center(child: Text('Updates save automatically', style: GoogleFonts.outfit(color: Colors.white10, fontSize: 11))),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        GlassContainer(
          padding: const EdgeInsets.all(10), borderRadius: 12, opacity: 0.07, tint: color,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _editSection(String label, {required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 6),
      GlassContainer(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), borderRadius: 12, opacity: 0.05, child: child),
    ]);
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon) {
    return _editSection(label, child: TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: (_) => _recalc(), // Recalculate as they type
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        border: InputBorder.none,
        prefixIcon: Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.5), size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 30),
      ),
    ));
  }
}
