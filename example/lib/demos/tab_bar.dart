import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:cupertino_native_plus/cupertino_native_plus.dart';

class TabBarDemoPage extends StatefulWidget {
  const TabBarDemoPage({super.key});

  @override
  State<TabBarDemoPage> createState() => _TabBarDemoPageState();
}

class _TabBarDemoPageState extends State<TabBarDemoPage> {
  int _selectedTab = 0;
  String _searchQuery = '';

  final _items = ['Apple', 'Banana', 'Cherry'];

  List<String> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    return _items
        .where(
          (item) => item.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Wait for first frame before enabling native tab bar
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _enableNativeTabBar();
    });
  }

  Future<void> _enableNativeTabBar() async {
    await CNTabBarNative.enable(
      tabs: [
        CNTab(title: 'Home', sfSymbol: CNSymbol('house.fill')),
        CNTab(
          title: 'Search',
          sfSymbol: CNSymbol('magnifyingglass'),
          isSearchTab: true,
        ),
        CNTab(title: 'Profile', sfSymbol: CNSymbol('person.fill')),
      ],
      selectedIndex: 0,
      onTabSelected: (index) {
        debugPrint('Tab selected: $index');
        setState(() => _selectedTab = index);
      },
      onSearchChanged: (query) {
        debugPrint('Native search: $query');
        setState(() => _searchQuery = query);
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
    return Container(
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: SafeArea(top: true, bottom: false, child: _buildTabContent()),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.house_fill,
            size: 64,
            color: CupertinoColors.systemBlue,
          ),
          SizedBox(height: 16),
          Text(
            'Home Tab',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Tap Search tab to test search',
            style: TextStyle(color: CupertinoColors.secondaryLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return _filteredItems.isEmpty
        ? const Center(
            child: Text(
              'No results',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 17,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CupertinoListTile(
                  title: Text(_filteredItems[index]),
                  leading: const Icon(
                    CupertinoIcons.circle_fill,
                    color: CupertinoColors.systemOrange,
                  ),
                ),
              );
            },
          );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_fill,
            size: 64,
            color: CupertinoColors.systemPurple,
          ),
          SizedBox(height: 16),
          Text(
            'Profile Tab',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
