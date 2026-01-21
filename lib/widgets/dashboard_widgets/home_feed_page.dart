import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/story_widgets/story_circle.dart';
import 'widgets/post_widgets/post_card.dart';
import 'widgets/post_widgets/story_viewer.dart';
import 'widget/search_page/animation.dart';
import 'logic/dashboard_cubit.dart';
import 'widgets/post_widgets/create_post_modal.dart';

// Import your search screen and necessary dependencies
import 'screens/search_screen.dart';
import 'logic/dashboard_search_cubit.dart';

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({super.key});

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  final ScrollController _scrollController = ScrollController();
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().initializeDashboard();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final cubit = context.read<DashboardCubit>();
    final state = cubit.state;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (state is DashboardLoaded) {
        cubit.loadMorePosts();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<DashboardCubit>().refreshDashboard();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _showCreatePostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostModal(),
    );
  }

  void _navigateToSearch() {
    // Note: Ensure SearchService is defined in your project
    Navigator.of(context).push(
      SearchPageRoute(
        page: BlocProvider(
          create: (context) => DashboardSearchCubit(SearchService()),
          child: const SearchScreen(),
        ),
      ),
    );
  }

  void _navigateToNotifications() {
    // Note: Ensure NotificationPage is defined in your project
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Scaffold(body: Center(child: Text('Notifications'))), 
      ),
    );
  }

  void _openStoryViewer(BuildContext context, List<Story> stories, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewer(
          stories: stories,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: false,
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              edgeOffset: 100,
              color: Colors.blueAccent,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    pinned: false,
                    elevation: 0.6,
                    backgroundColor: Colors.white,
                    titleSpacing: 16,
                    title: Row(
                      children: [
                        const Text(
                          'ChitChat',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SearchField(onTap: _navigateToSearch),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.black87),
                        onPressed: _navigateToNotifications,
                      ),
                    ],
                  ),
                  if (state is DashboardLoaded && state.stories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16),
                          itemCount: state.stories.length + 1,
                          itemBuilder: (context, i) {
                            if (i == 0) return _buildAddStory();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: StoryCircle(
                                story: state.stories[i - 1],
                                onTap: () => _openStoryViewer(
                                    context, state.stories, i - 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (state is DashboardInitial || state is DashboardLoading)
                    const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()))
                  else if (state is DashboardError)
                    SliverFillRemaining(child: _buildErrorState(state))
                  else if (state is DashboardLoaded)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => PostCardWidget(post: state.posts[i]),
                        childCount: state.posts.length,
                      ),
                    ),
                  if (state is DashboardLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  if (state is DashboardLoaded &&
                      state.posts.isNotEmpty &&
                      !state.hasMorePosts)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            "You're all caught up!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreatePostModal(context),
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildAddStory() {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 10),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              color: Colors.white,
            ),
            child: const Icon(Icons.add, color: Colors.blueAccent, size: 30),
          ),
          const SizedBox(height: 8),
          const Text('Your Story',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(DashboardError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (state.retryCallback != null)
              ElevatedButton(
                onPressed: state.retryCallback,
                child: const Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'Search...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
