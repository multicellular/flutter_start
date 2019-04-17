import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/event_bus.dart';
import '../home_page/home.dart';
import '../component/dioHttp.dart';

import './login.dart';

class RegisterPage extends StatefulWidget {
  @override
  RegisterPageState createState() => new RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  File _imageFile;

  _signUp() async {
    FormData formData = new FormData.from(
        {'file': new UploadFileInfo(_imageFile, _imageFile.path)});
    var res = await dioHttp.httpPost('/uploadFile', req: formData);
    String avatorUrl = res['urls'];
    var userRes = await dioHttp.httpPost('/user/signup', req: {
      'name': _unameController.text,
      'password': _pwdController.text,
      'avator': avatorUrl
    });
    if (userRes != null) {
      var user = userRes['user'];
      String token = userRes['token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uid', user['id']);
      await prefs.setString('token', 'Bearer $token');
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
                        width: 150,
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
