import 'package:flutter/material.dart';
// import './src/home_page/home.dart';
import './src/home_page/home2.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  MyAppState createState() => new MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // return MaterialApp(home: HomePage());
    return MaterialApp(home: MainWidget());
  }
}
