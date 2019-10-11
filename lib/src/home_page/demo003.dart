import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncher extends StatefulWidget {
  @override
  UrlLauncherState createState() => UrlLauncherState();
}

class UrlLauncherState extends State<UrlLauncher> {
  String tip='';
  _goLauncher(String uri) async {
    tip=uri;
    if (await canLaunch(uri)) {
      // tip=uri;
      await launch(uri);
    } else {
      // tip='error';
      await launch(uri);
      throw 'Could not launch $uri';
    }
    setState(() {
      
    });
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
                _goLauncher('weixin://');
                // _goLauncher('vnd.youtube://');
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
                _goLauncher('tel:13813808326');
              },
            ),
            Text(tip)
          ],
        )));
  }
}
