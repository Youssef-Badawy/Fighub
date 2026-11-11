import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_service.dart';
import 'chat_page.dart';
import 'cloudinary_service.dart';

const printCategories = <Map<String, dynamic>>[
  {'name': 'تيشيرتات', 'icon': Icons.checkroom},
  {'name': 'مجات', 'icon': Icons.coffee},
  {'name': 'هدايا', 'icon': Icons.card_giftcard},
  {'name': 'مجسمات', 'icon': Icons.toys},
  {'name': 'ميداليات', 'icon': Icons.workspace_premium},
  {'name': 'استيكرات', 'icon': Icons.sticky_note_2},
  {'name': 'خشبيات', 'icon': Icons.forest},
  {'name': 'سلاسل', 'icon': Icons.link},
  {'name': 'حظاظات', 'icon': Icons.circle_outlined},
  {'name': 'شنط', 'icon': Icons.shopping_bag},
  {'name': 'طابلوه', 'icon': Icons.image},
  {'name': 'صور', 'icon': Icons.photo},
  {'name': 'كابات', 'icon': Icons.sports_baseball},
  {'name': 'برواز', 'icon': Icons.crop_portrait},
  {'name': 'كوميكس', 'icon': Icons.menu_book},
  {'name': 'اعلام', 'icon': Icons.flag},
  {'name': 'نوت بوك', 'icon': Icons.book},
  {'name': 'اقلام', 'icon': Icons.edit},
  {'name': 'محفظة', 'icon': Icons.account_balance_wallet},
];

class PrintMarketplacePage extends StatelessWidget {
  const PrintMarketplacePage({super.key});

  @override
  Widget build(BuildContext context) => const _PrintMarketplaceHome();
}

class _PrintMarketplaceHome extends StatefulWidget {
  const _PrintMarketplaceHome();

  @override
  State<_PrintMarketplaceHome> createState() => _PrintMarketplaceHomeState();
}

class _PrintMarketplaceHomeState extends State<_PrintMarketplaceHome> {
  final _db = FirebaseFirestore.instance;
  String? _selectedCategory;

  Future<void> _createBusiness() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    final name = TextEditingController();
    final phone = TextEditingController();
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تفعيل حساب شركة / محل'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم الشركة أو المحل'), validator: (v) => v == null || v.trim().isEmpty ? 'اكتب اسم الشركة' : null),
              TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم التواصل'), validator: (v) => v == null || v.trim().isEmpty ? 'اكتب رقم التواصل' : null),
              TextFormField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'نبذة عن الشركة')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('حفظ')),
        ],
      ),
    );
    if (result != true || !mounted) return;
    await _db.collection('print_businesses').doc(user.uid).set({
      'ownerId': user.uid,
      'name': name.text.trim(),
      'phone': phone.text.trim(),
      'description': description.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'active': true,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D PRINTING'),
        leading: _selectedCategory == null ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedCategory = null),
        ),
        actions: [
          if (user != null && !user.isAnonymous)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.collection('print_businesses').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                final isBusiness = snapshot.data?.exists == true;
                return IconButton(
                  tooltip: isBusiness ? 'لوحة شركتي' : 'تفعيل حساب شركة',
                  icon: Icon(isBusiness ? Icons.store : Icons.add_business),
                  onPressed: () async {
                    if (isBusiness) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PrintBusinessPage(businessId: user.uid)));
                    } else {
                      await _createBusiness();
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: _selectedCategory == null ? _buildCategories() : _buildBusinesses(),
    );
  }

  Widget _buildCategories() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .95),
      itemCount: printCategories.length,
      itemBuilder: (context, index) {
        final item = printCategories[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => _selectedCategory = item['name'] as String),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(item['icon'] as IconData, size: 34, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(item['name'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildBusinesses() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('print_products').where('category', isEqualTo: _selectedCategory).where('active', isEqualTo: true).snapshots(),
      builder: (context, productsSnapshot) {
        if (productsSnapshot.hasError) return const Center(child: Text('تعذر تحميل المنتجات'));
        if (!productsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final sellerIds = productsSnapshot.data!.docs.map((d) => d.data()['sellerId'] as String? ?? '').where((id) => id.isNotEmpty).toSet().toList();
        if (sellerIds.isEmpty) return const Center(child: Text('لا توجد منتجات في هذا القسم حاليًا'));
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('print_businesses').where(FieldPath.documentId, whereIn: sellerIds.take(10).toList()).snapshots(),
          builder: (context, businessesSnapshot) {
            if (!businessesSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final businesses = businessesSnapshot.data!.docs;
            return ListView(
              padding: const EdgeInsets.all(12),
              children: businesses.map((business) {
                final data = business.data();
                final count = productsSnapshot.data!.docs.where((p) => p.data()['sellerId'] == business.id).length;
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.storefront)),
                    title: Text(data['name']?.toString() ?? 'شركة'),
                    subtitle: Text('${data['description'] ?? ''}\n$count منتج في قسم $_selectedCategory'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrintBusinessPage(businessId: business.id, initialCategory: _selectedCategory))),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class PrintBusinessPage extends StatefulWidget {
  final String businessId;
  final String? initialCategory;
  const PrintBusinessPage({super.key, required this.businessId, this.initialCategory});

  @override
  State<PrintBusinessPage> createState() => _PrintBusinessPageState();
}

class _PrintBusinessPageState extends State<PrintBusinessPage> {
  final _db = FirebaseFirestore.instance;
  bool _busy = false;

  bool get _isOwner => FirebaseAuth.instance.currentUser?.uid == widget.businessId;

  Future<void> _addProduct() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController(text: '1');
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String category = widget.initialCategory ?? printCategories.first['name'] as String;
    XFile? image;
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
        title: const Text('إضافة منتج 3D PRINTING'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم المنتج'), validator: (v) => v == null || v.trim().isEmpty ? 'اكتب اسم المنتج' : null),
            TextFormField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر بالجنيه'), validator: (v) => double.tryParse(v ?? '') == null ? 'اكتب سعرًا صحيحًا' : null),
            TextFormField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد القطع المتوفرة'), validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 0 ? 'اكتب كمية صحيحة' : null),
            DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'القسم'), items: printCategories.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'] as String))).toList(), onChanged: (v) => refresh(() => category = v ?? category)),
            TextFormField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'وصف المنتج')),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: () async { final files = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85); if (files != null) refresh(() => image = files); }, icon: const Icon(Icons.image), label: Text(image == null ? 'اختيار صورة' : 'تم اختيار الصورة')),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, {'name': name.text.trim(), 'price': price.text.trim(), 'stock': int.parse(stock.text), 'category': category, 'description': description.text.trim(), 'image': image}); }, child: const Text('نشر')),
        ],
      )),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      String imageUrl = '';
      final selectedImage = picked['image'] as XFile?;
      if (selectedImage != null) imageUrl = await CloudinaryService().uploadImage(selectedImage);
      await _db.collection('print_products').add({
        'sellerId': widget.businessId,
        'name': picked['name'],
        'price': picked['price'],
        'stockQuantity': picked['stock'],
        'category': picked['category'],
        'description': picked['description'],
        'imageUrl': imageUrl,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إضافة المنتج: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editStock(
    DocumentReference<Map<String, dynamic>> reference,
    int currentStock,
  ) async {
    final controller = TextEditingController(text: currentStock.toString());
    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الكمية المتوفرة'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد القطع'),
            validator: (value) {
              final quantity = int.tryParse(value ?? '');
              return quantity == null || quantity < 0
                  ? 'اكتب كمية صحيحة'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (shouldSave != true || !mounted) {
      controller.dispose();
      return;
    }
    try {
      await reference.update({
        'stockQuantity': int.parse(controller.text),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث الكمية: $error')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _requestDesign(Map<String, dynamic> business) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل حسابك أولًا لإرسال طلب تصميم')));
      return;
    }
    final notes = TextEditingController();
    String category = widget.initialCategory ?? printCategories.first['name'] as String;
    XFile? image;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
        title: const Text('اطلب تصميمك'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'عايز التصميم على إيه؟'), items: printCategories.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'] as String))).toList(), onChanged: (v) => refresh(() => category = v ?? category)),
          TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'تفاصيل أو ملاحظات عن التصميم')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () async { final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85); if (file != null) refresh(() => image = file); }, icon: const Icon(Icons.upload_file), label: Text(image == null ? 'ارفع صورة التصميم' : 'تم اختيار الصورة')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, {'category': category, 'notes': notes.text.trim(), 'image': image}), child: const Text('إرسال الطلب')),
        ],
      )),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      String imageUrl = '';
      final selectedImage = result['image'] as XFile?;
      if (selectedImage != null) imageUrl = await CloudinaryService().uploadImage(selectedImage);
      await _db.collection('print_design_requests').add({
        'companyId': widget.businessId,
        'companyName': business['name'] ?? '',
        'customerId': user.uid,
        'customerName': user.displayName ?? '',
        'category': result['category'],
        'notes': result['notes'],
        'imageUrl': imageUrl,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب التصميم للشركة')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الطلب: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buyProduct(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل حسابك أولًا لإتمام الطلب')));
      return;
    }
    if (user.uid == widget.businessId || _busy) return;
    setState(() => _busy = true);
    final orderRef = _db.collection('products').doc();
    final productRef = _db.collection('print_products').doc(productId);
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) throw StateError('المنتج غير موجود');
        final data = snapshot.data()!;
        final quantity = (data['stockQuantity'] as num?)?.toInt() ?? 0;
        if (quantity < 1 || data['active'] != true) throw StateError('الكمية غير متاحة حاليًا');
        transaction.update(productRef, {'stockQuantity': quantity - 1, 'updatedAt': FieldValue.serverTimestamp()});
        transaction.set(orderRef, {
          'productType': 'print_order',
          'sourcePrintProductId': productId,
          'sellerId': widget.businessId,
          'buyerId': user.uid,
          'reservedBy': user.uid,
          'name': data['name'] ?? 'طلب طباعة',
          'price': data['price']?.toString() ?? '0',
          'category': data['category'] ?? '',
          'condition': 'New',
          'description': data['description'] ?? '',
          'paymentMethod': 'Cash on Delivery',
          'imagePath': data['imageUrl'] ?? '',
          'imagePaths': (data['imageUrl'] as String?)?.isNotEmpty == true ? [data['imageUrl']] : <String>[],
          'status': 'Reserved',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      final orderData = await orderRef.get();
      final data = orderData.data()!;
      final chatId = await ChatService().addReservedProductToChat(
        productId: orderRef.id,
        productName: data['name'] as String,
        price: data['price'] as String,
        imagePaths: (data['imagePaths'] as List? ?? []).whereType<String>().toList(),
        sellerId: widget.businessId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الطلب وإضافته للمحادثات. بيانات الشحن متاحة من المحادثة.')));
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId, productName: 'حساب المشتريات')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إتمام الطلب: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('متجر ${widget.businessId.substring(0, widget.businessId.length > 8 ? 8 : widget.businessId.length)}')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('print_businesses').doc(widget.businessId).snapshots(),
        builder: (context, businessSnapshot) {
          final business = businessSnapshot.data?.data() ?? {};
          return Column(children: [
            if (_isOwner) Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              Expanded(child: FilledButton.icon(onPressed: _busy ? null : _addProduct, icon: const Icon(Icons.add), label: const Text('إضافة منتج'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrintRequestsPage(companyId: widget.businessId))), icon: const Icon(Icons.inbox), label: const Text('طلبات التصميم'))),
            ])),
            if (!_isOwner) Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : () => _requestDesign(business), icon: const Icon(Icons.brush), label: const Text('اطلب تصميمك')))),
            if (_busy) const LinearProgressIndicator(),
            Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('print_products').where('sellerId', isEqualTo: widget.businessId).where('active', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (widget.initialCategory != null) docs = docs.where((d) => d.data()['category'] == widget.initialCategory).toList();
                if (docs.isEmpty) return const Center(child: Text('لا توجد منتجات متاحة حاليًا'));
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final stock = (data['stockQuantity'] as num?)?.toInt() ?? 0;
                    final imageUrl = data['imageUrl'] as String? ?? '';
                    return Card(child: ListTile(
                      leading: imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.inventory_2)) : CircleAvatar(backgroundImage: NetworkImage(imageUrl)),
                      title: Text(data['name']?.toString() ?? ''),
                      subtitle: Text('${data['price']} جنيه • المتاح: $stock\n${data['description'] ?? ''}'),
                      isThreeLine: true,
                      trailing: _isOwner
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل الكمية',
                                  icon: const Icon(Icons.inventory_2_outlined),
                                  onPressed: () => _editStock(doc.reference, stock),
                                ),
                                IconButton(
                                  tooltip: 'إخفاء المنتج',
                                  icon: const Icon(Icons.visibility_off_outlined),
                                  onPressed: () => doc.reference.update({'active': false}),
                                ),
                              ],
                            )
                          : FilledButton(
                              onPressed: stock > 0 && !_busy
                                  ? () => _buyProduct(doc.id)
                                  : null,
                              child: const Text('اطلب'),
                            ),
                    ));
                  },
                );
              },
            )),
          ]);
        },
      ),
    );
  }
}

class PrintRequestsPage extends StatelessWidget {
  final String companyId;
  const PrintRequestsPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات التصميم الواردة')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('print_design_requests').where('companyId', isEqualTo: companyId).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الطلبات'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد طلبات تصميم حتى الآن'));
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data();
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: (data['imageUrl'] as String? ?? '').isEmpty ? const Icon(Icons.design_services) : Image.network(data['imageUrl'] as String, width: 56, height: 56, fit: BoxFit.cover),
                  title: Text('طلب ${data['category'] ?? 'تصميم'}'),
                  subtitle: Text('${data['notes'] ?? ''}\nالعميل: ${data['customerName'] ?? data['customerId']}\nالحالة: ${data['status']}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => doc.reference.update({'status': value, 'updatedAt': FieldValue.serverTimestamp()}),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'in_progress', child: Text('قيد التنفيذ')),
                      PopupMenuItem(value: 'completed', child: Text('تم التنفيذ')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
