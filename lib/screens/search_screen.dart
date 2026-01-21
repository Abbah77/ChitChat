// screens/search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chitchat/logic/dashboard_search_cubit.dart';
import 'package:chitchat/models/search_model.dart';
import 'package:chitchat/widget/search_page/dashboard_search.dart';
import 'package:chitchat/widget/search_page/animation.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchFocusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardSearchCubit>().loadSearchHistory();
      _animationController.forward();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      context.read<DashboardSearchCubit>().clearSearch();
    }
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    context.read<DashboardSearchCubit>().search(query);
  }
  
  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    context.read<DashboardSearchCubit>().clearSearch();
  }
  
  void _onHistoryTap(String query) {
    _searchController.text = query;
    context.read<DashboardSearchCubit>().search(query);
    _searchFocusNode.requestFocus();
  }
  
  void _onResultTap(SearchResult result) {
    switch (result.type) {
      case SearchResultType.user:
        _navigateToProfile(result.data['id']);
        break;
      case SearchResultType.hashtag:
        _navigateToHashtag(result.data['name']);
        break;
      case SearchResultType.post:
        _navigateToPost(result.data['id']);
        break;
    }
  }
  
  void _navigateToProfile(String userId) {
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }
  
  void _navigateToHashtag(String hashtag) {
    Navigator.pushNamed(context, '/hashtag', arguments: hashtag);
  }
  
  void _navigateToPost(String postId) {
    Navigator.pushNamed(context, '/post', arguments: postId);
  }
  
  Widget _buildSearchField() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search users, hashtags, posts...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: _clearSearch,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryState(DashboardSearchHistoryLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.history.isNotEmpty)
                TextButton(
                  onPressed: () => context.read<DashboardSearchCubit>().clearHistory(),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.history.length,
          separatorBuilder: (context, index) => const Divider(height: 0),
          itemBuilder: (context, index) {
            return SearchHistoryItem(
              history: state.history[index],
              onTap: () => _onHistoryTap(state.history[index].query),
              onDelete: () {
                context.read<DashboardSearchCubit>()
                  .removeFromHistory(state.history[index].id);
              },
            );
          },
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Popular Now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPopularTags(),
      ],
    );
  }
  
  Widget _buildPopularTags() {
    final tags = ['#flutter', '#dart', '#programming', '#tech', '#coding'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) {
          return ScaleOnTap(
            onTap: () => _onHistoryTap(tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchField(),
            const Divider(height: 0),
            Expanded(
              child: BlocBuilder<DashboardSearchCubit, DashboardSearchState>(
                builder: (context, state) {
                  return _buildContent(state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContent(DashboardSearchState state) {
    if (state is DashboardSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is DashboardSearchError) {
      return Center(child: Text(state.message));
    }
    
    if (state is DashboardSearchSuccess) {
      if (state.results.isEmpty) {
        return _buildEmptyState();
      }
      
      return ListView.separated(
        padding: const EdgeInsets.only(top: 8),
        itemCount: state.results.length,
        separatorBuilder: (context, index) => const Divider(height: 0),
        itemBuilder: (context, index) {
          return SearchResultItem(
            result: state.results[index],
            onTap: () => _onResultTap(state.results[index]),
          );
        },
      );
    }
    
    if (state is DashboardSearchHistoryLoaded) {
      return ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          SearchSlideTransition(
            animation: _animationController,
            child: _buildHistoryState(state),
          ),
        ],
      );
    }
    
    // DashboardSearchInitial
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        SearchSlideTransition(
          animation: _animationController,
          child: _buildHistoryState(
            DashboardSearchHistoryLoaded(history: []),
          ),
        ),
      ],
    );
  }
}