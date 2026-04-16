import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nameEnterController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // 創建房間
  Future<void> _createRoom() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // 隨機產生 4 位數房間號碼
      final roomCode = (Random().nextInt(9000) + 1000).toString();
      final name = _nameController.text;
      // 寫入 Supabase 資料庫
      await _supabase.from('rooms').insert({
        'room_code': roomCode,
        'host_name': _nameController.text,
        'status': 'waiting',
      });

      if (!mounted) return;
      _navigateToRoom(roomCode,name,true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('創建失敗: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 加入房間
  Future<void> _joinRoom() async {
    print("加入房間: ${_roomController.text}");
    if (_nameEnterController.text.isEmpty || _roomController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      print("加入房間: 成功觸發");
      final roomCode = _roomController.text;
      final name = _nameEnterController.text;

      // 查詢房間是否存在
      final data = await _supabase.from('rooms').select().eq('room_code', roomCode).maybeSingle();

      if (data == null) {
        throw Exception('找不到該房間號碼！');
      }
      if (data['status'] != 'waiting') {
        throw Exception('遊戲已經開始了！');
      }

      if (!mounted) return;
      _navigateToRoom(roomCode,name,false);
    } catch (e) {
      print("加入房間: 失敗觸發1 - $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      print('=== 加入房間發生錯誤 ===');
      print(e.toString());
      setState(() => _isLoading = false);
    }
  }

  void _navigateToRoom(String roomCode,String name ,bool isHost) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomScreen(
          playerName: name,
          roomCode: roomCode,
          isHost: isHost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('誰是臥底')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 80, color: Colors.deepPurpleAccent),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '玩家暱稱', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, minimumSize: const Size(double.infinity, 50)),
                onPressed: _createRoom,
                child: const Text('創建房間', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white24),
              const SizedBox(height: 32),
              TextField(
                controller: _nameEnterController,
                decoration: const InputDecoration(labelText: '加入的暱稱', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: '輸入房間號碼', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
                onPressed: _joinRoom,
                child: const Text('加入房間', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}