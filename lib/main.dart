import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
import './src/home_page/home.dart';

// BaseOptions options = new BaseOptions(
//   baseUrl: "http//localhost:3000/api",
//   connectTimeout: 5000,
//   receiveTimeout: 3000,
// );
// Dio dio = new Dio(options);

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  MyAppState createState() => new MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}
