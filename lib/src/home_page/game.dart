import 'dart:math';

import 'package:flutter/material.dart';
// import 'mycolor.dart';
// import 'tile.dart';
// import 'grid.dart';
// import 'game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class GamePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GamePageState();
  }
}

class _GamePageState extends State<GamePage> {
  List<List<int>> grid = [];
  List<List<int>> gridNew = [];
  SharedPreferences sharedPreferences;
  int score = 0;
  bool isgameOver = false;
  bool isgameWon = false;

  List<Widget> getGrid(double width, double height) {
    List<Widget> grids = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        int num = grid[i][j];
        String number;
        int color;
        if (num == 0) {
          color = MyColor.emptyGridBackground;
          number = "";
        } else if (num == 2 || num == 4) {
          color = MyColor.gridColorTwoFour;
          number = "$num";
        } else if (num == 8 || num == 64 || num == 256) {
          color = MyColor.gridColorEightSixtyFourTwoFiftySix;
          number = "$num";
        } else if (num == 16 || num == 32 || num == 1024) {
          color = MyColor.gridColorSixteenThirtyTwoOneZeroTwoFour;
          number = "$num";
        } else if (num == 128 || num == 512) {
          color = MyColor.gridColorOneTwentyEightFiveOneTwo;
          number = "$num";
        } else {
          color = MyColor.gridColorWin;
          number = "$num";
        }
        double size;
        String n = "$number";
        switch (n.length) {
          case 1:
          case 2:
            size = 40.0;
            break;
          case 3:
            size = 30.0;
            break;
          case 4:
            size = 20.0;
            break;
        }
        grids.add(Tile(number, width, height, color, size));
      }
    }
    return grids;
  }

  void handleGesture(int direction) {
    /*
    
      0 = up
      1 = down
      2 = left
      3 = right
    */
    bool flipped = false;
    bool played = true;
    bool rotated = false;
    if (direction == 0) {
      setState(() {
        grid = transposeGrid(grid);
        grid = flipGrid(grid);
        rotated = true;
        flipped = true;
      });
    } else if (direction == 1) {
      setState(() {
        grid = transposeGrid(grid);
        rotated = true;
      });
    } else if (direction == 2) {
    } else if (direction == 3) {
      setState(() {
        grid = flipGrid(grid);
        flipped = true;
      });
    } else {
      played = false;
    }

    if (played) {
      // print('playing');
      List<List<int>> past = copyGrid(grid);
      // print('past ${past}');
      for (int i = 0; i < 4; i++) {
        setState(() {
          List result = operate(grid[i], score, sharedPreferences);
          score = result[0];
          // print('score in set state ${score}');
          grid[i] = result[1];
        });
      }
      setState(() {
        grid = addNumber(grid, gridNew);
      });
      bool changed = compare(past, grid);
      // print('changed ${changed}');
      if (flipped) {
        setState(() {
          grid = flipGrid(grid);
        });
      }

      if (rotated) {
        setState(() {
          grid = transposeGrid(grid);
        });
      }

      if (changed) {
        setState(() {
          grid = addNumber(grid, gridNew);
          // print('is changed');
        });
      } else {
        // print('not changed');
      }

      bool gameover = isGameOver(grid);
      if (gameover) {
        // print('game over');
        setState(() {
          isgameOver = true;
        });
      }

      bool gamewon = isGameWon(grid);
      if (gamewon) {
        // print("GAME WON");
        setState(() {
          isgameWon = true;
        });
      }
      // print(grid);
      // print(score);
    }
  }

  @override
  void initState() {
    grid = blankGrid();
    gridNew = blankGrid();
    addNumber(grid, gridNew);
    addNumber(grid, gridNew);
    super.initState();
  }

  Future<String> getHighScore() async {
    sharedPreferences = await SharedPreferences.getInstance();
    int score = sharedPreferences.getInt('high_score');
    if (score == null) {
      score = 0;
    }
    return score.toString();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double gridWidth = (width - 80) / 4;
    double gridHeight = gridWidth;
    double height = 30 + (gridHeight * 4) + 10;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '2048',
          style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(MyColor.gridBackground),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Container(
                  width: 200.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Color(MyColor.gridBackground),
                  ),
                  height: 82.0,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 10.0, bottom: 2.0),
                        child: Text(
                          'Score',
                          style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          '$score',
                          style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                height: height,
                child: Stack(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: GestureDetector(
                        child: GridView.count(
                          primary: false,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          crossAxisCount: 4,
                          children: getGrid(gridWidth, gridHeight),
                        ),
                        onVerticalDragEnd: (DragEndDetails details) {
                          //primaryVelocity -ve up +ve down
                          if (details.primaryVelocity < 0) {
                            handleGesture(0);
                          } else if (details.primaryVelocity > 0) {
                            handleGesture(1);
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          //-ve right, +ve left
                          if (details.primaryVelocity > 0) {
                            handleGesture(2);
                          } else if (details.primaryVelocity < 0) {
                            handleGesture(3);
                          }
                        },
                      ),
                    ),
                    isgameOver
                        ? Container(
                            height: height,
                            color: Color(MyColor.transparentWhite),
                            child: Center(
                              child: Text(
                                'Game over!',
                                style: TextStyle(
                                    fontSize: 30.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(MyColor.gridBackground)),
                              ),
                            ),
                          )
                        : SizedBox(),
                    isgameWon
                        ? Container(
                            height: height,
                            color: Color(MyColor.transparentWhite),
                            child: Center(
                              child: Text(
                                'You Won!',
                                style: TextStyle(
                                    fontSize: 30.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(MyColor.gridBackground)),
                              ),
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
                color: Color(MyColor.gridBackground),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Color(MyColor.gridBackground),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: IconButton(
                          iconSize: 35.0,
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              grid = blankGrid();
                              gridNew = blankGrid();
                              grid = addNumber(grid, gridNew);
                              grid = addNumber(grid, gridNew);
                              score = 0;
                              isgameOver = false;
                              isgameWon = false;
                            });
                          },
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Color(MyColor.gridBackground),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          children: <Widget>[
                            Text(
                              'High Score',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                            FutureBuilder<String>(
                              future: getHighScore(),
                              builder: (ctx, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(
                                    snapshot.data,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  );
                                } else {
                                  return Text(
                                    '0',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  );
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MyColor {
  static int gridBackground = 0xFFa2917d;
  static int gridColorTwoFour = 0xFFeee4da;
  static int fontColorTwoFour = 0xFF766c62;
  static int emptyGridBackground = 0xFFbfafa0;
  static int gridColorEightSixtyFourTwoFiftySix = 0xFFf5b27e;
  static int gridColorOneTwentyEightFiveOneTwo = 0xFFf77b5f;
  static int gridColorSixteenThirtyTwoOneZeroTwoFour = 0xFFecc402;
  static int gridColorWin = 0xFF60d992;
  static int transparentWhite = 0x80FFFFFF;
}

class Tile extends StatefulWidget {
  String number;
  double width, height;
  int color;
  double size;
  Tile(this.number, this.width, this.height, this.color, this.size);

  @override
  State<StatefulWidget> createState() {
    return _TileState();
  }
}

class _TileState extends State<Tile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text(
          widget.number,
          style: TextStyle(
              fontSize: widget.size,
              fontWeight: FontWeight.bold,
              color: Color(MyColor.fontColorTwoFour)),
        ),
      ),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
          color: Color(widget.color),
          borderRadius: BorderRadius.all(Radius.circular(10.0))),
    );
  }
}

List<List<int>> blankGrid() {
  List<List<int>> rows = [];
  for (int i = 0; i < 4; i++) {
    rows.add([0, 0, 0, 0]);
  }
  return rows;
}

bool compare(List<List<int>> a, List<List<int>> b) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (a[i][j] != b[i][j]) {
        return false;
      }
    }
  }
  return true;
}

List<List<int>> copyGrid(List<List<int>> grid) {
  List<List<int>> extraGrid = blankGrid();
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      extraGrid[i][j] = grid[i][j];
    }
  }
  return extraGrid;
}

List<List<int>> flipGrid(List<List<int>> grid) {
  for (int i = 0; i < 4; i++) {
    List<int> row = grid[i];
    grid[i] = row.reversed.toList();
  }
  return grid;
}

List<List<int>> transposeGrid(List<List<int>> grid) {
  List<List<int>> newGrid = blankGrid();
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      newGrid[i][j] = grid[j][i];
    }
  }
  return newGrid;
}

List<List<int>> addNumber(List<List<int>> grid, List<List<int>> gridNew) {
  List<Point> options = [];
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (grid[i][j] == 0) {
        options.add(Point(i, j));
      }
    }
  }
  if (options.length > 0) {
    int spotRandomIndex = new Random().nextInt(options.length);
    Point spot = options[spotRandomIndex];
    int r = new Random().nextInt(100);
    grid[spot.x][spot.y] = r > 50 ? 4 : 2;
    gridNew[spot.x][spot.y] = 1;
  }

  return grid;
}

class Point {
  int x;
  int y;

  Point(this.x, this.y);
}

List operate(List<int> row, int score, SharedPreferences sharedPref) {
  row = slide(row);
  List result = combine(row, score, sharedPref);
  int sc = result[0];
  row = result[1];
  row = slide(row);

  // print('from func ${sc}');
  return [sc, row];
}

List<int> filter(List<int> row) {
  List<int> temp = [];
  for (int i = 0; i < row.length; i++) {
    if (row[i] != 0) {
      temp.add(row[i]);
    }
  }
  return temp;
}

List<int> slide(List<int> row) {
  List<int> arr = filter(row);
  int missing = 4 - arr.length;
  List<int> zeroes = zeroArray(missing);
  arr = zeroes + arr;
  return arr;
}

List<int> zeroArray(int length) {
  List<int> zeroes = [];
  for (int i = 0; i < length; i++) {
    zeroes.add(0);
  }
  return zeroes;
}

List combine(List<int> row, int score, SharedPreferences sharedPref) {
  for (int i = 3; i >= 1; i--) {
    int a = row[i];
    int b = row[i - 1];
    if (a == b) {
      row[i] = a + b;
      score += row[i];
      int sc = sharedPref.getInt('high_score');
      if (sc == null) {
        sharedPref.setInt('high_score', score);
      } else {
        if (score > sc) {
          sharedPref.setInt('high_score', score);
        }
      }
      row[i - 1] = 0;
    }
  }
  return [score, row];
}

bool isGameWon(List<List<int>> grid) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (grid[i][j] == 2048) {
        return true;
      }
    }
  }
  return false;
}

bool isGameOver(List<List<int>> grid) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      if (grid[i][j] == 0) {
        return false;
      }
      if (i != 3 && grid[i][j] == grid[i + 1][j]) {
        return false;
      }
      if (j != 3 && grid[i][j] == grid[i][j + 1]) {
        return false;
      }
    }
  }
  return true;
}
