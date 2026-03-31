import 'package:flutter/cupertino.dart';
import 'package:cupertino_native_plus/cupertino_native_plus.dart';

/// Demo page for native iOS 26 tab bar with search
class NativeTabBarDemoPage extends StatefulWidget {
  const NativeTabBarDemoPage({super.key});

  @override
  State<NativeTabBarDemoPage> createState() => _NativeTabBarDemoPageState();
}

class _NativeTabBarDemoPageState extends State<NativeTabBarDemoPage> {
  int _tabIndex = 0;
  String _searchQuery = '';
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _enableNativeTabBar();
  }

  Future<void> _enableNativeTabBar() async {
    await CNTabBarNative.enable(
      tabs: [
        CNTab(title: 'Home', sfSymbol: CNSymbol('house.fill')),
        CNTab(title: 'Browse', sfSymbol: CNSymbol('square.grid.2x2.fill')),
        CNTab(title: 'Library', sfSymbol: CNSymbol('books.vertical.fill')),
        CNTab(title: 'Search', isSearchTab: true),
      ],
      selectedIndex: _tabIndex,
      onTabSelected: (index) {
        setState(() {
          _tabIndex = index;
          if (index != 3) {
            _isSearchActive = false;
          }
        });
      },
      onSearchChanged: (query) {
        setState(() => _searchQuery = query);
      },
      onSearchActiveChanged: (active) {
        setState(() => _isSearchActive = active);
      },
    );
  }

  @override
  void dispose() {
    CNTabBarNative.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When search is active, show search results
    if (_isSearchActive || _tabIndex == 3) {
      return _buildSearchContent();
    }

    // Show tab content based on selected index
    switch (_tabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildBrowseTab();
      case 2:
        return _buildLibraryTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(largeTitle: const Text('Home')),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('Featured', [
                  _buildCard(
                    'Getting Started',
                    'Learn the basics',
                    CupertinoIcons.star_fill,
                  ),
                  _buildCard(
                    'New Features',
                    'iOS 26 Liquid Glass',
                    CupertinoIcons.sparkles,
                  ),
                ]),
                _buildSection('Recent', [
                  _buildCard(
                    'Project Alpha',
                    'Last edited today',
                    CupertinoIcons.folder_fill,
                  ),
                  _buildCard(
                    'Design System',
                    'Last edited yesterday',
                    CupertinoIcons.paintbrush_fill,
                  ),
                  _buildCard(
                    'Analytics',
                    'Last edited 3 days ago',
                    CupertinoIcons.chart_bar_fill,
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(largeTitle: const Text('Browse')),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('Categories', [
                  _buildCard('Design', '24 items', CupertinoIcons.paintbrush),
                  _buildCard('Development', '18 items', CupertinoIcons.hammer),
                  _buildCard('Marketing', '12 items', CupertinoIcons.chart_pie),
                  _buildCard(
                    'Finance',
                    '8 items',
                    CupertinoIcons.money_dollar_circle,
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(largeTitle: const Text('Library')),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('Saved Items', [
                  _buildCard(
                    'Favorites',
                    '15 items',
                    CupertinoIcons.heart_fill,
                  ),
                  _buildCard(
                    'Downloads',
                    '8 items',
                    CupertinoIcons.arrow_down_circle_fill,
                  ),
                  _buildCard('History', '32 items', CupertinoIcons.clock_fill),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    final sampleItems = [
      {
        'title': 'Dashboard',
        'subtitle': 'View your stats',
        'icon': CupertinoIcons.chart_pie,
      },
      {
        'title': 'Settings',
        'subtitle': 'Manage preferences',
        'icon': CupertinoIcons.gear,
      },
      {
        'title': 'Profile',
        'subtitle': 'Edit your account',
        'icon': CupertinoIcons.person_circle,
      },
      {
        'title': 'Notifications',
        'subtitle': '3 unread',
        'icon': CupertinoIcons.bell,
      },
      {
        'title': 'Help Center',
        'subtitle': 'Get support',
        'icon': CupertinoIcons.question_circle,
      },
      {
        'title': 'Privacy',
        'subtitle': 'View policy',
        'icon': CupertinoIcons.lock_shield,
      },
    ];

    final filteredItems = _searchQuery.isEmpty
        ? sampleItems
        : sampleItems
              .where(
                (item) => item['title'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 8),
              child: Text(
                _searchQuery.isEmpty
                    ? 'Suggestions'
                    : 'Results for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            size: 48,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No results',
                            style: TextStyle(color: CupertinoColors.systemGrey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return CupertinoListTile(
                          leading: Icon(
                            item['icon'] as IconData,
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                          title: Text(item['title'] as String),
                          subtitle: Text(item['subtitle'] as String),
                          trailing: const Icon(CupertinoIcons.chevron_forward),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: CupertinoTheme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_forward, size: 16),
        ],
      ),
    );
  }
}
