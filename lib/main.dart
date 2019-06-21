import 'package:flutter/material.dart';
// import './src/home_page/home.dart';
import './src/home_page/app.dart';

void main() => runApp(Main());

class Main extends StatefulWidget {
  // This widget is the root of your application.
  @override
  MainState createState() => new MainState();
}

class MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    // return MaterialApp(home: HomePage());
    return MaterialApp(home: AppWidget());
  }
}
