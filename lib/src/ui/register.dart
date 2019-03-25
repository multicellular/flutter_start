import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import './blog/blog.dart';
import './login.dart';
// import 'dart:async';

import './models/config.dart';
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
  Future<File> _imageFile;
  File avator;
  // void _selectedImage() {
  //   setState(() {
  //     _imageFile = ImagePicker.pickImage(source: ImageSource.gallery);
  //   });
  // }

  _signUp() async {
    FormData formData =
        new FormData.from({'file': new UploadFileInfo(avator, 'avator.png')});
    Response uplaodFile =
        await dio.post('$baseUrl/uploadFile', data: formData);
    String avatorUrl = uplaodFile.data['urls'];
    Response response =
        await dio.post('$baseUrl/user/signup', data: {
      'name': _unameController.text,
      'password': _pwdController.text,
      'avator': avatorUrl
    });
    // Map<String, dynamic> res = response.data;
    if (response.data['code'] == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return BlogPage();
      }));
    }
  }

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
                    child: FutureBuilder(
                      future: _imageFile,
                      builder:
                          (BuildContext context, AsyncSnapshot<File> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != null) {
                          avator = snapshot.data;
                          return ClipOval(
                            child: SizedBox(
                                width: 70.0,
                                height: 70.0,
                                child: Image.file(snapshot.data,
                                    fit: BoxFit.cover)),
                          );
                        } else {
                          return IconButton(
                            icon: Icon(Icons.add_photo_alternate),
                            tooltip: '请选择上传头像',
                            iconSize: 80.0,
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
                                          onTap: () {
                                            _imageFile = ImagePicker.pickImage(
                                                source: ImageSource.camera);
                                            Navigator.pop(context);
                                          },
                                        ),
                                        new ListTile(
                                          leading:
                                              new Icon(Icons.photo_library),
                                          title: new Text("Gallery"),
                                          onTap: () {
                                            _imageFile = ImagePicker.pickImage(
                                                source: ImageSource.gallery);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    );
                                  });
                            },
                          );
                        }
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
