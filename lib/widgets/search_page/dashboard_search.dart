// widget/search_page/dashboard_search.dart
import 'package:flutter/material.dart';
import 'package:chitchat/models/search_model.dart';

class DashboardSearchField extends StatelessWidget {
  final VoidCallback onTap;
  final double height;
  
  const DashboardSearchField({
    super.key,
    required this.onTap,
    this.height = 40,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Search ChitChat',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultItem extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;
  
  const SearchResultItem({
    super.key,
    required this.result,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        result.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (result.type == SearchResultType.user && 
                          (result.data['is_verified'] ?? false))
                        const SizedBox(width: 4),
                      if (result.type == SearchResultType.user && 
                          (result.data['is_verified'] ?? false))
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.count != null && result.count! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getCountText(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildTrailing(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatar() {
    switch (result.type) {
      case SearchResultType.user:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(result.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      case SearchResultType.hashtag:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade50,
          ),
          child: const Icon(
            Icons.tag,
            color: Colors.blue,
            size: 22,
          ),
        );
      case SearchResultType.post:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: result.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(result.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.grey.shade200,
          ),
          child: result.imageUrl.isEmpty
              ? const Icon(
                  Icons.article,
                  color: Colors.grey,
                  size: 22,
                )
              : null,
        );
    }
  }
  
  Widget _buildTrailing() {
    switch (result.type) {
      case SearchResultType.user:
        final isFollowing = result.isFollowing ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.grey.shade200 : Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: TextStyle(
              color: isFollowing ? Colors.black87 : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      default:
        return const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 20,
        );
    }
  }
  
  String _getCountText() {
    switch (result.type) {
      case SearchResultType.user:
        return '${result.count} followers';
      case SearchResultType.hashtag:
        return '${result.count} posts';
      default:
        return '';
    }
  }
}

class SearchHistoryItem extends StatelessWidget {
  final SearchHistory history;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  
  const SearchHistoryItem({
    super.key,
    required this.history,
    required this.onTap,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.history,
              color: Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                history.query,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.grey.shade500,
                size: 18,
              ),
              onPressed: onDelete,
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}