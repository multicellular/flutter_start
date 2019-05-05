import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/event_bus.dart';
import '../models/config.dart';
import '../component/dioHttp.dart';

var urlPath = DefaultConfig.urlPath;

class ProfilePage extends StatefulWidget {
  final dynamic profile;
  final int uid;
  final bool personal;
  ProfilePage(this.uid, {this.personal = false}) : profile = null;
  ProfilePage.withProfile(this.profile, {this.personal = false}) : uid = null;

  @override
  ProfilePageState createState() => new ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  var _profile;
  @override
  initState() {
    super.initState();
    if (widget.profile == null) {
      _initProfile(widget.uid);
    } else {
      setState(() {
        _profile = widget.profile;
      });
    }
  }

  _initProfile(uid) async {
    var userRes = await dioHttp.httpGet('/user/profile', req: {'uid': uid});
    if (userRes != null) {
      setState(() {
        _profile = userRes['profile'];
      });
    }
  }

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
      tag: _profile['uid'],
      child: Padding(
          padding: EdgeInsets.all(16.0),
          child: ClipOval(
            child: SizedBox(
              width: 100.0,
              height: 100.0,
              // child: Image.network(urlPath + _profile['avator'],
              //     fit: BoxFit.cover),
              child: CachedNetworkImage(
                // width: 100.0,
                // height: 100.0,
                fit: BoxFit.cover,
                // placeholder: (context, string) {
                //   return Image.asset('assets/images/no_avatar.jpeg');
                // },
                errorWidget: (context, string, obj) {
                  return Image.asset('assets/images/no_avatar.jpeg');
                },
                imageUrl: urlPath + _profile['uavator'],
              ),
            ),
          )
          // CircleAvatar(
          //   // 背景透明
          //   backgroundColor: Colors.transparent,
          //   // 半径
          //   radius: 72.0,
          //   // backgroundImage: NetworkImage(urlPath + _profile['avator']),
          // ),
          ),
    );
  }

  Widget signOutSection() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text.rich(
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
            _profile != null ? avatarSection() : Container(),
            widget.personal ? signOutSection() : Container(),
            loremSection(),
          ],
        ),
      ),
    );
  }
}
