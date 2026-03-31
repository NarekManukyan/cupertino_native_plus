import 'package:cupertino_native_plus/cupertino_native_plus.dart';
import 'package:flutter/cupertino.dart';

class SearchBarDemoPage extends StatefulWidget {
  const SearchBarDemoPage({super.key});

  @override
  State<SearchBarDemoPage> createState() => _SearchBarDemoPageState();
}

class _SearchBarDemoPageState extends State<SearchBarDemoPage> {
  String _query = '';
  String _submitted = '';
  final _controller = CNSearchBarController();

  static const _items = [
    'Apples',
    'Bananas',
    'Cherries',
    'Dates',
    'Elderberries',
    'Figs',
    'Grapes',
    'Honeydew',
    'Kiwi',
    'Lemon',
  ];

  List<String> get _filtered => _query.isEmpty
      ? _items
      : _items
            .where((i) => i.toLowerCase().contains(_query.toLowerCase()))
            .toList();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Search Bar')),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expandable',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CNSearchBar(
                        placeholder: 'Search fruits...',
                        expandable: true,
                        controller: _controller,
                        onChanged: (v) => setState(() => _query = v),
                        onSubmitted: (v) => setState(() => _submitted = v),
                        onCancelTap: () => setState(() => _query = ''),
                      ),
                    ],
                  ),
                  if (_submitted.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Submitted: "$_submitted"',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Always Expanded',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  CNSearchBar(
                    placeholder: 'Search...',
                    expandable: false,
                    initiallyExpanded: true,
                    showCancelButton: false,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tinted',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CNSearchBar(
                        placeholder: 'Search...',
                        expandable: true,
                        tint: CupertinoColors.systemPurple,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Results',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No results',
                        style: TextStyle(color: CupertinoColors.secondaryLabel),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(indent: 16),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(_filtered[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
