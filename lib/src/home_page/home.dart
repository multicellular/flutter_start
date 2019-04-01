import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page/login.dart';
// import '../login_page/register.dart';
import '../component/event_bus.dart';
import '../models/config.dart';
import '../login_page/setting.dart';
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
  // GlobalKey _fromKey = new GlobalKey();

  @override
  void initState() {
    super.initState();
    _initEvent();
    _initProfile();
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

  @override
  Widget build(BuildContext context) {
    // final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return Scaffold(
      // bottomSheet: Container(
      //   decoration: BoxDecoration(color: Colors.red[50]),
      //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      //   child: Row(
      //     children: <Widget>[
      //       buildUser(),
      //       _profile != null ? Text(_profile['name']) : Container()
      //     ],
      //   ),
      // ),
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
                  return SettingPage(_profile);
                }));
              },
              child: Hero(
                tag: _profile['id'],
                child: ClipOval(
                  child: SizedBox(
                    width: 60.0,
                    height: 60.0,
                    child: Image.network(urlPath + _profile['avator'],
                        fit: BoxFit.cover),
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
                    'BLOG PAGE: ',
                    style: TextStyle(color: Colors.black45, fontSize: 18),
                  ),
                  Card(
                    child: IconButton(
                      icon: Icon(Icons.pages),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return BlogPage();
                        }));
                      },
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
