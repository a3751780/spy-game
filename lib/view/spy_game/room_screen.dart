import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // 加入這行

class RoomScreen extends StatefulWidget {
  final String playerName;
  final String roomCode;
  final bool isHost;

  const RoomScreen({super.key, required this.playerName, required this.roomCode, required this.isHost});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;

  List<String> _players = [];
  bool _isGameStarted = false;
  bool _isVotingPhase = false;
  String _myWord = "";
  final List<String> _chatLogs = [];

  // 淘汰與投票
  String? _votedPlayer;
  bool _showElimination = false;
  String _eliminatedPlayerName = "";

  final TextEditingController _descController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _currentRound = 1;
  final int _maxRounds = 3;
  bool _hasSubmittedThisRound = false; // 記錄自己這回合是否已發言
  int _submittedCount = 0;             // 記錄這回合總共有幾個人發言了

  String _undercoverName = ""; // 新增這行：記錄誰是臥底

  Map<String, String> _votes = {}; // 記錄每個人投給誰 {投票者: 被投者}

  @override
  void initState() {
    super.initState();
    _setupSupabaseRealtime();
  }

  void _setupSupabaseRealtime() {
    // 加入房間的專屬 Channel
    _channel = _supabase.channel('room_${widget.roomCode}',
        opts: const RealtimeChannelConfig(key: 'room_presence'));

    // 1. 監聽 Presence (玩家上下線)
    _channel.onPresenceSync((_) {
      // 這裡的 states 是一個 List<SinglePresenceState>
      final states = _channel.presenceState();
      final currentPlayers = <String>[];

      // 第一層迴圈：遍歷每一個 SinglePresenceState
      for (final state in states) {

        // 第二層迴圈：遍歷裡面的每一個 Presence 物件
        for (final presence in state.presences) {

          // 從 payload 裡面把我們當初 track 的 player_name 拿出來
          if (presence.payload.containsKey('player_name')) {
            currentPlayers.add(presence.payload['player_name'].toString());
          }
        }
      }

      setState(() {
        _players = currentPlayers.toSet().toList(); // 去重複並更新畫面
        // 【防呆機制】：如果遊戲已經開始，但人數低於2人，強制結束遊戲
        if (_isGameStarted && _players.length < 2) {
          _isGameStarted = false;
          _isVotingPhase = false;
          _chatLogs.add("⚠️ 玩家斷線，人數不足，遊戲強制結束！");
        }

        // 【防呆機制】：如果自己不是房主，但發現房主(通常是列表中第一個)不見了
        // 可以寫一個邏輯把房主權限轉移給下一個人，或者直接把大家踢回大廳
      });
    });

    // 2. 監聽遊戲廣播 (Broadcast)
    _channel.onBroadcast(event: 'game_action', callback: _handleGameAction);

    // 3. 訂閱並追蹤自己的狀態
    _channel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // 連線成功，上傳自己的名字到 Presence
        _channel.track({'player_name': widget.playerName});

        // 隱藏重連提示 (如果有顯示的話)
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

      } else if (status == RealtimeSubscribeStatus.closed ||
          status == RealtimeSubscribeStatus.channelError) {

        // 顯示斷線提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('網路連線中斷，嘗試重新連線中...'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3), // 顯示直到重連成功
              )
          );

          // 實務上可以寫一個自動重連機制，或者讓使用者點擊重連
        }
      }
    });
  }

  // 接收廣播邏輯
  void _handleGameAction(Map<String, dynamic> payload) {
    if (!mounted) return;
    final action = payload['action'];

    setState(() {
      if (action == 'start_game') {
        _isGameStarted = true;
        _currentRound = 1;
        _submittedCount = 0;
        _hasSubmittedThisRound = false;
        _undercoverName = payload['undercover']; // 新增這行：存下臥底是誰
        _myWord = payload['words'][widget.playerName] ?? '旁觀者';
        _chatLogs.add("--- 遊戲開始，你的詞語是【$_myWord】 ---");

      } else if (action == 'chat') {
        // 顯示發言，並加上回合數標籤
        _chatLogs.add("[第$_currentRound回合] ${payload['sender']}: ${payload['text']}");
        _scrollToBottom();
        _submittedCount++; // 增加這回合的發言人數

        // 【核心邏輯】：由房主當裁判，判斷這回合是不是大家都發言完畢了
        if (widget.isHost && _submittedCount >= _players.length) {
          if (_currentRound < _maxRounds) {
            // 還沒滿3回合，廣播進入下一回合
            _sendBroadcast({'action': 'next_round', 'round': _currentRound + 1});
          } else {
            // 滿3回合了，廣播進入投票
            _sendBroadcast({'action': 'voting_phase'});
          }
        }

      } else if (action == 'next_round') {
        // 收到進入下一回合的指令
        _currentRound = payload['round'];
        _submittedCount = 0;             // 重置發言人數
        _hasSubmittedThisRound = false;  // 開放大家重新發言
        _chatLogs.add("--- 進入第 $_currentRound 回合 ---");
        _scrollToBottom();

      } else if (action == 'voting_phase') {
        _isVotingPhase = true;
        _chatLogs.add("--- 發言結束，進入投票階段！ ---");
        _scrollToBottom();

      } else if (action == 'voting_phase') {
        _isVotingPhase = true;
        _votes.clear(); // 進入投票階段時，清空計票板
        _chatLogs.add("--- 發言結束，進入投票階段！ ---");
        _scrollToBottom();

      } else if (action == 'submit_vote') {
        // 收到有人投票的廣播
        String voter = payload['voter'];
        String target = payload['target'];
        _votes[voter] = target;

        _chatLogs.add("[$voter] 已經完成投票。");
        _scrollToBottom();

        // 【核心邏輯】：由房主判斷是不是大家都投完了
        if (widget.isHost && _votes.length >= _players.length) {
          // 找出得票最多的人
          Map<String, int> voteCount = {};
          for (var t in _votes.values) {
            voteCount[t] = (voteCount[t] ?? 0) + 1;
          }

          // 簡單的找最高票邏輯 (如果平手，這裡會選到最先達到該票數的人)
          String highestVotedPlayer = "";
          int maxVotes = 0;
          voteCount.forEach((player, count) {
            if (count > maxVotes) {
              maxVotes = count;
              highestVotedPlayer = player;
            }
          });

          // 廣播淘汰最高票的人
          _sendBroadcast({
            'action': 'eliminate',
            'target': highestVotedPlayer,
            'votes': _votes // 順便把票數明細傳下去給大家看
          });
        }

      }else if (action == 'eliminate') {
        // 淘汰階段：可以在這裡印出大家的投票明細
        if (payload['votes'] != null) {
          Map<String, dynamic> finalVotes = payload['votes'];
          _chatLogs.add("--- 投票結果 ---");
          finalVotes.forEach((voter, target) {
            _chatLogs.add("$voter 投給了 $target");
          });
        }
        _triggerEliminationAnimation(payload['target']);
      }
    });
  }

  // 發送廣播共用函式
  Future<void> _sendBroadcast(Map<String, dynamic> payload) async {
    // 1. 透過 Supabase 傳送給房間裡的其他玩家
    await _channel.sendBroadcastMessage(event: 'game_action', payload: payload);

    // 2. 自己本地端也立刻執行這段邏輯 (因為廣播不會回傳給自己)
    _handleGameAction(payload);
  }

  // === 房主專屬功能 ===
  Future<void> _startGame() async {
    if (!widget.isHost) return;

    // 更新資料庫狀態
    await _supabase.from('rooms').update({'status': 'playing'}).eq('room_code', widget.roomCode);

    // 隨機抽取一組題庫
    final wordsData = await _supabase.from('word_pairs').select().limit(10);
    final selectedPair = (wordsData..shuffle()).first;

    // 分配臥底與平民
    final playersCopy = List<String>.from(_players)..shuffle();
    final undercoverName = playersCopy.first; // 抽一人當臥底

    Map<String, String> wordAssignments = {};
    for (var p in _players) {
      wordAssignments[p] = (p == undercoverName) ? selectedPair['undercover_word'] : selectedPair['civilian_word'];
    }

    // 廣播給大家
    _sendBroadcast({
      'action': 'start_game',
      'words': wordAssignments,
      'undercover': undercoverName // 新增這行
    });

  }

  // 房主控制進入投票階段
  void _startVotingPhase() {
    _sendBroadcast({'action': 'voting_phase'});
  }

  void _submitDescription() {
    if (_descController.text.trim().isEmpty || _hasSubmittedThisRound) return;

    final text = _descController.text.trim();
    _descController.clear();

    // 標記自己已經發言，避免重複輸入
    setState(() {
      _hasSubmittedThisRound = true;
    });

    _sendBroadcast({'action': 'chat', 'sender': widget.playerName, 'text': text});
  }

  // --- 投票邏輯 ---
  void _submitVote(String target) {
    if (_votedPlayer != null) return; // 已經投過就不能再投

    setState(() {
      _votedPlayer = target;
      _chatLogs.add("--- 你已投票給 $target，等待其他人投票... ---");
      _scrollToBottom();
    });

    // 廣播告訴大家「我投了這張票」
    _sendBroadcast({
      'action': 'submit_vote',
      'voter': widget.playerName,
      'target': target
    });
  }

  void _triggerEliminationAnimation(String targetPlayer) {
    setState(() {
      _eliminatedPlayerName = targetPlayer;
      _showElimination = true; // 顯示蓋章動畫
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      setState(() {
        _showElimination = false; // 隱藏蓋章動畫
      });

      // 判斷勝負邏輯
      bool isUndercover = (targetPlayer == _undercoverName);
      String title = isUndercover ? "🎉 平民獲勝 🎉" : "💀 臥底獲勝 💀";
      String content = isUndercover
          ? "$targetPlayer 是臥底！恭喜你們抓對人了！"
          : "$targetPlayer 是平民！抓錯人了，真正的臥底是 $_undercoverName！";

      // 彈出結算視窗
      showDialog(
        context: context,
        barrierDismissible: false, // 規定玩家必須點擊按鈕才能關閉視窗
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(title, style: TextStyle(color: isUndercover ? Colors.green : Colors.red)),
            content: Text(content, style: const TextStyle(color: Colors.white, fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 關閉視窗

                  // 玩家按下確認後，才真正回到大廳，並重置所有遊戲狀態！
                  setState(() {
                    _isVotingPhase = false;
                    _isGameStarted = false;
                    _chatLogs.clear();       // 清空上一場的聊天紀錄
                    _votedPlayer = null;     // 清空投票狀態
                  });
                },
                child: const Text('回到大廳', style: TextStyle(color: Colors.deepPurpleAccent)),
              ),
            ],
          );
        },
      );
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    _descController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // UI 佈局 (與之前的設計風格一致)
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false, // 阻止預設的返回行為
        onPopInvoked: (didPop) async {
          if (didPop) return;

          // 彈出確認視窗
          final shouldLeave = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('確定要離開房間嗎？'),
                content: const Text('離開後遊戲可能會中斷喔！'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('確定離開', style: TextStyle(color: Colors.red))),
                ],
              )
          );

          if (shouldLeave == true && mounted) {
            Navigator.of(context).pop(); // 真的退出
          }
        },
        child: Scaffold(
          appBar: AppBar(title: Text('房間: ${widget.roomCode}')),
          body: Stack(
            children: [
              _isGameStarted ? _buildGameUI() : _buildWaitingRoomUI(),
              if (_showElimination) _buildEliminationOverlay(),
            ],
          ),
        )
    );
  }

  Widget _buildWaitingRoomUI() {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(16.0), child: Text('等待玩家加入...', style: TextStyle(fontSize: 18, color: Colors.white70))),
        Expanded(
          child: ListView.builder(
            itemCount: _players.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.deepPurpleAccent, child: Icon(Icons.person, color: Colors.white)),
                title: Text(_players[index]),
                trailing: _players[index] == widget.playerName ? const Text('自己') : null,
              );
            },
          ),
        ),
        if (widget.isHost)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: _players.length >= 2 ? _startGame : null, // 至少兩人才能開始
              child: const Text('開始遊戲', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          )
      ],
    );
  }

  Widget _buildGameUI() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.deepPurple.withOpacity(0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 顯示目前回合數
              Text(_isVotingPhase ? '投票階段' : '第 $_currentRound / $_maxRounds 回合',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
              Text('你的詞語: $_myWord ${widget.playerName == _undercoverName ? "(臥底)" : "(平民)"}',
                  style: const TextStyle(fontSize: 18, color: Colors.white)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatLogs.length,
            itemBuilder: (context, index) {
              final log = _chatLogs[index];
              final isSystem = log.startsWith("---");
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(log, style: TextStyle(color: isSystem ? Colors.grey : Colors.white70, fontStyle: isSystem ? FontStyle.italic : FontStyle.normal, fontSize: 16)),
              );
            },
          ),
        ),
        const Divider(height: 1, color: Colors.white24),
        if (!_isVotingPhase) _buildInputArea() else _buildVotingArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _descController,
              enabled: !_hasSubmittedThisRound, // 如果已經發言了，就鎖定輸入框
              decoration: InputDecoration(
                  hintText: _hasSubmittedThisRound ? '等待其他人發言...' : '描述你的詞...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10
              ),
              onSubmitted: (_) => _submitDescription(),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.send),
              color: _hasSubmittedThisRound ? Colors.grey : Colors.deepPurpleAccent,
              onPressed: _submitDescription
          ),
        ],
      ),
    );
  }

  Widget _buildVotingArea() {
    return Container(
      color: const Color(0xFF1E1E1E),
      height: 250,
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final target = _players[index];
          if (target == widget.playerName) return const SizedBox.shrink();
          final isVoted = _votedPlayer == target;
          return Card(
            color: isVoted ? Colors.redAccent.withOpacity(0.3) : Colors.black26,
            child: ListTile(
              title: Text(target),
              trailing: isVoted ? const Icon(Icons.check_circle, color: Colors.redAccent) : null,
              onTap: _votedPlayer == null ? () => _submitVote(target) : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEliminationOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          tween: Tween<double>(begin: 3.0, end: 1.0),
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: scale > 2.0 ? 0.0 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 6), borderRadius: BorderRadius.circular(16)),
                  child: Text('$_eliminatedPlayerName\n被淘汰', textAlign: TextAlign.center, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}