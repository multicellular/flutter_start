import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncher extends StatefulWidget {
  @override
  UrlLauncherState createState() => UrlLauncherState();
}

class UrlLauncherState extends State<UrlLauncher> {
  _goLauncher(String uri) async {
    if (await canLaunch(uri)) {
      await launch(uri);
    } else {
      throw 'Could not launch $uri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Launcher',
          ),
        ),
        body: Center(
            child: Column(
          children: <Widget>[
            RaisedButton.icon(
              label: Text('微信'),
              icon: Icon(
                Icons.touch_app,
              ),
              onPressed: () {
                _goLauncher('weixin://dl/chat');
              },
            ),
            RaisedButton.icon(
              label: Text('百度'),
              icon: Icon(
                Icons.touch_app,
              ),
              onPressed: () {
                _goLauncher('https://www.baidu.com/');
              },
            ),
            RaisedButton.icon(
              label: Text('电话'),
              icon: Icon(
                Icons.touch_app,
              ),
              onPressed: () {
                _goLauncher('tel:+86 13813808326');
              },
            ),
          ],
        )));
  }
}
