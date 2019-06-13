import 'package:flutter/material.dart';
import 'package:hello_flutter/src/blog_page/blog_book.dart';
import 'package:hello_flutter/src/chat_page/chat_book.dart';
import 'package:hello_flutter/src/home_page/home.dart';
import '../component/kf_drawer.dart';
import '../login_page/login.dart';

class MainWidget extends StatefulWidget {
  @override
  _MainWidgetState createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  KFDrawerController _drawerController;

  @override
  void initState() {
    super.initState();
    _drawerController = KFDrawerController(
      // initialPage: ClassBuilder.fromString('MainPage'),
      initialPage: HomePage(),
      items: [
        KFDrawerItem.initWithPage(
          text: Text('MAIN', style: TextStyle(color: Colors.white)),
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