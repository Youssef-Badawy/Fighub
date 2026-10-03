import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        ) ??
        const AppLocalizations(Locale('en'));
  }

  bool get isArabic => locale.languageCode == 'ar';

  String get settings =>
      isArabic ? 'الإعدادات' : 'Settings';

  String get language =>
      isArabic ? 'اللغة' : 'Language';

  String get english =>
      isArabic ? 'الإنجليزية' : 'English';

  String get arabic =>
      isArabic ? 'العربية' : 'Arabic';

  String get notifications =>
      isArabic ? 'الإشعارات' : 'Notifications';

  String get account =>
      isArabic ? 'الحساب' : 'Account';

  String get darkMode =>
      isArabic ? 'الوضع الداكن' : 'Dark Mode';

  String get aboutFigHub =>
      isArabic ? 'عن FigHub' : 'About FigHub';

  String get products =>
      isArabic ? 'المنتجات' : 'Products';

  String get sold =>
      isArabic ? 'تم البيع' : 'Sold';

  String get reviews =>
      isArabic ? 'التقييمات' : 'Reviews';

  String get myProducts =>
      isArabic ? 'منتجاتي' : 'My Products';

  String get myFavorites =>
      isArabic ? 'المفضلة' : 'My Favorites';

  String get loginSignUp =>
      isArabic
          ? 'تسجيل الدخول / إنشاء حساب'
          : 'Login / Sign Up';

  String get home =>
      isArabic ? 'الرئيسية' : 'Home';

  String get sell =>
      isArabic ? 'بيع' : 'Sell';

  String get favorites =>
      isArabic ? 'المفضلة' : 'Favorites';

  String get messages =>
      isArabic ? 'المحادثات' : 'Messages';

  String get search =>
      isArabic ? 'بحث' : 'Search';

  String get all =>
      isArabic ? 'الكل' : 'All';

  String get marvel =>
      isArabic ? 'مارفل' : 'Marvel';

  String get dc =>
      isArabic ? 'دي سي' : 'DC';

  String get gameOfThrones =>
      isArabic ? 'صراع العروش' : 'Game of Thrones';

  String get anime =>
      isArabic ? 'أنمي' : 'Anime';

  String get starWars =>
      isArabic ? 'حرب النجوم' : 'Star Wars';

  String get other =>
      isArabic ? 'أخرى' : 'Other';

  String get available =>
      isArabic ? 'متاح' : 'Available';

  String get reserved =>
      isArabic ? 'محجوز' : 'Reserved';

  String get productSold =>
      isArabic ? 'تم البيع' : 'Sold';

  String get newCondition =>
      isArabic ? 'جديد' : 'New';

  String get usedCondition =>
      isArabic ? 'مستعمل' : 'Used';

  String get rareCondition =>
      isArabic ? 'نادر' : 'Rare';

  String get cashOnDelivery =>
      isArabic ? 'الدفع عند الاستلام' : 'Cash on Delivery';

  String get electronicWallet =>
      isArabic ? 'محفظة إلكترونية' : 'Electronic Wallet';

  String get cancel =>
      isArabic ? 'إلغاء' : 'Cancel';

  String get delete =>
      isArabic ? 'حذف' : 'Delete';

  String get save =>
      isArabic ? 'حفظ' : 'Save';

  String get close =>
      isArabic ? 'إغلاق' : 'Close';

  String get yes =>
      isArabic ? 'نعم' : 'Yes';

  String get no =>
      isArabic ? 'لا' : 'No';

  String get justNow =>
      isArabic ? 'الآن' : 'Just now';

  String get noProducts =>
      isArabic
          ? 'لا توجد منتجات حتى الآن.'
          : 'No products yet.';

  String get noFavorites =>
      isArabic
          ? 'لا توجد منتجات مفضلة حتى الآن.'
          : 'No favorite products yet.';

  String get noMessages =>
      isArabic
          ? 'لا توجد محادثات حتى الآن.'
          : 'No conversations yet.';

  String get noNotifications =>
      isArabic
          ? 'لا توجد إشعارات حتى الآن.'
          : 'No notifications yet.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'en' ||
        locale.languageCode == 'ar';
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<AppLocalizations> old,
  ) {
    return false;
  }
}