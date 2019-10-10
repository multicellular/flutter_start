import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:barcode_scan/barcode_scan.dart';

import '../component/event_bus.dart';
import '../component/kf_drawer.dart';
import '../models/config.dart';
import '../login_page/login.dart';
import '../login_page/profile.dart';
import 'game.dart';
import 'demo001.dart';

String urlPath = DefaultConfig.urlPath;
String socketPath = DefaultConfig.socketPath;

class HomePage extends KFDrawerContent {
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  var _profile;
  String barcode;

  @override
  void initState() {
    super.initState();
    _initEvent();
    // _initUpdate();
  }

  _initEvent() {
    evtBus.off('profile_update');
    evtBus.on('profile_update', (args) {
      setState(() {
        _profile = args;
      });
    });
  }

  _initUpdate() async {
    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    String _localPath = directory.path + '/download';
    FlutterDownloader.registerCallback((id, status, progress) {
      print(
          'Download task ($id) is in status ($status) and process ($progress)');
      if (status == DownloadTaskStatus.complete) {
        // OpenFile.open(_localPath);
        FlutterDownloader.open(taskId: id);
      }
    });
    // final taskId =
    await FlutterDownloader.enqueue(
      url:
          'http://www.lovepean.xyz:3000/files/upload_896d5a9eba19e5049455367c251e9f0b.jpg',
      savedDir: _localPath,
      showNotification:
          true, // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
    );
    // final tasks =
    await FlutterDownloader.loadTasks();
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() {
        return this.barcode = barcode;
      });
    } catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          return this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() {
          return this.barcode = 'Unknown error: $e';
        });
      }
    } on FormatException {
      setState(() => this.barcode =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }

  // Widget _buildMessage() {
  //   Widget widget = Container();
  //   if (_messages.length > 0) {
  //     String content = _messages.last['content'];
  //     widget = Container(
  //       color: Colors.white30,
  //       margin: EdgeInsets.only(top: 20),
  //       child: new ListTile(title: new Text('$content')),
  //     );
  //   }
  //   return new Builder(builder: (BuildContext context) {
  //     return widget;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return Scaffold(
      floatingActionButton: _profile != null
          ? FloatingActionButton(
              heroTag: _profile['id'],
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ProfilePage.withProfile(
                      {'uid': _profile['id'], 'uavator': _profile['avator']},
                      personal: true);
                }));
              },
              child: ClipOval(
                child: SizedBox(
                  width: 60.0,
                  height: 60.0,
                  // child: Image.network(urlPath + _profile['avator'],
                  //     fit: BoxFit.cover),
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    // placeholder: (context, string) {
                    //   return Image.asset('assets/images/no_avatar.jpeg');
                    // },
                    errorWidget: (context, string, obj) {
                      return Image.asset('assets/images/no_avatar.jpeg');
                    },
                    imageUrl: urlPath + _profile['avator'],
                  ),
                ),
              ),
            )
          : FloatingActionButton.extended(
              icon: Icon(Icons.insert_emoticon),
              label: Text('sigin in'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  // return LoginPage();
                  return LoginPage();
                }));
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        // shape: CircularNotchedRectangle(),
        color: const Color(0xFFf16d7e),
        child: Row(
          children: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Colors.white70,
                  size: 40,
                ),
                onPressed: widget.onMenuPressed),
            IconButton(
              icon: Icon(
                Icons.games,
                color: Colors.white70,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return GamePage();
                }));
              },
            ),
            PopupMenuButton(
              // overflow menu
              offset: Offset(0, -180),
              color: Color(0xFFb853c0),
              icon: Icon(
                Icons.more,
                color: Colors.white70,
              ),
              onSelected: (val) {
                switch (val) {
                  case 'demo001':
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return RunBall();
                    }));
                    break;
                  case 'file_download':
                    _initUpdate();
                    break;
                  case 'scan':
                    scan();
                    break;
                  default:
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'demo001',
                    child: Text('demo001',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  PopupMenuItem<String>(
                    value: 'file_download',
                    child: Text('file_download',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  PopupMenuItem<String>(
                    value: 'scan',
                    child:
                        Text('scan', style: TextStyle(color: Colors.white54)),
                  ),
                ];
              },
            ),
            // IconButton(
            //   icon: Icon(
            //     Icons.file_download,
            //     color: Colors.white70,
            //   ),
            //   onPressed: () {
            //     _initUpdate();
            //   },
            // ),
            // IconButton(
            //   icon: Icon(
            //     Icons.scanner,
            //     color: Colors.white70,
            //   ),
            //   onPressed: () {
            //     scan();
            //   },
            // ),
            SizedBox(),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceAround,
        ),
      ),
      body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF9b5ae1),
                const Color(0xFFb853c0),
                const Color(0xFFf16d7e)
              ],
            ),
            borderRadius: BorderRadius.circular(3.0), //3像素圆角
            boxShadow: [
              //阴影
              BoxShadow(
                  color: Colors.black54,
                  offset: Offset(2.0, 2.0),
                  blurRadius: 4.0)
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              // _buildMessage(),
              Container(
                margin: EdgeInsets.only(top: 120, bottom: 40),
                child: Text(
                  'With the time going,we always need to do something',
                  style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      textBaseline: TextBaseline.alphabetic),
                ),
              ),
              // Image.asset('assets/images/launch.jpeg')
              Text(barcode ?? '')
            ],
          )),
    );
  }
}
