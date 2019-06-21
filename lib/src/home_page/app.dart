import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audio_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

import '../component/event_bus.dart';
import '../component/db_bus.dart';
import '../component/dioHttp.dart';
import '../component/kf_drawer.dart';

import '../chat_page/chat_book.dart';
import '../chat_page/call.dart';
import '../blog_page/blog_book.dart';
import '../home_page/home.dart';
import '../login_page/login.dart';

class AppWidget extends StatefulWidget {
  //TODO 所有路由皆以appWidget为root，路由表
  @override
  AppWidgetState createState() => AppWidgetState();
}

class AppWidgetState extends State<AppWidget> {
  KFDrawerController _drawerController;
  var _profile;
  IOWebSocketChannel _channel;
  List _messages = [];
  var flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _drawerController = KFDrawerController(
      // initialPage: ClassBuilder.fromString('MainPage'),
      initialPage: HomePage(),
      items: [
        KFDrawerItem.initWithPage(
          text: Text('HOME', style: TextStyle(color: Colors.white)),
          icon: Icon(Icons.home, color: Colors.white),
          page: HomePage(),
        ),
        KFDrawerItem.initWithPage(
          text: Text(
            'BLOG',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(Icons.mode_edit, color: Colors.white),
          page: BlogPage(),
        ),
        KFDrawerItem.initWithPage(
          text: Text(
            'CHAT',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(Icons.mode_comment, color: Colors.white),
          // page: ClassBuilder.fromString('SettingsPage'),
          page: ChatBookPage(),
        ),
      ],
    );
    _initEvent();
    _initProfile();
    _initNotifications();
    _initApply();
    // _initUpdate();
  }

  _initNotifications() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: _onDidRecieveLocalNotification);
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);
  }

  Future _onDidRecieveLocalNotification(
      int id, String title, String body, String payload) {
    // onDidRecieveLocalNotification 这个是IOS端接收到通知所作的处理的方法
    return null;
  }

  Future _onSelectNotification(String payload) {
    int localeID = int.parse(payload);
    _cancelNotification(localeID);
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ChatBookPage();
    }));
    return null;
  }

  Future _showNotification(
      int localeID, String title, String conetnt, String payload) async {
    //安卓的通知配置，必填参数是渠道id, 名称, 和描述, 可选填通知的图标，重要度等等。
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'id', 'name', 'description',
        importance: Importance.Max, priority: Priority.High);
    //IOS的通知配置
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    //显示通知，其中 0 代表通知的 id，用于区分通知。
    await flutterLocalNotificationsPlugin.show(
        localeID, title, conetnt, platformChannelSpecifics,
        payload: payload);
  }

  //删除单个通知
  Future _cancelNotification(id) async {
    //参数 0 为需要删除的通知的id
    await flutterLocalNotificationsPlugin.cancel(id);
  }

//删除所有通知
  // Future _cancelAllNotifications() async {
  //   await flutterLocalNotificationsPlugin.cancelAll();
  // }

  _initProfile() async {
    var userRes =
        await dioHttp.httpGet('/user/info', needToken: true, showTip: false);
    if (userRes != null) {
      var user = userRes['user'];
      int connectid = user['id'];
      _channel = IOWebSocketChannel.connect(socketPath + '/connect/$connectid');
      _channel.sink.add('connect');
      _channel.stream.listen((message) async {
        var msgJson = json.decode(message);
        if (msgJson['type'] == 'apply') {
          // 好友申请监听
          _initApply();
        } else if (msgJson['type'] == 'call') {
          _showCallDialog(msgJson);
          // 本地notification通知
          _showNotification(1000, '', 'calling', '1000');
        } else {
          // app聊天消息处理
          setState(() {
            _messages.add(msgJson);
          });
          _handleMessage(message);
        }
      });
      evtBus.emit('profile_update', user);
      setState(() {
        _profile = user;
      });
    }
    // }
  }

  _handleMessage(message) async {
    var msgJson = json.decode(message);
    int localeID = await dbBus.insertMessage(message);
    _showNotification(localeID, '', msgJson['content'], localeID.toString());
  }

  _showCallDialog(msgJson) async {
    AudioPlayer _audioPlayer = await AudioCache().play('call.mp3');
    // 视频通话监听
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text('视频聊天'),
            children: <Widget>[
              Text(msgJson['sendid'].toString()),
              RaisedButton(
                onPressed: () {
                  _audioPlayer.stop();
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CallPage(
                      channelName: msgJson['roomid'].toString(),
                    );
                  }));
                },
                child: Text('接受'),
              ),
              RaisedButton(
                onPressed: () {
                  _audioPlayer.stop();
                  Navigator.pop(context);
                },
                child: Text('取消'),
              ),
            ],
          );
        });
  }

  @override
  void dispose() {
    super.dispose();
    dbBus.dispose();
    _channel.sink.close(status.goingAway);
  }

  _initEvent() {
    evtBus.off('sigin_out');
    evtBus.on('sigin_out', (args) {
      dbBus.dispose();
      _channel.sink.close(status.goingAway);
      evtBus.off('message');
      evtBus.emit('profile_update');
      setState(() {
        _profile = null;
      });
    });
    evtBus.off('message');
    evtBus.on('message', (message) {
      // _channel.sink.add('disconnect');
      String msg = json.encode(message);
      _channel.sink.add(msg);
    });
    // evtBus.off('sigin_in');
    // evtBus.on('sigin_in', (args) {
    //   _initProfile();
    // });
  }

  _initApply() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = prefs.getInt('uid');
    if (uid == null) {
      return;
    }
    var applyRes =
        await dioHttp.httpGet('/room/findApply', req: {'invitees_uid': uid});

    if (applyRes != null && applyRes['applys'].length > 0) {
      var _applys = applyRes['applys'];
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('好友申请'),
              children: <Widget>[
                Container(
                  width: 200,
                  height: 300,
                  child: ListView.separated(
                    itemCount: _applys.length,
                    itemBuilder: (BuildContext context, int index) {
                      var apply = _applys[index];
                      return Row(
                        children: <Widget>[
                          Text(apply['verify_message'] ?? ''),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () async {
                              var result = await dioHttp.httpPost(
                                  '/room/ignoreApply',
                                  req: {'applyid': apply['id']});
                              if (result != null) {
                                _applys.removeAt(index);
                                if (_applys.length == 0) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () async {
                              var result = await dioHttp.httpPost(
                                '/room/allowJoinFriend',
                                req: {
                                  'apply_uid': apply['apply_uid'],
                                  'apply_flist_id': apply['apply_flist_id'],
                                  'invitees_uid': apply['invitees_uid'],
                                  'invitees_flist_id':
                                      apply['invitees_flist_id'],
                                  'applyId': apply['id']
                                },
                              );
                              if (result != null) {
                                _applys.removeAt(index);
                                if (_applys.length == 0) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          )
                        ],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {},
                  ),
                ),
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KFDrawer(
        controller: _drawerController,
        header: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            width: MediaQuery.of(context).size.width * 0.6,
            child: Image.asset(
              'assets/images/chat_bg.jpeg',
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        footer: KFDrawerItem(
          text: Text(
            'SIGN IN',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(
            Icons.input,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return LoginPage();
            }));
          },
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(255, 255, 255, 1.0),
              Color.fromRGBO(44, 72, 171, 1.0)
            ],
            tileMode: TileMode.repeated,
          ),
        ),
      ),
    );
  }
}

// typedef T Constructor<T>();

// final Map<String, Constructor<Object>> _constructors =
//     <String, Constructor<Object>>{};

// void register<T>(Constructor<T> constructor) {
//   _constructors[T.toString()] = constructor;
// }

// class ClassBuilder {

//   static void registerClasses() {
//     register<MainPage>(() => MainPage());
//     register<CalendarPage>(() => CalendarPage());
//     register<SettingsPage>(() => SettingsPage());
//   }

//   static dynamic fromString(String type) {
//     return _constructors[type]();
//   }
//
