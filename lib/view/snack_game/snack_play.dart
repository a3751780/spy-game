import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

// 定義移動方向的列舉
enum Direction { up, down, left, right }

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({Key? key}) : super(key: key);

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  // 網格設定
  final int rowSize = 21;
  final int totalNumberOfSquares = 441; // 20 * 20 網格

  // 遊戲狀態變數
  List<int> snakePosition = [45, 65, 85]; // 初始蛇的身體位置（最後一個是頭）
  int foodPosition = 255; // 初始食物位置
  Direction currentDirection = Direction.down; // 初始方向
  bool isPlaying = false;
  int score = 0;
  Timer? gameTimer;

  // 開始遊戲
  void startGame() {
    setState(() {
      isPlaying = true;
      score = 0;
      snakePosition = [45, 65, 85];
      currentDirection = Direction.down;
      _generateNewFood();
    });

    // 遊戲主迴圈 (每 150 毫秒更新一次)
    gameTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      updateSnake();
      if (checkGameOver()) {
        timer.cancel();
        showGameOverDialog();
      }
    });
  }

  // 更新蛇的位置
  void updateSnake() {
    setState(() {
      int head = snakePosition.last;
      int newHead = head;

      // 根據目前方向計算下一個頭的位置
      switch (currentDirection) {
        case Direction.down:
          newHead = head + rowSize;
          break;
        case Direction.up:
          newHead = head - rowSize;
          break;
        case Direction.left:
          newHead = head - 1;
          break;
        case Direction.right:
          newHead = head + 1;
          break;
      }

      snakePosition.add(newHead); // 把新的頭加入

      // 檢查是否吃到食物
      if (newHead == foodPosition) {
        score++;
        _generateNewFood();
      } else {
        snakePosition.removeAt(0); // 沒吃到食物，移除尾巴（保持長度）
      }
    });
  }

  // 隨機產生食物，且不能長在蛇的身上
  void _generateNewFood() {
    int newFood;
    do {
      newFood = Random().nextInt(totalNumberOfSquares);
    } while (snakePosition.contains(newFood));
    foodPosition = newFood;
  }

  // 檢查遊戲是否結束
  bool checkGameOver() {
    int head = snakePosition.last;

    // 1. 檢查是否撞到自己 (頭的位置跟身體重疊)
    // 扣除掉最後一個元素(頭)，檢查剩下的身體是否包含頭的位置
    List<int> body = snakePosition.sublist(0, snakePosition.length - 1);
    if (body.contains(head)) {
      return true;
    }

    // 2. 檢查是否撞牆
    if (currentDirection == Direction.left && head % rowSize == 0) return true; // 撞左牆
    if (currentDirection == Direction.right && (head + 1) % rowSize == 0) return true; // 撞右牆
    if (currentDirection == Direction.up && head < rowSize) return true; // 撞上牆
    if (currentDirection == Direction.down && head >= totalNumberOfSquares - rowSize) return true; // 撞下牆

    return false;
  }

  // 顯示遊戲結束對話框
  void showGameOverDialog() {
    setState(() {
      isPlaying = false;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('遊戲結束!'),
          content: Text('你的最終分數是: $score'),
          actions: [
            TextButton(
              child: const Text('再玩一次'),
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 上方：分數看板
            Expanded(
              flex: 1,
              child: Center(
                child: Text('分數: $score',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),

            // 中間：遊戲網格 (使用 Stack 讓開始按鈕疊加在上面)
            Expanded(
              flex: 4,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0 && currentDirection != Direction.up) {
                    currentDirection = Direction.down;
                  } else if (details.delta.dy < 0 && currentDirection != Direction.down) {
                    currentDirection = Direction.up;
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 0 && currentDirection != Direction.left) {
                    currentDirection = Direction.right;
                  } else if (details.delta.dx < 0 && currentDirection != Direction.right) {
                    currentDirection = Direction.left;
                  }
                },
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    children: [
                      // 底層：遊戲網格
                      Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade800, width: 2),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: totalNumberOfSquares,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: rowSize,
                          ),
                          itemBuilder: (context, index) {
                            if (index == snakePosition.last) {
                              return _buildSquare(Colors.greenAccent.shade700);
                            }
                            if (snakePosition.contains(index)) {
                              return _buildSquare(Colors.green);
                            }
                            if (index == foodPosition) {
                              return _buildSquare(Colors.red);
                            }
                            return _buildSquare(Colors.grey[900]!);
                          },
                        ),
                      ),

                      // 表層：如果遊戲還沒開始，顯示半透明遮罩與大大的「開始遊戲」按鈕
                      if (!isPlaying)
                        Container(
                          margin: const EdgeInsets.all(10),
                          color: Colors.black.withOpacity(0.6), // 半透明黑色遮罩
                          child: Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              ),
                              onPressed: startGame,
                              child: const Text(
                                '開始遊戲',
                                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 下方：操作提示
            const Expanded(
              flex: 1,
              child: Center(
                child: Text('在畫面上滑動來控制方向', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 繪製單個格子的輔助函數
  Widget _buildSquare(Color color) {
    return Container(
      padding: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(color: color),
      ),
    );
  }
}

class SnakeSegment {
  final int id;
  int position;
  SnakeSegment({required this.id, required this.position});
}

class SmoothSnakeGamePage extends StatefulWidget {
  const SmoothSnakeGamePage({Key? key}) : super(key: key);

  @override
  State<SmoothSnakeGamePage> createState() => _SmoothSnakeGamePageState();
}

class _SmoothSnakeGamePageState extends State<SmoothSnakeGamePage> {
  final int rowSize = 20;
  final int totalNumberOfSquares = 400;
  final int speedMilliseconds = 150; // 移動速度
  String gameOverReason = ""; // 新增：用來記錄死掉的原因與位置

  List<SnakeSegment> snake = [];
  int foodPosition = 0;
  int _nextSegmentId = 0; // 用於產生唯一的 ID

  Direction currentDirection = Direction.down;
  Direction? queuedDirection; // 指令佇列，防止連續快速滑動導致的 bug

  bool isPlaying = false;
  int score = 0;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    _initSnake();
  }

  void _initSnake() {
    snake = [
      // 讓蛇出生在靠近左上角的地方
      SnakeSegment(id: _nextSegmentId++, position: rowSize * 1 + 2),
      SnakeSegment(id: _nextSegmentId++, position: rowSize * 2 + 2),
      SnakeSegment(id: _nextSegmentId++, position: rowSize * 3 + 2),
    ];
    _generateNewFood();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      score = 0;
      currentDirection = Direction.down;
      queuedDirection = null;
      _initSnake();
    });

    gameTimer = Timer.periodic(Duration(milliseconds: speedMilliseconds), (timer) {
      if (checkGameOverNextStep()) {
        timer.cancel();

        // ----------------------------------------------------
        // 新增：強制給蛇最後一步「撞上去」的指令，讓動畫有機會更新！
        // ----------------------------------------------------
        setState(() {
          if (queuedDirection != null) {
            currentDirection = queuedDirection!;
            queuedDirection = null;
          }
          // 讓身體往前遞補
          for (int i = 0; i < snake.length - 1; i++) {
            snake[i].position = snake[i + 1].position;
          }
          // 計算撞牆的蛇頭最終位置
          int finalHead = snake.last.position;
          switch (currentDirection) {
            case Direction.down: finalHead += rowSize; break;
            case Direction.up: finalHead -= rowSize; break;
            case Direction.left: finalHead -= 1; break;
            case Direction.right: finalHead += 1; break;
          }
          snake.last.position = finalHead; // 讓蛇頭超出邊界，這樣畫面會播動畫
        });

        // ----------------------------------------------------
        // 新增：等待動畫播完(剛好等於移動速度 speedMilliseconds)後，才跳出結算畫面
        // ----------------------------------------------------
        Future.delayed(Duration(milliseconds: speedMilliseconds), () {
          showGameOverDialog();
        });
        return;
      }
      updateSnake();
    });
  }

  void updateSnake() {
    setState(() {
      // 1. 套用玩家排隊中的轉向指令
      if (queuedDirection != null) {
        currentDirection = queuedDirection!;
        queuedDirection = null;
      }

      int headPos = snake.last.position;
      int newHeadPos = headPos;

      switch (currentDirection) {
        case Direction.down: newHeadPos += rowSize; break;
        case Direction.up: newHeadPos -= rowSize; break;
        case Direction.left: newHeadPos -= 1; break;
        case Direction.right: newHeadPos += 1; break;
      }

      bool ateFood = (newHeadPos == foodPosition);
      int oldTailPos = snake.first.position;

      // 2. 讓身體每一節往前遞補位置 (這會觸發 AnimatedPositioned 的滑動動畫)
      for (int i = 0; i < snake.length - 1; i++) {
        snake[i].position = snake[i + 1].position;
      }
      snake.last.position = newHeadPos;

      // 3. 如果吃到食物，在原本尾巴的位置長出一節新的身體
      if (ateFood) {
        score++;
        snake.insert(0, SnakeSegment(id: _nextSegmentId++, position: oldTailPos));
        _generateNewFood();
      }
    });
  }

  void _generateNewFood() {
    int newFood;
    List<int> currentPositions = snake.map((s) => s.position).toList();
    do {
      newFood = Random().nextInt(totalNumberOfSquares);
    } while (currentPositions.contains(newFood));
    foodPosition = newFood;
  }

  bool checkGameOverNextStep() {
    // 預判下一步是否會死掉
    if (queuedDirection != null) {
      currentDirection = queuedDirection!;
      queuedDirection = null;
    }

    int head = snake.last.position;

    // 先計算出如果照著當前方向走，蛇頭下一步的座標在哪
    int newHead = head;
    switch (currentDirection) {
      case Direction.down: newHead += rowSize; break;
      case Direction.up: newHead -= rowSize; break;
      case Direction.left: newHead -= 1; break;
      case Direction.right: newHead += 1; break;
    }

    // 計算目前的 X(行) 與 Y(列) 座標，為了顯示給玩家看
    int currentX = head % rowSize;
    int currentY = head ~/ rowSize;

    // 根據這一步「跨出」的結果來檢查是否撞牆，並記錄死因
    if (currentDirection == Direction.up && newHead < 0) {
      gameOverReason = "撞到了上方牆壁！\n(當前位置 -> X: $currentX, Y: $currentY)";
      return true;
    }
    if (currentDirection == Direction.down && newHead >= totalNumberOfSquares) {
      gameOverReason = "撞到了下方牆壁！\n(當前位置 -> X: $currentX, Y: $currentY)";
      return true;
    }
    if (currentDirection == Direction.left && head % rowSize == 0) {
      gameOverReason = "撞到了左方牆壁！\n(當前位置 -> X: $currentX, Y: $currentY)";
      return true;
    }
    if (currentDirection == Direction.right && (head + 1) % rowSize == 0) {
      gameOverReason = "撞到了右方牆壁！\n(當前位置 -> X: $currentX, Y: $currentY)";
      return true;
    }

    // 檢查撞身體 (忽略當前尾巴，因為尾巴下一步會往前移動)
    for (int i = 1; i < snake.length; i++) {
      if (snake[i].position == newHead) {
        gameOverReason = "咬到自己的身體了！\n(當前位置 -> X: $currentX, Y: $currentY)";
        return true;
      }
    }

    return false;
  }

  void showGameOverDialog() {
    setState(() {
      isPlaying = false;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('遊戲結束!'),
          content: Text('你的最終分數是: $score\n\n$gameOverReason'),
          actions: [
            TextButton(
              child: const Text('再玩一次'),
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 分數看板
            Expanded(
              flex: 1,
              child: Center(
                child: Text('分數: $score',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            // 遊戲區域
            Expanded(
              flex: 4,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0 && currentDirection != Direction.up) {
                    queuedDirection = Direction.down;
                  } else if (details.delta.dy < 0 && currentDirection != Direction.down) {
                    queuedDirection = Direction.up;
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 0 && currentDirection != Direction.left) {
                    queuedDirection = Direction.right;
                  } else if (details.delta.dx < 0 && currentDirection != Direction.right) {
                    queuedDirection = Direction.left;
                  }
                },
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800, width: 2),
                      color: Colors.grey.shade900,
                    ),
                    // 使用 LayoutBuilder 來動態計算每個格子的精確像素大小
                    // 使用 LayoutBuilder 來動態計算每個格子的精確像素大小
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 關鍵修改：取「寬度」和「高度」中較小的值，作為正方形的基準長度！
                        // 這樣不管螢幕怎麼擠壓，遊戲畫面絕對不會超出可見範圍。
                        double maxSquareArea = min(constraints.maxWidth, constraints.maxHeight);
                        double squareSize = maxSquareArea / rowSize;

                        return Center( // 加入 Center 確保正方型的遊戲區置中顯示
                          child: SizedBox(
                            width: maxSquareArea,
                            height: maxSquareArea,
                            child: Stack(
                              children: [
                                // 畫食物
                                Positioned(
                                  left: (foodPosition % rowSize) * squareSize,
                                  top: (foodPosition ~/ rowSize) * squareSize,
                                  width: squareSize,
                                  height: squareSize,
                                  child: _buildSquare(Colors.red),
                                ),

                                // 畫蛇的身體 (使用 AnimatedPositioned 產生絲滑移動效果)
                                ...snake.map((segment) {
                                  bool isHead = segment == snake.last;
                                  return AnimatedPositioned(
                                    key: ValueKey(segment.id),
                                    duration: Duration(milliseconds: speedMilliseconds),
                                    curve: Curves.linear,
                                    left: (segment.position % rowSize) * squareSize,
                                    top: (segment.position ~/ rowSize) * squareSize,
                                    width: squareSize,
                                    height: squareSize,
                                    child: _buildSquare(isHead ? Colors.greenAccent.shade400 : Colors.green),
                                  );
                                }).toList(),

                                // 遊戲未開始時的遮罩與按鈕
                                if (!isPlaying)
                                  Container(
                                    color: Colors.black.withOpacity(0.6),
                                    child: Center(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent.shade700,
                                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                        ),
                                        onPressed: startGame,
                                        child: const Text('開始遊戲',
                                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            const Expanded(flex: 1, child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildSquare(Color color) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(color: color),
      ),
    );
  }
}