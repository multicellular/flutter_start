import 'package:flutter/material.dart';
import 'dart:math';

import 'dart:ui';

///简单随机色
///
Color randomRGB() {
  Random random = Random();
  int r = 30 + random.nextInt(200);
  int g = 30 + random.nextInt(200);
  int b = 30 + random.nextInt(200);
  return Color.fromARGB(255, r, g, b);
}

class RunBall extends StatefulWidget {
  @override
  _RunBallState createState() => _RunBallState();
}

class _RunBallState extends State<RunBall> with SingleTickerProviderStateMixin {
  AnimationController controller;
  // var _oldTime = DateTime.now().millisecondsSinceEpoch; //首次运行时时间
  List<Ball> _balls = [];
  Rect _area = Rect.fromLTRB(0 + 5.0, 0 + 5.0, 365 + 5.0, 710 + 5.0);
  // var _ball =
  //     Ball(color: Colors.blueAccent, r: 10, x: 40.0 + 140, y: 200.0 + 100);

  @override
  Widget build(BuildContext context) {
    // ---->[使用:_RunBallState#build]----
    var child = Scaffold(
      body: CustomPaint(
        painter: RunBallView(_balls, _area),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '粒子分裂',
          style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(148, 198, 246, 248),
      ),
      body: GestureDetector(
        //手势组件，做点击响应
        child: child,
        onTap: () {
          controller.forward(); //执行动画
        },
      ),
    );
  }

  @override
  void initState() {
    controller = //创建AnimationController对象
        AnimationController(duration: Duration(days: 999 * 365), vsync: this);
    controller.addListener(() {
      //添加监听,执行渲染
      _render();
    });
    //[4]._RunBallState中初始化时生成随机信息的小球
    for (var i = 0; i < 6; i++) {
      Random random = Random();
      _balls.add(Ball(
          color: randomRGB(),
          r: 8 + 4 * random.nextDouble(),
          vX: 3 * random.nextDouble() * pow(-1, random.nextInt(20)),
          vY: 3 * random.nextDouble() * pow(-1, random.nextInt(20)),
          aY: 0.1,
          x: 100 * random.nextDouble(),
          y: 200 * random.nextDouble()));
    }
  }

  @override
  void dispose() {
    controller.dispose(); // 资源释放
    super.dispose();
  }

  //渲染方法，更新状态
  //[3].渲染时批量更改信息
  _render() {
    for (var i = 0; i < _balls.length; i++) {
      updateBall(i);
    }
    setState(() {});
  }

  void updateBall(int i) {
    var _ball = _balls[i];
    if (_ball.r < 1) {
      //半径小于0.3就移除
      _balls.removeAt(i);
      if (_balls.length < 50) {
        Random random = Random();
        _balls.add(Ball(
            color: randomRGB(),
            r: 5 + 4 * random.nextDouble(),
            vX: 3 * random.nextDouble() * pow(-1, random.nextInt(100)),
            vY: 3 * random.nextDouble() * pow(-1, random.nextInt(100)),
            aY: 0.1,
            x: 200,
            y: 300));
      }
    }
    //运动学公式
    _ball.x += _ball.vX;
    _ball.y += _ball.vY;
    _ball.vX += _ball.aX;
    _ball.vY += _ball.aY;
    // //限定下边界
    // if (_ball.y > _area.bottom - _ball.r) {
    //   _ball.y = _area.bottom - _ball.r;
    //   _ball.vY = -_ball.vY;
    //   _ball.color=randomRGB();//碰撞后随机色
    // }
    //限定上边界
    if (_ball.y < _area.top + _ball.r) {
      _ball.y = _area.top + _ball.r;
      _ball.vY = -_ball.vY;
      _ball.color = randomRGB(); //碰撞后随机色
    }

    //限定左边界
    if (_ball.x < _area.left + _ball.r) {
      _ball.x = _area.left + _ball.r;
      _ball.vX = -_ball.vX;
      _ball.color = randomRGB(); //碰撞后随机色
    }

    //限定右边界
    if (_ball.x > _area.right - _ball.r) {
      _ball.x = _area.right - _ball.r;
      _ball.vX = -_ball.vX;
      _ball.color = randomRGB(); //碰撞后随机色
    }
    //限定下边界
    if (_ball.y > _area.bottom) {
      var newBall = Ball.fromBall(_ball);
      newBall.r = newBall.r / 2;
      newBall.vX = -newBall.vX;
      newBall.vY = -newBall.vY;
      _balls.add(newBall);
      _ball.r = _ball.r / 2;

      _ball.y = _area.bottom;
      _ball.vY = -_ball.vY;
      _ball.color = randomRGB(); //碰撞后随机色
    }
  }
}

///小球信息描述类
class Ball {
  double aX; //加速度
  double aY; //加速度Y
  double vX; //速度X
  double vY; //速度Y
  double x; //点位X
  double y; //点位Y
  Color color; //颜色
  double r; //小球半径

  Ball(
      {this.x = 0,
      this.y = 0,
      this.color,
      this.r = 10,
      this.aX = 0,
      this.aY = 0,
      this.vX = 0,
      this.vY = 0}); //复制一个小球

  Ball.fromBall(Ball ball) {
    this.x = ball.x;
    this.y = ball.y;
    this.color = ball.color;
    this.r = ball.r;
    this.aX = ball.aX;
    this.aY = ball.aY;
    this.vX = ball.vX;
    this.vY = ball.vY;
  }
}

///画板Painter
class RunBallView extends CustomPainter {
  List<Ball> _balls; //小球
  Rect _area; //运动区域
  Paint mPaint; //主画笔
  Paint bgPaint; //背景画笔

  RunBallView(this._balls, this._area) {
    mPaint = new Paint();
    bgPaint = new Paint()..color = Color.fromARGB(148, 198, 246, 248);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(_area, bgPaint);
    // _drawBall(canvas, _ball);
    _balls.forEach((ball) {
      _drawBall(canvas, ball);
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  ///使用[canvas] 绘制某个[ball]
  void _drawBall(Canvas canvas, Ball ball) {
    canvas.drawCircle(
        Offset(ball.x, ball.y), ball.r, mPaint..color = ball.color);
  }
}
