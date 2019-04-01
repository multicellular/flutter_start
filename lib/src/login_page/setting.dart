// import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:dio/dio.dart';
import '../component/event_bus.dart';
import '../models/config.dart';

// Options options = new BaseOptions(baseUrl: 'localhost:3000/api');
// Dio dio = new Dio(options);
// Dio dio = new Dio();
// dio.options.baseUrl = 'localhost:3000/api';
String baseUrl = DefaultConfig.baseUrl;
var urlPath = DefaultConfig.urlPath;

class SettingPage extends StatefulWidget {
  final dynamic profile;
  SettingPage(this.profile);
  @override
  SettingPageState createState() => new SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  // var _profile;

  // @override
  // initState(){
  //   super.initState();
  //   _initPage();
  // }

  // _initPage() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String token = await prefs.getString('token');
  //   if (token.isNotEmpty) {
  //     Options options =
  //         Options(headers: {HttpHeaders.authorizationHeader: token});
  //     Response response = await dio.get('$baseUrl/user/info', options: options);
  //     if (response.data['code'] == 0) {
  //       setState(() {
  //         _profile = response.data['user'];
  //       });
  //     }
  //   }
  // }

  TapGestureRecognizer _tapGestureRecognizer = new TapGestureRecognizer();

  @override
  void dispose() {
    //用到GestureRecognizer的话一定要调用其dispose方法释放资源
    _tapGestureRecognizer.dispose();
    super.dispose();
  }

  _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('uid');
    prefs.remove('token');
    evtBus.emit('sigin_out');
  }

  Widget avatarSection() {
    // Hero 动画
    return Hero(
      tag: widget.profile['id'],
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircleAvatar(
          // 背景透明
          backgroundColor: Colors.transparent,
          // 半径
          radius: 72.0,
          backgroundImage: NetworkImage(urlPath + widget.profile['avator']),
        ),
      ),
    );
  }

  Widget welcomeSection() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: "sigin out",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: _tapGestureRecognizer
              ..onTap = () {
                _signOut();
                Navigator.pop(context);
              },
          ),
        ]),
      ),
    );
  }

  Widget loremSection() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec hendrerit condimentum mauris id tempor. Praesent eu commodo lacus. Praesent eget mi sed libero eleifend tempor. Sed at fringilla ipsum. Duis malesuada feugiat urna vitae convallis. Aliquam eu libero arcu.',
        style: TextStyle(
          fontSize: 16.0,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        // 获取设备宽度
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          // 渐变色
          gradient: LinearGradient(colors: [
            Colors.blue,
            Colors.lightBlueAccent,
          ]),
        ),
        padding: EdgeInsets.all(28.0),
        child: Column(
          children: <Widget>[
            avatarSection(),
            welcomeSection(),
            loremSection(),
          ],
        ),
      ),
    );
  }
}
