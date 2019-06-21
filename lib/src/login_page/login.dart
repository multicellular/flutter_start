import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../component/dioHttp.dart';
import '../component/event_bus.dart';
import '../home_page/app.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();

  _signIn() async {
    dioHttp.httpPost('/user/signin', req: {
      'name': _unameController.text,
      'password': _pwdController.text
    }).then((res) async {
      if (res != null) {
        var user = res['user'];
        String token = res['token'];
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
    });
    // Map<String, dynamic> res = response.data;
  }

  Widget _buildPageContent(BuildContext context) {
    return Container(
      color: Colors.blue.shade100,
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 30.0,
          ),
          // CircleAvatar(child: Image.asset('assets/images/no_avatar.jpeg'), maxRadius: 50, backgroundColor: Colors.transparent,),
          SizedBox(
            height: 20.0,
          ),
          _buildLoginForm(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => SignupPage()));
                },
                child: Text("Sign Up",
                    style: TextStyle(color: Colors.blue, fontSize: 18.0)),
              )
            ],
          ),
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
                    height: 90.0,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.only(right: 20.0),
                          child: Text(
                            "Forgot Password",
                            style: TextStyle(color: Colors.black45),
                          ))
                    ],
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
              CircleAvatar(
                radius: 40.0,
                backgroundColor: Colors.blue.shade600,
                child: Icon(Icons.child_care),
              ),
            ],
          ),
          Container(
            height: 420,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RaisedButton(
                onPressed: () {
                  _signIn();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0)),
                child: Text("Login", style: TextStyle(color: Colors.white70)),
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
