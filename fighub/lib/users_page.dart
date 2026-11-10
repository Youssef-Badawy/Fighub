import 'dart:async';

import 'package:flutter/material.dart';

import 'seller_profile_page.dart';
import 'app_localizations.dart';
import 'seller_profile_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final SellerProfileService _sellerProfileService =
      SellerProfileService();

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  Timer? _searchDebounce;
  Future<List<SellerProfile>>? _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _searchFuture = null;
    });

    if (query.length < 2) return;

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchFuture = _sellerProfileService.searchSellerProfiles(query);
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSellerProfile(String sellerId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SellerProfilePage(
          sellerId: sellerId,
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(SellerProfile profile) {
    if (profile.photoUrl.isEmpty) {
      return const CircleAvatar(
        radius: 26,
        child: Icon(Icons.person),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundImage: NetworkImage(profile.photoUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localization.isArabic ? 'المستخدمون' : 'Users',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localization.isArabic ? 'ابحث عن مستخدم بالاسم' : 'Search users by name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchQuery.length < 2
                ? Center(
                    child: Text(
                      localization.isArabic
                          ? 'اكتب حرفين على الأقل للبحث عن مستخدم.'
                          : 'Type at least two letters to search for a user.',
                    ),
                  )
                : FutureBuilder<List<SellerProfile>>(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      if (_searchFuture == null ||
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Could not search users.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final profiles = snapshot.data ?? const <SellerProfile>[];
                      if (profiles.isEmpty) {
                        return const Center(
                          child: Text(
                            localization.isArabic
                                ? 'لا يوجد مستخدمون بهذا الاسم.'
                                : 'No users match your search.',
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: profiles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: _buildProfilePhoto(profile),
                              title: Text(
                                profile.name.isNotEmpty
                                    ? profile.name
                                    : 'FigHub User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openSellerProfile(profile.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
