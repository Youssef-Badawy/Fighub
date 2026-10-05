import 'package:flutter/material.dart';

import 'seller_profile_page.dart';
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

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
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

  List<SellerProfile> _filterProfiles(
    List<SellerProfile> profiles,
  ) {
    if (_searchQuery.isEmpty) {
      return profiles;
    }

    return profiles.where((profile) {
      final name = profile.name.toLowerCase();
      final email = profile.email.toLowerCase();

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery);
    }).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<SellerProfile>>(
        stream: _sellerProfileService.watchAllSellerProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load users.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final profiles = _filterProfiles(snapshot.data ?? []);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
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
                child: profiles.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No users found.'
                              : 'No users match your search.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          24,
                        ),
                        itemCount: profiles.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];

                          return Card(
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
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
                              subtitle: profile.email.isNotEmpty
                                  ? Text(
                                      profile.email,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: const Icon(
                                Icons.chevron_right,
                              ),
                              onTap: () =>
                                  _openSellerProfile(profile.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
