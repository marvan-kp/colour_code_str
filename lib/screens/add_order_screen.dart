import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/paint_order.dart';
import '../providers/order_provider.dart';
import '../widgets/glass_container.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _colorController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _customProductController = TextEditingController();
  final _customBaseController = TextEditingController();

  String _selectedProduct = '';
  int _selectedLiters = 1;
  bool _isCustomProduct = false;

  String _selectedBase = '';
  bool _isCustomBase = false;

  double _totalCost = 0.0;

  static const _literOptions = [1, 4, 10, 20];

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_recalc);
    _qtyController.addListener(_recalc);
  }

  @override
  void dispose() {
    _colorController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _customProductController.dispose();
    _customBaseController.dispose();
    super.dispose();
  }

  void _recalc() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final qty = int.tryParse(_qtyController.text) ?? 1;
    setState(() => _totalCost = _selectedLiters * price * qty);
  }

  String get _effectiveProduct =>
      _isCustomProduct ? _customProductController.text.trim() : _selectedProduct;
      
  String get _effectiveBase =>
      _isCustomBase ? _customBaseController.text.trim() : _selectedBase;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_effectiveProduct.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.orange.withOpacity(0.9), content: Text('Select or add a product', style: GoogleFonts.outfit())),
      );
      return;
    }

    final provider = context.read<OrderProvider>();
    final colorCodeRaw = _colorController.text.trim();
    final finalProduct = _effectiveProduct;

    // Check for duplicates (same product and same color code)
    final isDuplicate = provider.orders.any((o) =>
        o.product.toLowerCase() == finalProduct.toLowerCase() &&
        o.colorCode.toLowerCase() == colorCodeRaw.toLowerCase());

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent.withOpacity(0.9), content: Text('Order with this Product and Color Code is already stored!', style: GoogleFonts.outfit())),
      );
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final qty = int.tryParse(_qtyController.text) ?? 1;

    final finalBase = _effectiveBase;

    // Save product and base persistently if they are new
    if (_isCustomProduct) {
      await provider.addProduct(finalProduct);
    }
    if ((_isCustomBase || finalBase.isNotEmpty) && finalProduct.isNotEmpty) {
      await provider.addBaseToProduct(finalProduct, finalBase);
    }

    provider.addOrder(PaintOrder(
      colorCode: colorCodeRaw,
      base: finalBase,
      product: finalProduct,
      subProduct: '',
      canSize: '${_selectedLiters}L',
      liters: _selectedLiters,
      pricePerLiter: price,
      quantity: qty,
      totalCost: _totalCost,
      customer: 'Walk-in',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deviceId: provider.deviceId,
      isSynced: false,
    ));

    Navigator.pop(context);
  }

  void _showProductSearch(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (sheetContext) => Consumer<OrderProvider>(
        builder: (context, provider, child) => _SearchSheet(
          title: 'Search Products',
          hintText: 'Search products...',
          addText: 'Add New Product...',
          items: provider.products,
          onSelected: (p) => setState(() {
            if (_selectedProduct != p) { _selectedBase = ''; _isCustomBase = false; }
            _selectedProduct = p;
            _isCustomProduct = false;
          }),
          onCustom: () => setState(() {
            _isCustomProduct = true; _selectedProduct = '';
            _selectedBase = ''; _isCustomBase = false;
          }),
          onDelete: (p) => provider.deleteProduct(p),
        ),
      ),
    );
  }

  void _showBaseSearch(BuildContext context) {
    if (_selectedProduct.isEmpty && !_isCustomProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.orange.withOpacity(0.9), content: Text('Select a product first', style: GoogleFonts.outfit())),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (sheetContext) => Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final map = provider.productBases;
          final bases = map[_effectiveProduct] ?? <String>[];
          return _SearchSheet(
            title: 'Select Base',
            hintText: 'Search bases...',
            addText: 'Add New Base...',
            items: bases,
            onSelected: (b) => setState(() {
              _selectedBase = b;
              _isCustomBase = false;
            }),
            onCustom: () => setState(() {
              _isCustomBase = true;
              _selectedBase = '';
            }),
            onDelete: (b) => provider.deleteBaseFromProduct(_effectiveProduct, b),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Premium Multi-gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF060B12), Color(0xFF0D1422), Color(0xFF060B12)],
              ),
            ),
          ),
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned(top: -100, right: -120,
                  child: _glow(400, Colors.cyanAccent.withOpacity(0.12))),
                Positioned(bottom: -150, left: -100,
                  child: _glow(450, Colors.purpleAccent.withOpacity(0.1))),
                Positioned(top: 300, left: -70,
                  child: _glow(250, Colors.blueAccent.withOpacity(0.06))),
              ],
            ),
          ),

          SafeArea(
            child: RepaintBoundary(
              child: Column(
                children: [
                  _appBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Product Selection ───────────────────────────────
                          _section('Product Selection', Icons.brush_rounded, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _showProductSearch(context),
                                child: GlassContainer(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  borderRadius: 16, opacity: 0.06,
                                  child: Row(children: [
                                    Icon(Icons.search_rounded, color: Colors.cyanAccent.withOpacity(0.6), size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(
                                      _isCustomProduct ? 'Custom Product' : (_selectedProduct.isEmpty ? 'Tap to Search Products...' : _selectedProduct),
                                      style: GoogleFonts.outfit(
                                        color: _selectedProduct.isEmpty && !_isCustomProduct ? Colors.white30 : Colors.white,
                                        fontSize: 16,
                                        fontWeight: _selectedProduct.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    )),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                                  ]),
                                ),
                              ),
                              if (_isCustomProduct) ...[
                                const SizedBox(height: 16),
                                _inputField(
                                  controller: _customProductController,
                                  label: 'Enter New Product Name',
                                  icon: Icons.add_circle_outline_rounded,
                                  iconColor: Colors.orangeAccent,
                                  validator: (v) => (_isCustomProduct && (v == null || v.trim().isEmpty))
                                      ? 'Required' : null,
                                ),
                              ],
                            ],
                          )),

                          const SizedBox(height: 18),

                          // ── Color & Base ─────────────────────────────────
                          _section('Order Details', Icons.tune_rounded, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _inputField(controller: _colorController, label: 'Color Code', hint: 'e.g. ff90',
                              icon: Icons.palette_rounded,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                            const SizedBox(height: 18),
                            
                            GestureDetector(
                              onTap: () => _showBaseSearch(context),
                              child: GlassContainer(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                borderRadius: 16, opacity: 0.05,
                                child: Row(children: [
                                  Icon(Icons.layers_rounded, color: Colors.cyanAccent.withOpacity(0.6), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(
                                    _isCustomBase ? 'Custom Base' : (_selectedBase.isEmpty ? 'Tap to Select Base Info...' : _selectedBase),
                                    style: GoogleFonts.outfit(
                                      color: _selectedBase.isEmpty && !_isCustomBase ? Colors.white30 : Colors.white,
                                      fontSize: 16,
                                      fontWeight: _selectedBase.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  )),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                                ]),
                              ),
                            ),
                            if (_isCustomBase) ...[
                              const SizedBox(height: 16),
                              _inputField(
                                controller: _customBaseController,
                                label: 'Enter New Base Info',
                                hint: 'e.g. AB1',
                                icon: Icons.add_circle_outline_rounded,
                                iconColor: Colors.orangeAccent,
                                required: false,
                              ),
                            ],
                          ])),

                          const SizedBox(height: 18),

                          // ── Volume & Pricing ──────────────────────────────
                          _section('Volume & Price', Icons.analytics_rounded, child: Column(children: [
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedLiters, isExpanded: true,
                                dropdownColor: const Color(0xFF0D1F2D),
                                icon: const Icon(Icons.expand_more_rounded, color: Colors.cyanAccent),
                                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                items: _literOptions.map((l) => DropdownMenuItem(value: l, child: Text('$l Litre${l > 1 ? 's' : ''}'))).toList(),
                                onChanged: (v) { if (v != null) { setState(() => _selectedLiters = v); _recalc(); } },
                              ),
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            Row(children: [
                              Expanded(child: _inputField(
                                controller: _priceController, label: 'Rate/L (₹)', icon: Icons.currency_rupee_rounded,
                                inputType: TextInputType.number,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              )),
                              const SizedBox(width: 14),
                              Expanded(child: _inputField(
                                controller: _qtyController, label: 'Qty', icon: Icons.numbers_rounded,
                                inputType: TextInputType.number,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              )),
                            ]),
                          ])),

                          const SizedBox(height: 24),

                          // ── Final Estimate ────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.05), blurRadius: 20, spreadRadius: 2)],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('TOTAL ESTIMATE', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  const SizedBox(height: 4),
                                  Text('${_selectedLiters}L × ${_qtyController.text} × ₹${_priceController.text}', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
                                ]),
                                Text('₹${_totalCost.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                              ],
                            ),
                          ).animate()
                           .fadeIn(delay: 600.ms, duration: 600.ms)
                           .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
                           .shimmer(delay: 2.seconds, duration: 2.seconds, color: Colors.cyanAccent.withOpacity(0.1)),
                          
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity, height: 60,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0, 
                              ),
                              child: Text('CREATE ORDER', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                             .boxShadow(begin: const BoxShadow(blurRadius: 10, color: Colors.cyanAccent), end: const BoxShadow(blurRadius: 25, color: Colors.cyanAccent)),
                          ).animate().fadeIn(delay: 700.ms, duration: 600.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      Text('New Order', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
      const Spacer(),
    ]),
  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic);

  Widget _glow(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35), child: const SizedBox.expand()),
  );

  Widget _section(String title, IconData icon, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(children: [
            Icon(icon, size: 16, color: Colors.cyanAccent.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(title.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ]),
        ),
        GlassContainer(padding: const EdgeInsets.all(20), borderRadius: 24, opacity: 0.1, applyBlur: true, blur: 20, child: child),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _inputField({required TextEditingController controller, required String label, required IconData icon, String? hint, Color iconColor = Colors.cyanAccent, TextInputType inputType = TextInputType.text, bool required = true, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, keyboardType: inputType,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
        hintText: hint, hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: iconColor.withOpacity(0.7), size: 18),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: iconColor.withOpacity(0.5))),
      ),
      validator: validator,
    );
  }
}

// ── Generic Searchable Modal ──────────────────────────────────────────────
class _SearchSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String addText;
  final List<String> items;
  final Function(String) onSelected;
  final Function(String) onDelete;
  final VoidCallback onCustom;
  const _SearchSheet({required this.title, required this.hintText, required this.addText, required this.items, required this.onSelected, required this.onCustom, required this.onDelete});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((p) => p.toLowerCase().contains(_query.toLowerCase())).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassContainer(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        borderRadius: 30, opacity: 0.16, applyBlur: true, blur: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(widget.title, style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              style: GoogleFonts.outfit(color: Colors.white),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: GoogleFonts.outfit(color: Colors.white24),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...filtered.map((p) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    title: Text(p, style: GoogleFonts.outfit(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        widget.onDelete(p);
                        Navigator.pop(context); // Close sheet to reflect delete smoothly if simpler
                      },
                    ),
                    onTap: () { widget.onSelected(p); Navigator.pop(context); },
                  )),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline_rounded, color: Colors.orangeAccent),
                    title: Text(widget.addText, style: GoogleFonts.outfit(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    onTap: () { widget.onCustom(); Navigator.pop(context); },
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
