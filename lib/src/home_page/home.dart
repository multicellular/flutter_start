import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chat_page/chat_room.dart';
import '../login_page/login.dart';
import '../component/event_bus.dart';
import '../models/config.dart';
import '../login_page/profile.dart';
import '../blog_page/blog_book.dart';

// Options options = new BaseOptions(baseUrl: 'localhost:3000/api');
// Dio dio = new Dio(options);
Dio dio = new Dio();
// dio.options.baseUrl = 'localhost:3000/api';
String baseUrl = DefaultConfig.baseUrl;
String urlPath = DefaultConfig.urlPath;

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  var _profile;
  // var _applys = [];
  // GlobalKey _fromKey = new GlobalKey();

  @override
  void initState() {
    super.initState();
    _initEvent();
    _initProfile();
    _initNotification();
  }

  _initProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = await prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      Options options =
          Options(headers: {HttpHeaders.authorizationHeader: token});
      Response response = await dio.get('$baseUrl/user/info', options: options);
      if (response.data['code'] == 0) {
        setState(() {
          _profile = response.data['user'];
        });
      }
    }
  }

  _initEvent() {
    evtBus.on('sigin_out', (args) {
      setState(() {
        _profile = null;
      });
    });
    evtBus.on('sigin_in', (args) {
      _initProfile();
    });
  }

  _initNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = await prefs.getInt('uid');
    Response response = await dio
        .get('$baseUrl/room/findApply', queryParameters: {'invitees_uid': uid});
    if (response.data['code'] == 0 && response.data['applys'].length > 0) {
      var _applys = response.data['applys'];
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
                              Response result = await dio.post(
                                '$baseUrl/room/ignoreApply',
                                data: {'applyid': apply['id']},
                              );
                              if (result.data['code'] == 0) {
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
                              Response result = await dio.post(
                                '$baseUrl/room/allowJoinFriend',
                                data: {
                                  'apply_uid': apply['apply_uid'],
                                  'apply_flist_id': apply['apply_flist_id'],
                                  'invitees_uid': apply['invitees_uid'],
                                  'invitees_flist_id':
                                      apply['invitees_flist_id'],
                                  'applyId': apply['id']
                                },
                              );
                              if (result.data['code'] == 0) {
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
    // final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return Scaffold(
      //   bottomSheet: Container(
      //       decoration: BoxDecoration(color: Colors.red[50]),
      //       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      //       child: ListView.separated(
      //         itemCount: _applys.length,
      //         itemBuilder: (BuildContext context, int index) {
      //           var apply = _applys[index];
      //           return Row(
      //             children: <Widget>[
      //               Text(apply['verify_message'] != null
      //                   ? apply['verify_message']
      //                   : ''),
      //               IconButton(
      //                 icon: Icon(Icons.close),
      //                 onPressed: () async {
      //                   Response result = await dio.post(
      //                     '$baseUrl/room/ignoreApply',
      //                     data: {'applyid': apply['id']},
      //                   );
      //                   if (result.data['code'] == 0) {
      //                     _applys.removeAt(index);
      //                     if (_applys.length == 0) {
      //                       Navigator.pop(context);
      //                     }
      //                   }
      //                 },
      //               ),
      //               IconButton(
      //                 icon: Icon(Icons.check),
      //                 onPressed: () async {
      //                   Response result = await dio.post(
      //                     '$baseUrl/room/allowJoinFriend',
      //                     data: {
      //                       'apply_uid': apply['apply_uid'],
      //                       'apply_flist_id': apply['apply_flist_id'],
      //                       'invitees_uid': apply['invitees_uid'],
      //                       'invitees_flist_id': apply['invitees_flist_id'],
      //                       'applyId': apply['id']
      //                     },
      //                   );
      //                   if (result.data['code'] == 0) {
      //                     _applys.removeAt(index);
      //                     if (_applys.length == 0) {
      //                       Navigator.pop(context);
      //                     }
      //                   }
      //                 },
      //               )
      //             ],
      //           );
      //         },
      //         separatorBuilder: (BuildContext context, int index) {},
      //       )),
      floatingActionButton: _profile != null
          // ? ClipOval(
          //     child: SizedBox(
          //       width: 60.0,
          //       height: 60.0,
          //       child: Image.network(urlPath + _profile['avator'],
          //           fit: BoxFit.cover),
          //     ),
          //   )
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
            // image: Image.asset('assets/images/login_bg.jpg',fit: BoxFit.fill),
            // image: DecorationImage(
            //   image: AssetImage('assets/images/home_bg.jpg'),
            //   fit: BoxFit.cover,
            // ),
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
              Container(
                margin: EdgeInsets.only(top: 60),
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
                  // Card(
                  // child: GestureDetector(
                  //   onTap: () {
                  //     Navigator.push(context,
                  //         MaterialPageRoute(builder: (context) {
                  //       return BlogPage();
                  //     }));
                  //   },
                  //   child: Image.asset(
                  //     'assets/images/blog_icon.png',
                  //     width: 60,
                  //     height: 60,
                  //   ),
                  // ),
                  // ),
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
                        return ChatRoomPage();
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