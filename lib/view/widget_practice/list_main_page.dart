import 'package:flutter/material.dart';

import '../../model/user.dart';

void main() async{
  runApp(MaterialApp(
    title: 'Simple Demos',
    home: LazyLoadingList(),
  ));
}

class LazyLoadingList extends StatefulWidget {
  const LazyLoadingList({super.key});

  @override
  _LazyLoadingListState createState() => _LazyLoadingListState();
}

class _LazyLoadingListState extends State<LazyLoadingList> {
  final List<User> _items = List.generate(
    20, (index) => User(name: 'User $index', email: 'user$index@example.com', id: 0, phone: ''),
  ); // 初始數據
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent &&
          !_isLoading) {
        _loadMoreItems();
      }
    });
  }

  Future<void> _loadMoreItems() async {
    setState(() {
      _isLoading = true;
    });

    // 模擬網絡請求延遲
    await Future.delayed(Duration(seconds: 2));

    final newItems = List.generate(
      10,
          (index) => User(
          name: 'User ${_items.length + index}',
          email: 'user${_items.length + index}@example.coms',
          id: 0,
          phone: ''
      ),
    );
    setState(() {
      _items.addAll(newItems);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('分段載入列表'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final user = _items[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
          );
        },
      ),
    );
  }
}