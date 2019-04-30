import 'package:flutter/material.dart';
import '../component/dioHttp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/event_bus.dart';
import '../home_page/home.dart';

import './register.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => new LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  // GlobalKey _fromKey = new GlobalKey();

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
            context.toString().indexOf('RegisterPage') > -1) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return HomePage();
          }));
        } else {
          Navigator.pop(context);
        }
      }
    });
    // Map<String, dynamic> res = response.data;
  }

  @override
  Widget build(BuildContext context) {
    // final TextStyle textStyle = Theme.of(context).textTheme.display1;

    return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            // image: Image.asset('assets/images/login_bg.jpg',fit: BoxFit.fill),
            // image: DecorationImage(
            //   image: AssetImage('assets/images/login_bg.jpg'),
            //   fit: BoxFit.fill,
            // ),
            borderRadius: BorderRadius.circular(3.0), //3像素圆角
            boxShadow: [
              //阴影
              BoxShadow(
                  color: Colors.black54,
                  offset: Offset(2.0, 2.0),
                  blurRadius: 4.0)
            ],
          ),
          child: Container(
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
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
                    obscureText: true,
                    decoration: InputDecoration(
                        hintText: '请输入密码',
                        labelText: '密码',
                        icon: Icon(Icons.lock)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 150,
                          child: RaisedButton(
                            color: Colors.blue,
                            highlightColor: Colors.blue[700],
                            colorBrightness: Brightness.dark,
                            // splashColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0)),
                            child: Text('登录'),
                            onPressed: () {
                              _signIn();
                            },
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          child: RaisedButton(
                            child: Text('注册'),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0)),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return RegisterPage();
                              }));
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}

class InputWidget extends StatelessWidget {
  final double topRight;
  final double bottomRight;

  InputWidget(this.topRight, this.bottomRight);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 40, bottom: 30),
      child: Container(
        width: MediaQuery.of(context).size.width - 40,
        child: Material(
          elevation: 10,
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(bottomRight),
                  topRight: Radius.circular(topRight))),
          child: Padding(
            padding: EdgeInsets.only(left: 40, right: 20, top: 10, bottom: 10),
            child: TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "JohnDoe@example.com",
                  hintStyle: TextStyle(color: Color(0xFFE1E1E1), fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }
}
