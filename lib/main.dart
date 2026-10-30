import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const NakshatraSalesApp());

const businessName = 'Nakshatra Sales';
const businessWhatsApp = '919022657558';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.description,
    required this.code,
    this.imageUrl = '',
    this.variants = const [],
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final String description;
  final String code;
  final String imageUrl;
  final List<String> variants;
}

const demoProducts = <Product>[
  Product(
    id: 'P001',
    name: 'Hex Bolt',
    category: 'Fasteners',
    price: 12,
    unit: 'piece',
    description: 'Durable hex-head bolt for general fastening applications. Confirm material and thread specifications before ordering.',
    code: 'NS-FAS-001',
    variants: ['M6', 'M8', 'M10', 'M12'],
  ),
  Product(
    id: 'P002',
    name: 'Wall Plug Set',
    category: 'Fasteners',
    price: 85,
    unit: 'packet',
    description: 'Wall plugs for common fixing applications. Packet quantity and compatible screw size can be confirmed with the seller.',
    code: 'NS-FAS-002',
    variants: ['6 mm', '8 mm', '10 mm'],
  ),
  Product(
    id: 'P003',
    name: 'Adjustable Spanner',
    category: 'Hand Tools',
    price: 220,
    unit: 'piece',
    description: 'Adjustable spanner for gripping and turning nuts and bolts.',
    code: 'NS-TOL-001',
    variants: ['6 inch', '8 inch', '10 inch'],
  ),
  Product(
    id: 'P004',
    name: 'Door Hinge',
    category: 'Door Fittings',
    price: 65,
    unit: 'piece',
    description: 'General-purpose door hinge. Please confirm finish and dimensions before placing the order.',
    code: 'NS-DRF-001',
    variants: ['2 inch', '3 inch', '4 inch'],
  ),
  Product(
    id: 'P005',
    name: 'PVC Elbow',
    category: 'Plumbing',
    price: 18,
    unit: 'piece',
    description: 'PVC elbow fitting for compatible plumbing applications. Check diameter and angle before ordering.',
    code: 'NS-PLB-001',
    variants: ['½ inch', '¾ inch', '1 inch'],
  ),
  Product(
    id: 'P006',
    name: 'Measuring Tape',
    category: 'Hand Tools',
    price: 120,
    unit: 'piece',
    description: 'Compact measuring tape for everyday measuring tasks.',
    code: 'NS-TOL-002',
    variants: ['3 m', '5 m', '7.5 m'],
  ),
];

class CartLine {
  CartLine({required this.product, required this.variant, this.quantity = 1});
  final Product product;
  final String variant;
  int quantity;

  String get key => '${product.id}::$variant';
  double get total => product.price * quantity;
}

class NakshatraSalesApp extends StatefulWidget {
  const NakshatraSalesApp({super.key});

  @override
  State<NakshatraSalesApp> createState() => _NakshatraSalesAppState();
}

class _NakshatraSalesAppState extends State<NakshatraSalesApp> {
  final Map<String, CartLine> _cart = {};
  String _customerName = '';
  String _customerPhone = '';
  String _deliveryAddress = '';

  int get _cartCount => _cart.values.fold(0, (sum, line) => sum + line.quantity);
  double get _cartTotal => _cart.values.fold(0, (sum, line) => sum + line.total);

  void _addToCart(Product product, String variant, int quantity) {
    final line = CartLine(product: product, variant: variant, quantity: quantity);
    setState(() {
      if (_cart.containsKey(line.key)) {
        _cart[line.key]!.quantity += quantity;
      } else {
        _cart[line.key] = line;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 1)),
    );
  }

  void _changeQuantity(String key, int delta) {
    setState(() {
      final line = _cart[key];
      if (line == null) return;
      line.quantity += delta;
      if (line.quantity <= 0) _cart.remove(key);
    });
  }

  void _removeLine(String key) => setState(() => _cart.remove(key));

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _customerName);
    final phoneController = TextEditingController(text: _customerPhone);
    final addressController = TextEditingController(text: _deliveryAddress);

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Delivery details', style: Theme.of(sheetContext).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Customer name', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile number', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().length < 8) ? 'Enter a valid mobile number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Delivery address / notes', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) Navigator.pop(sheetContext, true);
                  },
                  child: const Text('Continue to WhatsApp'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (submitted != true || !mounted) return;
    _customerName = nameController.text.trim();
    _customerPhone = phoneController.text.trim();
    _deliveryAddress = addressController.text.trim();

    final lines = _cart.values.map((line) =>
      '• ${line.product.name} (${line.variant.isEmpty ? 'Standard' : line.variant})'
      '\n  Qty: ${line.quantity} ${line.product.unit}(s) × ${_money(line.product.price)} = ${_money(line.total)}'
      '\n  Code: ${line.product.code}'
    ).join('\n\n');

    final message = '''
Hello $businessName,
I'd like to place an order:

$lines

Order total: ${_money(_cartTotal)}

Customer: $_customerName
Mobile: $_customerPhone
Delivery address / notes: ${_deliveryAddress.isEmpty ? 'Not provided' : _deliveryAddress}

Please confirm availability, final pricing, and delivery details.
''';
    final uri = Uri.parse('https://wa.me/$businessWhatsApp?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp. Please check that it is installed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: businessName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457A7)),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, surfaceTintColor: Colors.white),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: CatalogScreen(
        cartCount: _cartCount,
        onOpenCart: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => CartScreen(
            cart: _cart,
            total: _cartTotal,
            onQuantity: _changeQuantity,
            onRemove: _removeLine,
            onCheckout: _checkout,
          ),
        )),
        onAdd: _addToCart,
      ),
    );
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.cartCount, required this.onOpenCart, required this.onAdd});
  final int cartCount;
  final VoidCallback onOpenCart;
  final void Function(Product, String, int) onAdd;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _query = '';
  String _category = 'All';

  List<String> get _categories => ['All', ...demoProducts.map((p) => p.category).toSet()];

  @override
  Widget build(BuildContext context) {
    final products = demoProducts.where((p) {
      final matchesCategory = _category == 'All' || p.category == _category;
      final search = _query.toLowerCase();
      final matchesSearch = p.name.toLowerCase().contains(search) ||
          p.code.toLowerCase().contains(search) ||
          p.category.toLowerCase().contains(search);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.handyman_outlined, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(businessName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Hardware & supplies', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ])),
        ]),
        actions: [
          IconButton(
            onPressed: widget.onOpenCart,
            tooltip: 'Shopping cart',
            icon: Badge(label: Text('${widget.cartCount}'), child: const Icon(Icons.shopping_cart_outlined)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search hardware products',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () => setState(() => _query = ''), icon: const Icon(Icons.close)),
              ),
            ),
          )),
          SliverToBoxAdapter(child: SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                );
              },
            ),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Expanded(child: Text('Products', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              Text('${products.length} items', style: Theme.of(context).textTheme.bodySmall),
            ]),
          )),
          if (products.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No products found. Try another search.')))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    product: products[index],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: products[index], onAdd: widget.onAdd),
                    )),
                  ),
                  childCount: products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(children: [
          const Expanded(child: Row(children: [
            Icon(Icons.storefront_outlined),
            SizedBox(width: 8),
            Text('Browse hardware', style: TextStyle(fontWeight: FontWeight.w600)),
          ])),
          TextButton.icon(onPressed: widget.onOpenCart, icon: const Icon(Icons.shopping_cart_outlined), label: Text('Cart (${widget.cartCount})')),
        ]),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFEFF3F8),
              child: const Center(child: Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFF718096))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.category.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2457A7), letterSpacing: .6)),
              const SizedBox(height: 4),
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text('From ${_money(product.price)} / ${product.unit}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                child: const Text('View details'),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product, required this.onAdd});
  final Product product;
  final void Function(Product, String, int) onAdd;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _variant = '';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _variant = widget.product.variants.isEmpty ? '' : widget.product.variants.first;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          height: 230,
          decoration: BoxDecoration(color: const Color(0xFFEFF3F8), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.inventory_2_outlined, size: 88, color: Color(0xFF718096)),
        ),
        const SizedBox(height: 20),
        Text(p.category.toUpperCase(), style: const TextStyle(color: Color(0xFF2457A7), fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(p.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('${_money(p.price)} / ${p.unit}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Product code: ${p.code}', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        Text(p.description, style: const TextStyle(height: 1.5)),
        if (p.variants.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Select size / variant', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: p.variants.map((v) => ChoiceChip(
            label: Text(v), selected: _variant == v, onSelected: (_) => setState(() => _variant = v),
          )).toList()),
        ],
        const SizedBox(height: 24),
        Row(children: [
          Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove_circle_outline)),
          Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add_circle_outline)),
        ]),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            widget.onAdd(p, _variant, _quantity);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Add to cart'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ]),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key, required this.cart, required this.total, required this.onQuantity,
    required this.onRemove, required this.onCheckout,
  });
  final Map<String, CartLine> cart;
  final double total;
  final void Function(String, int) onQuantity;
  final void Function(String) onRemove;
  final Future<void> Function() onCheckout;

  @override
  Widget build(BuildContext context) {
    final lines = cart.values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: lines.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.black26),
              SizedBox(height: 12),
              Text('Your cart is empty'),
              SizedBox(height: 4),
              Text('Browse products and add items to order.', style: TextStyle(color: Colors.black54)),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lines.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == lines.length) {
                  return Card(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Row(children: [
                        const Expanded(child: Text('Estimated total', style: TextStyle(fontWeight: FontWeight.w600))),
                        Text(_money(total), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      const Text('Final availability, taxes, delivery charges, and pricing will be confirmed by Nakshatra Sales.', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ]),
                  ));
                }
                final line = lines[index];
                return Card(child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFEFF3F8), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF718096))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(line.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${line.variant.isEmpty ? 'Standard' : line.variant} • ${line.product.unit}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      Text(_money(line.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(visualDensity: VisualDensity.compact, onPressed: () => onQuantity(line.key, -1), icon: const Icon(Icons.remove_circle_outline)),
                        Text('${line.quantity}'),
                        IconButton(visualDensity: VisualDensity.compact, onPressed: () => onQuantity(line.key, 1), icon: const Icon(Icons.add_circle_outline)),
                      ]),
                    ])),
                    IconButton(onPressed: () => onRemove(line.key), tooltip: 'Remove', icon: const Icon(Icons.delete_outline)),
                  ]),
                ));
              },
            ),
      bottomNavigationBar: lines.isEmpty ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: onCheckout,
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Order on WhatsApp'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ),
    );
  }
}

String _money(double value) => '₹${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
