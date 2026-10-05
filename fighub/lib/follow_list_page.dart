import 'package:flutter/material.dart';

import 'follow_service.dart';
import 'seller_profile_page.dart';
import 'seller_profile_service.dart';

enum FollowListType {
  followers,
  following,
}

class FollowListPage extends StatelessWidget {
  final String userId;
  final FollowListType type;

  const FollowListPage({
    super.key,
    required this.userId,
    required this.type,
  });

  String get _title {
    return type == FollowListType.followers
        ? 'Followers'
        : 'Following';
  }

  Stream<List<String>> _watchIds(FollowService service) {
    return type == FollowListType.followers
        ? service.watchFollowerIds(userId)
        : service.watchFollowingIds(userId);
  }

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();
    final profileService = SellerProfileService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<String>>(
        stream: _watchIds(followService),
        builder: (context, idSnapshot) {
          if (idSnapshot.connectionState ==
                  ConnectionState.waiting &&
              !idSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (idSnapshot.hasError) {
            return Center(
              child: Text(
                'Could not load users.\n${idSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final userIds = idSnapshot.data ?? [];

          if (userIds.isEmpty) {
            return Center(
              child: Text(
                type == FollowListType.followers
                    ? 'No followers yet.'
                    : 'Not following anyone yet.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: userIds.length,
            separatorBuilder: (_, index) =>
                const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final profileId = userIds[index];

              return StreamBuilder<SellerProfile?>(
                stream: profileService
                    .watchSellerProfile(profileId),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !profileSnapshot.hasData) {
                    return const SizedBox(
                      height: 70,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final profile =
                      profileSnapshot.data;

                  if (profile == null) {
                    return const SizedBox.shrink();
                  }

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
                      subtitle:
                          profile.email.isNotEmpty
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
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SellerProfilePage(
                              sellerId: profile.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfilePhoto(
    SellerProfile profile,
  ) {
    if (profile.photoUrl.isEmpty) {
      return const CircleAvatar(
        radius: 26,
        child: Icon(Icons.person),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundImage: NetworkImage(
        profile.photoUrl,
      ),
    );
  }
}
