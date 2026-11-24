import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'fighub_image_picker.dart';

import 'chat_service.dart';
import 'chat_page.dart';
import 'cloudinary_service.dart';

const _printSizePrices = <String, Map<String, int>>{
  'برواز': {'30×20 سم': 200, '40×30 سم': 300, '50×40 سم': 450, '60×50 سم': 500, '70×50 سم': 580},
  'طابلوه': {'20×15 سم': 120, '30×20 سم': 230, '40×30 سم': 380, '50×40 سم': 450, '60×50 سم': 550, '70×50 سم': 580},
};

int? _defaultPrintPrice(String category) {
  switch (category) {
    case 'تيشيرتات': return 450;
    case 'مجات': return 200;
    case 'برواز': return 200; // 30×20 cm starting size
    case 'طابلوه': return 120; // 20×15 cm starting size
    default: return null;
  }
}

const printCategories = <Map<String, String>>[
  {'name': 'تيشيرتات', 'emoji': '👕'},
  {'name': 'مجات', 'emoji': '☕'},
  {'name': 'هدايا', 'emoji': '🎁'},
  {'name': 'مجسمات', 'emoji': '🧸'},
  {'name': 'ميداليات', 'emoji': '🏅'},
  {'name': 'استيكرات', 'emoji': '🏷️'},
  {'name': 'خشبيات', 'emoji': '🪵'},
  {'name': 'سلاسل', 'emoji': '📿'},
  {'name': 'حظاظات', 'emoji': '🪢'},
  {'name': 'شنط', 'emoji': '👜'},
  {'name': 'طابلوه', 'emoji': '🖼️'},
  {'name': 'صور', 'emoji': '📸'},
  {'name': 'كابات', 'emoji': '🧢'},
  {'name': 'برواز', 'emoji': '🖼️'},
  {'name': 'كوميكس', 'emoji': '📚'},
  {'name': 'اعلام', 'emoji': '🚩'},
  {'name': 'نوت بوك', 'emoji': '📓'},
  {'name': 'اقلام', 'emoji': '🖊️'},
  {'name': 'محفظة', 'emoji': '👛'},
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
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول بحسابك أولًا لتفعيل حساب شركة أو محل')),
      );
      return;
    }

    final name = TextEditingController();
    final phone = TextEditingController();
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تفعيل حساب شركة / محل'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم الشركة أو المحل'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب اسم الشركة'
                      : null,
                ),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم التواصل'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب رقم التواصل'
                      : null,
                ),
                TextFormField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'نبذة عن الشركة'),
                ),
              ]),
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

      if (result != true || !mounted) return;

      final reference = _db.collection('print_businesses').doc(user.uid);
      final existing = await reference.get();
      final businessData = <String, dynamic>{
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'description': description.text.trim(),
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existing.exists) {
        // Repair legacy records that were created without a matching ownerId.
        // The document ID is the authenticated user's UID.
        await reference.update({
          ...businessData,
          'ownerId': user.uid,
        });
      } else {
        await reference.set({
          ...businessData,
          'ownerId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل حساب الشركة بنجاح')),
        );
      }
    } catch (error) {
      debugPrint('PRINT BUSINESS REGISTRATION ERROR: $error');
      if (mounted) {
        final details = error.toString();
        final message = details.contains('permission-denied')
            ? 'تعذر التسجيل بسبب صلاحيات قاعدة البيانات. يلزم نشر قواعد Firestore الخاصة بـ 3D PRINTING.'
            : 'تعذر تفعيل حساب الشركة: $details';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      name.dispose();
      phone.dispose();
      description.dispose();
    }
  }

  Future<void> _openAdminCatalog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      final userSnapshot = await _db.collection('users').doc(user.uid).get();
      if (userSnapshot.data()?['role'] != 'admin') {
        throw StateError('هذه اللوحة متاحة لحساب الأدمن فقط.');
      }
      final businessRef = _db.collection('print_businesses').doc(user.uid);
      final businessSnapshot = await businessRef.get();
      if (!businessSnapshot.exists) {
        await businessRef.set({
          'name': 'كتالوج FigHub الرسمي',
          'phone': '',
          'description': 'الكتالوج الرسمي لتصميمات FigHub',
          'active': true,
          'officialCatalog': true,
          'ownerId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (businessSnapshot.data()?['officialCatalog'] != true) {
        // Mark legacy official-catalog documents so customers can discover
        // them without reading the owner's private users/{uid} document.
        await businessRef.update({
          'officialCatalog': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrintBusinessPage(
            businessId: user.uid,
            isAdminCatalog: true,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح كتالوج الأدمن: $error')),
        );
      }
    }
  }

  Future<void> _openOfficialCatalog() async {
    try {
      final result = await _db
          .collection('print_businesses')
          .where('name', isEqualTo: 'كتالوج FigHub الرسمي')
          .get();

      // The officialCatalog marker is writable only by an admin according
      // to Firestore rules. Do not read users/{uid}: those documents are private.
      DocumentSnapshot<Map<String, dynamic>>? officialCatalog;
      for (final candidate in result.docs) {
        if (candidate.data()['officialCatalog'] == true &&
            candidate.data()['active'] == true) {
          officialCatalog = candidate;
          break;
        }
      }

      if (officialCatalog == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الكتالوج الرسمي قيد التجهيز حاليًا')),
          );
        }
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrintBusinessPage(
            businessId: officialCatalog!.id,
            isAdminCatalog: true,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الكتالوج الرسمي: $error')),
        );
      }
    }
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
          IconButton(
            tooltip: 'كتالوج FigHub الرسمي',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _openOfficialCatalog,
          ),
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
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: user == null || user.isAnonymous
                ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
                : _db.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.data?.data()?['role'] != 'admin') {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'كتالوج FigHub الرسمي',
                icon: const Icon(Icons.admin_panel_settings_outlined),
                onPressed: _openAdminCatalog,
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
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: .10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  item['emoji']!,
                  style: const TextStyle(fontSize: 43, height: 1.15),
                ),
              ),
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
          // Avoid Firestore whereIn limits: show all active businesses in this category.
          stream: _db.collection('print_businesses')
              .where('active', isEqualTo: true)
              .snapshots(),
          builder: (context, businessesSnapshot) {
            if (businessesSnapshot.hasError) {
              return const Center(child: Text('تعذر تحميل الشركات'));
            }
            if (!businessesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final businesses = businessesSnapshot.data!.docs
                .where((business) => sellerIds.contains(business.id))
                .toList();
            if (businesses.isEmpty) {
              return const Center(child: Text('لا توجد شركات في هذا القسم حاليًا'));
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: businesses.map((business) {
                final data = business.data();
                final count = productsSnapshot.data!.docs
                    .where((p) => p.data()['sellerId'] == business.id)
                    .length;
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.storefront)),
                    title: Text(data['name']?.toString() ?? 'شركة'),
                    subtitle: Text(
                      '${data['description'] ?? ''}\n$count منتج في قسم $_selectedCategory',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrintBusinessPage(
                          businessId: business.id,
                          initialCategory: _selectedCategory,
                        ),
                      ),
                    ),
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
  final bool isAdminCatalog;
  const PrintBusinessPage({
    super.key,
    required this.businessId,
    this.initialCategory,
    this.isAdminCatalog = false,
  });

  @override
  State<PrintBusinessPage> createState() => _PrintBusinessPageState();
}

class _PrintBusinessPageState extends State<PrintBusinessPage> {
  final _db = FirebaseFirestore.instance;
  bool _busy = false;

  bool get _isOwner => FirebaseAuth.instance.currentUser?.uid == widget.businessId;

  Future<void> _addProduct() async {
    final name = TextEditingController();
    final initialCategory = widget.initialCategory ?? printCategories.first['name']!;
    final price = TextEditingController(text: _defaultPrintPrice(initialCategory)?.toString() ?? '');
    final stock = TextEditingController(text: '1');
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String category = initialCategory;
    String? selectedSize = _printSizePrices[initialCategory]?.keys.first;
    XFile? image;
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
        title: const Text('إضافة منتج 3D PRINTING'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم المنتج'), validator: (v) => v == null || v.trim().isEmpty ? 'اكتب اسم المنتج' : null),
            TextFormField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر بالجنيه'), validator: (v) { final value = double.tryParse(v ?? ''); return value == null || value <= 0 ? 'اكتب سعرًا أكبر من صفر' : null; }),
            TextFormField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد القطع المتوفرة'), validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 0 ? 'اكتب كمية صحيحة' : null),
            DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'القسم'), items: printCategories.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'] as String))).toList(), onChanged: (v) => refresh(() { category = v ?? category; selectedSize = _printSizePrices[category]?.keys.first; price.text = selectedSize == null ? (_defaultPrintPrice(category)?.toString() ?? '') : _printSizePrices[category]![selectedSize].toString(); })),
            if (_printSizePrices.containsKey(category)) DropdownButtonFormField<String>(value: selectedSize, decoration: const InputDecoration(labelText: 'المقاس'), items: _printSizePrices[category]!.keys.map((size) => DropdownMenuItem(value: size, child: Text(size))).toList(), onChanged: (v) => refresh(() { selectedSize = v; if (v != null) price.text = _printSizePrices[category]![v].toString(); })),
            TextFormField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'وصف المنتج')),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: () async { final files = await FigHubImagePicker.pickAndCrop(context, imageQuality: 90, maxWidth: 2500, maxHeight: 2500); if (files != null) refresh(() => image = files); }, icon: const Icon(Icons.image), label: Text(image == null ? 'اختيار صورة المنتج (مطلوب)' : 'تم اختيار الصورة')),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              if (image == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('اختار صورة واضحة للمنتج قبل النشر'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, {
                'name': selectedSize == null
                    ? name.text.trim()
                    : '${name.text.trim()} - $selectedSize',
                'price': price.text.trim(),
                'stock': int.parse(stock.text),
                'category': category,
                'description': description.text.trim(),
                'image': image,
              });
            },
            child: const Text('نشر'),
          ),
        ],
      )),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final selectedImage = picked['image'] as XFile?;
      if (selectedImage == null) {
        throw StateError('لا يمكن نشر منتج بدون صورة.');
      }
      final cloudinary = CloudinaryService();
      final imageUrl = widget.isAdminCatalog
          ? await cloudinary.uploadCatalogImage(selectedImage)
          : await cloudinary.uploadImage(selectedImage);
      await _db.collection('print_products').add({
        'sellerId': widget.businessId,
        if (widget.isAdminCatalog) 'catalogOwnerId': widget.businessId,
        if (widget.isAdminCatalog) 'catalogManaged': true,
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

  Future<void> _bulkImportCatalog() async {
    if (!widget.isAdminCatalog || !_isOwner || _busy) return;
    final franchise = TextEditingController();
    final character = TextEditingController();
    final price = TextEditingController(text: '250');
    final stock = TextEditingController(text: '10');
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String category = widget.initialCategory ?? printCategories.first['name']!;
    List<XFile> images = [];
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('استيراد دفعة تصميمات للكتالوج الرسمي'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: franchise,
                    decoration: const InputDecoration(labelText: 'العالم / السلسلة (مثال: خيال علمي)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'اكتب اسم السلسلة' : null,
                  ),
                  TextFormField(
                    controller: character,
                    decoration: const InputDecoration(labelText: 'الشخصية أو الموضوع'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'اكتب الشخصية أو الموضوع' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'نوع المنتج'),
                    items: printCategories.map((item) => DropdownMenuItem(
                      value: item['name'] as String,
                      child: Text(item['name'] as String),
                    )).toList(),
                    onChanged: (value) => refresh(() => category = value ?? category),
                  ),
                  TextFormField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'سعر القطعة بالجنيه'),
                    validator: (v) {
                      final value = double.tryParse(v ?? '');
                      return value == null || value <= 0 ? 'اكتب سعرًا صحيحًا' : null;
                    },
                  ),
                  TextFormField(
                    controller: stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'المخزون لكل تصميم'),
                    validator: (v) {
                      final value = int.tryParse(v ?? '');
                      return value == null || value < 0 ? 'اكتب كمية صحيحة' : null;
                    },
                  ),
                  TextFormField(
                    controller: description,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'وصف مشترك (اختياري)'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await ImagePicker().pickMultiImage(
                        imageQuality: 90,
                        maxWidth: 2500,
                        maxHeight: 2500,
                      );
                      if (selected.isNotEmpty) refresh(() => images = selected);
                    },
                    icon: const Icon(Icons.collections_outlined),
                    label: Text(images.isEmpty
                        ? 'اختيار صور التصميمات من الجهاز'
                        : 'تم اختيار ${images.length} صورة'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'كل صورة ستتحول إلى منتج مستقل على حساب الأدمن. اختر صورًا أصلية تملك حق استخدامها.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (images.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('اختار صورة واحدة على الأقل')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('بدء الاستيراد'),
            ),
          ],
        ),
      ),
    );
    if (result != true || !mounted) {
      franchise.dispose();
      character.dispose();
      price.dispose();
      stock.dispose();
      description.dispose();
      return;
    }

    setState(() => _busy = true);
    var imported = 0;
    try {
      final ownerId = FirebaseAuth.instance.currentUser!.uid;
      for (var index = 0; index < images.length; index++) {
        final imageUrl = await CloudinaryService().uploadCatalogImage(images[index]);
        final productRef = _db.collection('print_products').doc();
        await productRef.set({
          'sellerId': ownerId,
          'catalogOwnerId': ownerId,
          'catalogManaged': true,
          'franchise': franchise.text.trim(),
          'character': character.text.trim(),
          'designNumber': index + 1,
          'name': '${character.text.trim()} - ${category} - تصميم ${index + 1}',
          'price': price.text.trim(),
          'stockQuantity': int.parse(stock.text),
          'category': category,
          'description': description.text.trim(),
          'imageUrl': imageUrl,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        imported++;
        if (mounted) setState(() {});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد $imported تصميم إلى كتالوج الأدمن')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد $imported من أصل ${images.length}. تعذر إكمال الدفعة: $error')),
        );
      }
    } finally {
      franchise.dispose();
      character.dispose();
      price.dispose();
      stock.dispose();
      description.dispose();
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

  Future<void> _editPrice(
    DocumentReference<Map<String, dynamic>> reference,
    String currentPrice,
  ) async {
    final controller = TextEditingController(text: currentPrice);
    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل السعر'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'السعر بالجنيه'),
            validator: (value) {
              final price = double.tryParse(value ?? '');
              return price == null || price <= 0 ? 'اكتب سعرًا أكبر من صفر' : null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true);
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
        'price': controller.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث السعر: $error')),
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
    if (user.uid == widget.businessId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك إرسال طلب تصميم من حساب الكتالوج نفسه')),
      );
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
          OutlinedButton.icon(onPressed: () async { final file = await FigHubImagePicker.pickAndCrop(context, imageQuality: 85, maxWidth: 2500, maxHeight: 2500); if (file != null) refresh(() => image = file); }, icon: const Icon(Icons.upload_file), label: Text(image == null ? 'ارفع صورة التصميم' : 'تم اختيار الصورة')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (image == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ارفع صورة مرجعية للتصميم أولًا')),
                );
                return;
              }
              Navigator.pop(dialogContext, {
                'category': category,
                'notes': notes.text.trim(),
                'image': image,
              });
            },
            child: const Text('إرسال الطلب'),
          ),
        ],
      )),
    );
    if (result == null || !mounted) {
      notes.dispose();
      return;
    }
    setState(() => _busy = true);
    try {
      String imageUrl = '';
      final selectedImage = result['image'] as XFile?;
      if (selectedImage != null) imageUrl = await CloudinaryService().uploadImage(selectedImage);
      final request = await _db.collection('print_design_requests').add({
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
      // Also deliver the request in the existing buyer/company conversation,
      // which triggers the app's normal chat notification.
      try {
        final chatId = await ChatService().getOrCreateChat(
          productId: 'design_${request.id}',
          productName: 'طلب تصميم ${result['category']}',
          sellerId: widget.businessId,
          chatType: 'printing',
        );
        await ChatService().sendMessage(
          chatId: chatId,
          text: [
            'طلب تصميم جديد',
            'المنتج: ${result['category']}',
            'التفاصيل: ${result['notes']}',
          ].join('\n'),
        );
        if (imageUrl.isNotEmpty) {
          await ChatService().sendMediaMessage(
            chatId: chatId,
            mediaUrl: imageUrl,
            mediaType: 'image',
            caption: 'صورة التصميم المرفقة - ${result['category']}',
          );
        }
      } catch (deliveryError) {
        debugPrint('PRINT DESIGN CHAT DELIVERY ERROR: $deliveryError');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب التصميم لحساب FigHub')),
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الطلب: $error')));
    } finally {
      notes.dispose();
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
    var orderSaved = false;
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) throw StateError('المنتج غير موجود');
        final data = snapshot.data()!;
        final quantity = (data['stockQuantity'] as num?)?.toInt() ?? 0;
        final imageUrl = (data['imageUrl'] as String? ?? '').trim();
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
          'imagePath': imageUrl,
          'imagePaths': imageUrl.isNotEmpty ? [imageUrl] : <String>[],
          'status': 'Reserved',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      orderSaved = true;
      final orderData = await orderRef.get();
      final data = orderData.data()!;
      final chatId = await ChatService().addReservedProductToChat(
        productId: orderRef.id,
        productName: data['name'] as String,
        price: data['price'] as String,
        imagePaths: (data['imagePaths'] as List? ?? []).whereType<String>().toList(),
        sellerId: widget.businessId,
        chatType: 'printing',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الطلب وإضافته للمحادثات. بيانات الشحن متاحة من المحادثة.')));
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId, productName: 'حساب المشتريات')));
      }
    } catch (error) {
      if (mounted) {
        final message = orderSaved
            ? 'تم تسجيل الطلب وتحديث المخزون، لكن تعذر فتح المحادثة: $error'
            : 'تعذر إتمام الطلب: $error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showProductImage(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.7,
              maxScale: 5,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminCatalog ? 'كتالوج FigHub الرسمي' : 'متجر 3D PRINTING'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('print_businesses').doc(widget.businessId).snapshots(),
        builder: (context, businessSnapshot) {
          final business = businessSnapshot.data?.data() ?? {};
          return Column(children: [
            if (_isOwner) Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: _busy ? null : _addProduct, icon: const Icon(Icons.add), label: const Text('إضافة منتج'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrintRequestsPage(companyId: widget.businessId))), icon: const Icon(Icons.inbox), label: const Text('طلبات التصميم'))),
              ]),
              if (widget.isAdminCatalog) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _busy ? null : _bulkImportCatalog,
                    icon: const Icon(Icons.library_add),
                    label: const Text('استيراد مجموعة تصميمات لحساب الأدمن'),
                  ),
                ),
              ],
            ])),
            Builder(
              builder: (context) {
                final currentUser = FirebaseAuth.instance.currentUser;
                // The request button belongs on the official admin catalog,
                // and is intended for registered customers, not the admin owner.
                if (!widget.isAdminCatalog ||
                    currentUser == null ||
                    currentUser.isAnonymous ||
                    currentUser.uid == widget.businessId) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _requestDesign(business),
                      icon: const Icon(Icons.brush),
                      label: const Text('اطلب تصميمك من FigHub'),
                    ),
                  ),
                );
              },
            ),
            if (_busy) const LinearProgressIndicator(),
            Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('print_products').where('sellerId', isEqualTo: widget.businessId).where('active', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('تعذر تحميل منتجات الشركة'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
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
                    final imageUrl = (data['imageUrl'] as String? ?? '').trim();
                    final franchise = data['franchise']?.toString() ?? '';
                    final character = data['character']?.toString() ?? '';
                    final description = data['description']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _showProductImage(imageUrl),
                              borderRadius: BorderRadius.circular(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 104,
                                  height: 104,
                                  child: imageUrl.isEmpty
                                      ? const ColoredBox(
                                          color: Color(0x11000000),
                                          child: Icon(Icons.inventory_2_outlined, size: 34),
                                        )
                                      : Image.network(
                                          imageUrl,
                                          width: 104,
                                          height: 104,
                                          cacheWidth: 312,
                                          cacheHeight: 312,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    data['name']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '${data['price']} جنيه  •  المتاح: $stock',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (franchise.isNotEmpty || character.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      [if (franchise.isNotEmpty) franchise, if (character.isNotEmpty) character].join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (_isOwner)
                              PopupMenuButton<String>(
                                tooltip: 'إدارة المنتج',
                                icon: const Icon(Icons.more_vert),
                                onSelected: (action) async {
                                  if (action == 'stock') {
                                    await _editStock(doc.reference, stock);
                                  } else if (action == 'price') {
                                    await _editPrice(doc.reference, data['price']?.toString() ?? '');
                                  } else if (action == 'hide') {
                                    try {
                                      await doc.reference.update({'active': false});
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('تعذر إخفاء المنتج: $error')),
                                        );
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'stock', child: Text('تعديل الكمية')),
                                  PopupMenuItem(value: 'price', child: Text('تعديل السعر')),
                                  PopupMenuItem(value: 'hide', child: Text('إخفاء المنتج')),
                                ],
                              )
                            else
                              FilledButton.tonal(
                                onPressed: stock > 0 && !_busy ? () => _buyProduct(doc.id) : null,
                                child: const Text('اطلب'),
                              ),
                          ],
                        ),
                      ),
                    );
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
              final imageUrl = (data['imageUrl'] as String? ?? '').trim();
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: imageUrl.isEmpty
                      ? const Icon(Icons.design_services, size: 36)
                      : InkWell(
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) => Dialog(
                                insetPadding: const EdgeInsets.all(12),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    InteractiveViewer(
                                      minScale: 0.7,
                                      maxScale: 5,
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => const Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Icon(Icons.broken_image_outlined, size: 48),
                                        ),
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              width: 88,
                              height: 88,
                              cacheWidth: 264,
                              cacheHeight: 264,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                  title: Text('طلب ${data['category'] ?? 'تصميم'}'),
                  subtitle: Text('${data['notes'] ?? ''}\nالعميل: ${data['customerName'] ?? data['customerId']}\nالحالة: ${data['status']}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        await doc.reference.update({
                          'status': value,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر تحديث حالة الطلب: $error')),
                          );
                        }
                      }
                    },
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
