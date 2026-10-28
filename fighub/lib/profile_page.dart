import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'product_model.dart';
import 'settings_page.dart';
import 'app_settings.dart';
import 'app_localizations.dart';
import 'auth_manager.dart';
import 'account_page.dart';
import 'auth_profile_header.dart';
import 'interests_page.dart';
import 'verification_page.dart';
import 'admin_verification_page.dart';

class ProfilePage extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onMyProducts;
  final VoidCallback onFavorites;
  final AppSettings settings;
  final AuthManager authManager;

  const ProfilePage({
    super.key,
    required this.products,
    required this.onMyProducts,
    required this.onFavorites,
    required this.settings,
    required this.authManager,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    final soldCount = products
        .where((product) => product.status == 'Sold')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.isArabic ? 'الملف الشخصي' : 'Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AuthProfileHeader(authManager: authManager),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  title: localization.products,
                  value: products.length.toString(),
                ),
              ),
              Expanded(
                child: _ProfileStat(
                  title: localization.sold,
                  value: soldCount.toString(),
                ),
              ),
              Expanded(
                child: _ProfileStat(title: localization.reviews, value: '0'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(settings.isArabic ? 'الحساب' : 'Account'),
              subtitle: Text(
                settings.isArabic
                    ? 'إدارة بيانات حسابك'
                    : 'Manage your account information',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountPage(authManager: authManager),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(localization.myProducts),
              subtitle: Text(
                settings.isArabic
                    ? 'إدارة المنتجات التي قمت بعرضها'
                    : 'Manage your listed products',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: onMyProducts,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite_border),
              title: Text(localization.myFavorites),
              subtitle: Text(
                settings.isArabic
                    ? 'عرض الشخصيات المفضلة لديك'
                    : 'View your favorite figures',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: onFavorites,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.interests_outlined),
              title: Text(settings.isArabic ? 'الاهتمامات' : 'Interests'),
              subtitle: Text(
                settings.isArabic
                    ? 'اختر أنواع الشخصيات التي تهمك'
                    : 'Choose the types of figures you like',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InterestsPage(authManager: authManager),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: Text(settings.isArabic ? 'توثيق الحساب' : 'Verification'),
              subtitle: Text(
                settings.isArabic
                    ? 'قدّم طلب توثيق حسابك'
                    : 'Apply to become a verified seller',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerificationPage()),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: () async {
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {
                return FirebaseFirestore.instance
                    .collection('users')
                    .doc('__no_user__')
                    .get();
              }

              return FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
            }(),
            builder: (context, snapshot) {
              final isAdmin = snapshot.data?.data()?['role'] == 'admin';

              if (!isAdmin) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: Text(
                        settings.isArabic
                            ? 'إدارة التوثيق'
                            : 'Verification Admin',
                      ),
                      subtitle: Text(
                        settings.isArabic
                            ? 'مراجعة طلبات توثيق الحسابات'
                            : 'Review verification requests',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminVerificationPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping_outlined),
                      title: Text(
                        settings.isArabic
                            ? 'رقم واتساب الشحن'
                            : 'Shipping WhatsApp number',
                      ),
                      subtitle: Text(
                        settings.isArabic
                            ? 'تحديد الرقم الذي يستقبل بيانات الشحن'
                            : 'Set the number that receives shipping details',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _editShippingWhatsappNumber(
                        context,
                        settings.isArabic,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(localization.settings),
              subtitle: Text(
                settings.isArabic ? 'إعدادات التطبيق' : 'App settings',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(settings: settings),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () async {
              await authManager.logout();

              if (!context.mounted) {
                return;
              }

              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
            label: Text(settings.isArabic ? 'تسجيل الخروج' : 'Log Out'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

Future<void> _editShippingWhatsappNumber(
  BuildContext context,
  bool isArabic,
) async {
  final controller = TextEditingController();

  try {
    final reference = FirebaseFirestore.instance
        .collection('app_config')
        .doc('shipping');
    final snapshot = await reference.get();
    controller.text = (snapshot.data()?['whatsappNumber'] ?? '').toString();

    if (!context.mounted) return;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isArabic ? 'رقم واتساب الشحن' : 'Shipping WhatsApp number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: isArabic
                ? 'الرقم الدولي مع كود الدولة'
                : 'International number with country code',
            helperText: isArabic
                ? 'اكتب الأرقام فقط، بدون + أو مسافات'
                : 'Digits only, without + or spaces',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true || !context.mounted) return;

    final number = controller.text.replaceAll(RegExp(r'\D'), '');
    if (number.length < 10 || number.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'أدخل رقمًا دوليًا صحيحًا من 10 إلى 15 رقمًا'
                : 'Enter an international number containing 10–15 digits',
          ),
        ),
      );
      return;
    }

    await reference.set({'whatsappNumber': number});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'تم حفظ الرقم' : 'Number saved')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذّر حفظ الرقم. سنراجع صلاحيات Firestore في الخطوة التالية.'
                : 'Could not save the number. Firestore permissions will be checked next.',
          ),
        ),
      );
    }
  } finally {
    controller.dispose();
  }
}
