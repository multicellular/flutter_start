import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../component/event_bus.dart';
import '../component/dioHttp.dart';
import '../home_page/app.dart';

class SignupPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SignupPageState();
}

class SignupPageState extends State {
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  File _imageFile;

  _signUp() async {
    
    String avatorUrl = '';
    if (_imageFile != null) {
      FormData formData = new FormData.from(
          {'file': new UploadFileInfo(_imageFile, _imageFile.path)});
      var res = await dioHttp.httpPost('/uploadFile', req: formData);
      avatorUrl = res != null ? res['urls'] : '';
    }
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
          context.toString().indexOf('SignupPage') > -1) {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return AppWidget();
        }));
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<File> _compressAndGetFile(File file) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      file.absolute.path,
      minWidth: 100,
      minHeight: 100,
      quality: 100,
      // rotate: 90,
    );
    // print(file.lengthSync());
    // print(result.length);
    return result;
  }

  Widget _buildPageContent(BuildContext context) {
    return Container(
      color: Colors.blue.shade100,
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 30.0,
          ),
          // CircleAvatar(child: Image.asset('assets/img/origami.png'), maxRadius: 50, backgroundColor: Colors.transparent,),
          SizedBox(
            height: 20.0,
          ),
          _buildLoginForm(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  Navigator.pop(context);
                },
                backgroundColor: Colors.blue,
                child: Icon(Icons.arrow_back),
              )
            ],
          )
        ],
      ),
    );
  }

  Container _buildLoginForm() {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Stack(
        children: <Widget>[
          ClipPath(
            // clipper: RoundedDiagonalPathClipper(),
            child: Container(
              height: 400,
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(40.0)),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 60.0,
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: _unameController,
                        style: TextStyle(color: Colors.blue),
                        decoration: InputDecoration(
                            hintText: "Email address",
                            hintStyle: TextStyle(color: Colors.blue.shade200),
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.email,
                              color: Colors.blue,
                            )),
                      )),
                  Container(
                    child: Divider(
                      color: Colors.blue.shade400,
                    ),
                    padding:
                        EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: _pwdController,
                        style: TextStyle(color: Colors.blue),
                        decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.blue.shade200),
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.lock,
                              color: Colors.blue,
                            )),
                      )),
                  Container(
                    child: Divider(
                      color: Colors.blue.shade400,
                    ),
                    padding:
                        EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        style: TextStyle(color: Colors.blue),
                        decoration: InputDecoration(
                            hintText: "Confirm password",
                            hintStyle: TextStyle(color: Colors.blue.shade200),
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.lock,
                              color: Colors.blue,
                            )),
                      )),
                  Container(
                    child: Divider(
                      color: Colors.blue.shade400,
                    ),
                    padding:
                        EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SizedBox(height: 100),
              _imageFile != null
                  ? ClipOval(
                      child: SizedBox(
                        width: 70.0,
                        height: 70.0,
                        child: Image.file(_imageFile, fit: BoxFit.cover),
                      ),
                    )
                  : CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.blue.shade600,
                      child: Icon(Icons.person),
                    ),
              IconButton(
                icon: Icon(
                  Icons.camera_alt,
                  color: Colors.blue.shade600,
                ),
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
                              File image = await ImagePicker.pickImage(
                                  source: ImageSource.camera);
                              _imageFile = await _compressAndGetFile(image);
                              Navigator.pop(context);
                            },
                          ),
                          new ListTile(
                            leading: new Icon(Icons.photo_library),
                            title: new Text("Gallery"),
                            onTap: () async {
                              File image = await ImagePicker.pickImage(
                                  source: ImageSource.gallery);
                              _imageFile = await _compressAndGetFile(image);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          Container(
            height: 420,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RaisedButton(
                onPressed: () {
                  _signUp();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0)),
                child: Text("Sign Up", style: TextStyle(color: Colors.white70)),
                color: Colors.blue,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPageContent(context),
    );
  }
}
