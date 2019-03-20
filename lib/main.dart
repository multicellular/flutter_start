import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import './src/ui/login.dart';
// import './src/ui/models/choice.dart';

BaseOptions options = new BaseOptions(
  baseUrl: "http//localhost:3000/api",
  connectTimeout: 5000,
  receiveTimeout: 3000,
);
Dio dio = new Dio(options);
void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  MyAppState createState() => new MyAppState();
}

class MyAppState extends State<MyApp> {
  // _getInfo() async {
  //   Response response = await dio.get("/test?id=12&name=wendu");

  // }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LoginPage());
  }
}
