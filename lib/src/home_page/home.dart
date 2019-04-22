import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

import '../component/event_bus.dart';
import '../models/config.dart';
import '../component/dioHttp.dart';

import '../login_page/login.dart';
import '../login_page/profile.dart';
import '../blog_page/blog_book.dart';
import '../chat_page/chat_book.dart';
import '../chat_page/call.dart';

String urlPath = DefaultConfig.urlPath;
String socketPath = DefaultConfig.socketPath;

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  var _profile;
  IOWebSocketChannel _channel;
  List _messages = [];
  Database _db;
  var flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initEvent();
    _initDatabase();
    _initProfile();
    _initNotifications();
    _initApply();
  }

  _initDatabase() async {
    var databasePath = await getDatabasesPath();
    String path = Path.join(databasePath, 'message.db');
    // deleteDatabase(path);
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
            create table local_messages(
              localid integer primary key autoincrement,
              msg text not null,
              read integer not null default 0,
              groupid integer,
              private integer
            )
          ''');
    });
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
  }
  Future _onSelectNotification(String payload) {
    int localeID = int.parse(payload);
    _cancelNotification(localeID);
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ChatBookPage();
    }));
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
  Future _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  _initProfile() async {
    var userRes = await dioHttp.httpGet('/user/info', needToken: true);
    if (userRes != null) {
      var user = userRes['user'];
      int connectid = user['id'];
      _channel = IOWebSocketChannel.connect(socketPath + '/connect/$connectid');
      _channel.sink.add('connect');
      _channel.stream.listen((message) {
        var msgJson = json.decode(message);
        if (msgJson['type'] == 'apply') {
          // 好友申请监听
          _initApply();
        } else if (msgJson['type'] == 'call') {
          _audioPlayer.play('assets/call.mp3', isLocal: true);
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
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
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
        } else {
          // app聊天消息处理
          setState(() {
            _messages.add(msgJson);
          });
          _handleMessage(message);
        }
      });
      setState(() {
        _profile = user;
      });
    }
    // }
  }

  _handleMessage(message) async {
    var msgJson = json.decode(message);
    int localeID = await _db.insert('local_messages', {
      'msg': message,
      'groupid': msgJson['roomid'],
      'private': msgJson['private'] ? 1 : 0
    });
    _showNotification(localeID, '', msgJson['content'], localeID.toString());
  }

  @override
  void dispose() {
    super.dispose();
    _channel.sink.close(status.goingAway);
    _db.close();
  }

  _initEvent() {
    evtBus.off('sigin_out');
    evtBus.on('sigin_out', (args) {
      // _channel.sink.add('disconnect');
      _channel.sink.close(status.goingAway);
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
                          Text(apply['verify_message'] != null
                              ? apply['verify_message']
                              : ''),
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

  Widget _buildMessage() {
    Widget widget = Container();
    if (_messages.length > 0) {
      String content = _messages.last['content'];
      widget = Container(
        color: Colors.white30,
        margin: EdgeInsets.only(top: 20),
        child: new ListTile(title: new Text('$content')),
      );
      // String content = _messages.last['content'];
      // widget = Container(
      //   height: 20,
      //   color: Colors.white,
      //   margin: EdgeInsets.only(top: 10, left: 10),
      //   child: Text(content),
      // );
    }
    return new Builder(builder: (BuildContext context) {
      return widget;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return Scaffold(
      floatingActionButton: _profile != null
          ? GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ProfilePage.withProfile(
                      {'uid': _profile['id'], 'uavator': _profile['avator']},
                      personal: true);
                }));
              },
              child: Hero(
                tag: _profile['id'],
                child: ClipOval(
                  child: SizedBox(
                    width: 60.0,
                    height: 60.0,
                    // child: Image.network(urlPath + _profile['avator'],
                    //     fit: BoxFit.cover),
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      placeholder: (context, string) {
                        return Image.asset('assets/images/no_avatar.jpeg');
                      },
                      // errorWidget: (context, string, obj) {
                      //   return Image.asset('assets/images/no_avatar.jpeg');
                      // },
                      imageUrl: urlPath + _profile['avator'],
                    ),
                  ),
                ),
              ),
            )
          : FloatingActionButton.extended(
              icon: Icon(Icons.insert_emoticon),
              label: Text('sigin in'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }));
              },
            ),
      body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF9b5ae1),
                const Color(0xFFb853c0),
                const Color(0xFFf16d7e)
              ],
            ),
            borderRadius: BorderRadius.circular(3.0), //3像素圆角
            boxShadow: [
              //阴影
              BoxShadow(
                  color: Colors.black54,
                  offset: Offset(2.0, 2.0),
                  blurRadius: 4.0)
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              _buildMessage(),
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Text(
                  'Flutter allows you to build beautiful native apps on iOS and Android from a single codebase.',
                  style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      textBaseline: TextBaseline.alphabetic),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Text(
                  '    Paint your app to life in milliseconds with stateful Hot Reload. Use a rich set of fully-customizable widgets to build native interfaces in minutes.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Text(
                  '    Quickly ship features with a focus on native end-user experiences. Layered architecture allows for full customization, which results in incredibly fast rendering and expressive and flexible designs.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20, bottom: 30),
                child: Text(
                  '    Flutter’s widgets incorporate all critical platform differences such as scrolling, navigation, icons and fonts to provide full native performance on both iOS and Android.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Text(
                    'GO TO PAGE: ',
                    style: TextStyle(color: Colors.black45, fontSize: 18),
                  ),
                  IconButton(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    icon: Icon(
                      Icons.mode_edit,
                      size: 50,
                      color: Colors.lightBlue,
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return BlogPage();
                      }));
                    },
                  ),
                  IconButton(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    icon: Icon(
                      Icons.mode_comment,
                      size: 50,
                      color: Colors.lightBlue,
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return _profile != null ? ChatBookPage() : LoginPage();
                      }));
                    },
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
