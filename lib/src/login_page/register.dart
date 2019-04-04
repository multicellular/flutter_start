import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/event_bus.dart';
import '../home_page/home.dart';

// import '../blog_page/blog_book.dart';
import './login.dart';
// import 'dart:async';

import '../models/config.dart';

// Options options = new BaseOptions(baseUrl: 'localhost:3000/api');
// Dio dio = new Dio(options);
Dio dio = new Dio();
// dio.options.baseUrl = 'localhost:3000/api';
String baseUrl = DefaultConfig.baseUrl;

class RegisterPage extends StatefulWidget {
  @override
  RegisterPageState createState() => new RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  // GlobalKey _fromKey = new GlobalKey();
  // Future<File> _imageFile;
  File _imageFile;
  // File avator;
  // void _selectedImage() {
  //   setState(() {
  //     _imageFile = ImagePicker.pickImage(source: ImageSource.gallery);
  //   });
  // }

  _signUp() async {
    FormData formData = new FormData.from(
        {'file': new UploadFileInfo(_imageFile, _imageFile.path)});
    Response uplaodFile = await dio.post('$baseUrl/uploadFile', data: formData);
    String avatorUrl = uplaodFile.data['urls'];
    Response response = await dio.post('$baseUrl/user/signup', data: {
      'name': _unameController.text,
      'password': _pwdController.text,
      'avator': avatorUrl
    });
    // Map<String, dynamic> res = response.data;
    if (response.data['code'] == 0) {
      // Navigator.push(context, MaterialPageRoute(builder: (context) {
      //   return BlogPage();
      // }));
      var user = response.data['user'];
      String token = response.data['token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uid', user['id']);
      await prefs.setString('token', 'Bearer ${token}');
      evtBus.emit('sigin_in');
      if (context.toString().indexOf('LoginPage') > -1 ||
          context.toString().indexOf('RegisterPage') > -1) {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return HomePage();
        }));
      } else {
        Navigator.pop(context);
      }
    }
  }

  // Future<List<int>> _compressFile(File file) async {
  //   var result = await FlutterImageCompress.compressWithFile(
  //     file.absolute.path,
  //     // minWidth: 2300,
  //     // minHeight: 1500,
  //     quality: 94,
  //     rotate: 90,
  //   );
  //   print(file.lengthSync());
  //   print(result.length);
  //   return result;
  // }

  Future<File> _compressAndGetFile(File file) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      file.absolute.path,
      minWidth: 100,
      minHeight: 100,
      quality: 100,
      rotate: 90,
    );
    // print(file.lengthSync());
    // print(result.length);
    return result;
  }

  // Future<Widget> _buildImage() async {
  //   List<int> list = await _compressFile(_imageFile);
  //   ImageProvider provider = MemoryImage(Uint8List.fromList(list));
  //   return Image(
  //     image: provider ?? AssetImage("assets/images/video_default.jpg"),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return Scaffold(
      appBar: AppBar(
        title: Text("Register"),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 50, left: 20, right: 20),
        child: Form(
          // key: _fromKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                autofocus: true,
                controller: _unameController,
                decoration: InputDecoration(
                    hintText: '用户名或邮箱',
                    labelText: '用户名',
                    icon: Icon(Icons.person)),
              ),
              TextFormField(
                controller: _pwdController,
                // obscureText: true,
                decoration: InputDecoration(
                    hintText: '请输入密码', labelText: '密码', icon: Icon(Icons.lock)),
              ),
              Row(
                children: <Widget>[
                  Icon(Icons.face),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: _imageFile != null
                        ? ClipOval(
                            child: SizedBox(
                              width: 70.0,
                              height: 70.0,
                              child: Image.file(_imageFile, fit: BoxFit.cover),
                            ),
                          )
                        : IconButton(
                            icon: Icon(Icons.add_photo_alternate),
                            tooltip: '请选择上传头像',
                            iconSize: 40.0,
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return new Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      new ListTile(
                                        leading: new Icon(Icons.photo_camera),
                                        title: new Text("Camera"),
                                        onTap: () async {
                                          File image =
                                              await ImagePicker.pickImage(
                                                  source: ImageSource.camera);
                                          _imageFile =
                                              await _compressAndGetFile(image);
                                          Navigator.pop(context);
                                        },
                                      ),
                                      new ListTile(
                                        leading: new Icon(Icons.photo_library),
                                        title: new Text("Gallery"),
                                        onTap: () async {
                                          File image =
                                              await ImagePicker.pickImage(
                                                  source: ImageSource.gallery);
                                          _imageFile =
                                              await _compressAndGetFile(image);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
              Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 200,
                        margin: EdgeInsets.only(right: 40),
                        child: RaisedButton(
                          color: Colors.blue,
                          splashColor: Colors.grey,
                          highlightColor: Colors.blue[700],
                          colorBrightness: Brightness.dark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          child: Text('注册'),
                          onPressed: () {
                            _signUp();
                          },
                        ),
                      ),
                      RaisedButton(
                        child: Text('登录'),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0)),
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return LoginPage();
                          }));
                        },
                      ),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
