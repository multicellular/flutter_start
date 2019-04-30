import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../models/config.dart';
import '../models/user.dart';
import '../component/event_bus.dart';
import '../component/db_bus.dart';
import '../chat_page/call.dart';
import '../component/dioHttp.dart';
import '../component/photo_view.dart';

String socketPath = DefaultConfig.socketPath;
String urlPath = DefaultConfig.urlPath;

class Message {
  final int id;
  final String type;
  final String content;
  final String moment;
  final int roomid;
  final int sendid;
  final int toid;
  final bool private;
  Message(
      {@required this.type,
      @required this.content,
      this.sendid,
      this.id,
      this.moment,
      this.roomid,
      this.private,
      this.toid});

  @override
  String toString() {
    // JSON.stringify
    return '{ "id": $id ,"type": "$type", "content": "$content", "moment": "$moment", "roomid": $roomid, "sendid": $sendid, "toid": $toid, "private": $private }';
  }

  static Message toJson(String msg) {
    dynamic jsonMsg = json.decode(msg);
    return Message.fromJson(jsonMsg);
  }

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type = json['type'],
        content = json['content'],
        roomid = json['roomid'],
        sendid = json['sendid'],
        toid = json['toid'],
        private = json['private'],
        moment = json['moment'];
}

class ChatGroupPage extends StatefulWidget {
  final int roomid;
  final String roomName;
  final int chatid;
  final bool private;
  final List roomUsers;
  ChatGroupPage(this.roomid,
      {this.roomName, this.chatid, this.private, this.roomUsers});
  @override
  ChatGroupPageState createState() => ChatGroupPageState();
}

class ChatGroupPageState extends State<ChatGroupPage>
    with TickerProviderStateMixin {
  List<ChatMessage> _messages = [];
  TextEditingController _messageController = new TextEditingController();
  IOWebSocketChannel _channel;
  int uid;
  bool _isLoadingMore = false;

  File _imageFile;

  ScrollController _controller = new ScrollController();
  int _lastID;

  _initChannel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getInt('uid');
    if (uid != null) {
      String route = widget.private
          ? '/chat/${widget.roomid}/$uid'
          : '/room/${widget.roomid}/$uid';
      _channel = IOWebSocketChannel.connect(socketPath + route);
      // _message = Message(type: 'join', content: '', sendid: uid);
      // _channel.sink.add(_message.toString());
      _channel.sink.add('join');
      _channel.stream.listen((message) {
        var msgJson = json.decode(message);
        Message msg = Message.fromJson(msgJson);
        ChatMessage chatMessage = new ChatMessage(
          message: msg,
          user: User().filterUser(msg.sendid, widget.roomUsers),
          uid: uid,
          animationController: new AnimationController(
              duration: new Duration(milliseconds: 700), vsync: this),
        );
        setState(() {
          _messages.insert(0, chatMessage);
        });
        chatMessage.animationController.forward();
        dbBus.insertMessage(message, isRead: true);
      });
    }
  }

  _initRoomMessages() async {
    List results = await dbBus.queryMessage(
        columns: ['localid', 'msg'],
        where: '"groupid"=?',
        whereArgs: [widget.roomid],
        orderBy: 'localid desc',
        limit: 12);
    if (results.isNotEmpty) _lastID = results.last['localid'];

    for (var result in results) {
      Message msg = Message.fromJson(json.decode(result['msg']));
      ChatMessage chatMessage = new ChatMessage(
        message: msg,
        uid: uid,
        user: User().filterUser(msg.sendid, widget.roomUsers),
        animationController: new AnimationController(
            duration: new Duration(milliseconds: 100), vsync: this),
      );
      setState(() {
        _messages.add(chatMessage);
      });
      chatMessage.animationController.forward();
    }
  }

  Future _getMoreMessages() async {
    setState(() {
      _isLoadingMore = true;
    });
    List results = await dbBus.queryMessage(
        columns: ['localid', 'msg'],
        where: '"groupid"=? and "localid"<?',
        whereArgs: [widget.roomid, _lastID],
        orderBy: 'localid desc',
        limit: 12);
    if (results.isNotEmpty) {
      _lastID = results.last['localid'];
    }
    for (var result in results) {
      Message msg = Message.fromJson(json.decode(result['msg']));
      ChatMessage chatMessage = new ChatMessage(
        message: msg,
        uid: uid,
        user: User().filterUser(msg.sendid, widget.roomUsers),
        animationController: new AnimationController(
            duration: new Duration(milliseconds: 100), vsync: this),
      );
      setState(() {
        _messages.add(chatMessage);
      });
      chatMessage.animationController.forward();
    }
    setState(() {
      _isLoadingMore = false;
    });
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initChannel();
    _initRoomMessages();
    _controller.addListener(() {
      var maxScroll = _controller.position.maxScrollExtent;
      var pixel = _controller.position.pixels;
      // 顶端下拉刷新数据
      if (maxScroll == pixel && !_isLoadingMore) {
        _getMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    // _message = Message(type: 'leave', content: '', sendid: uid);
    // _channel.sink.add(_message.toString());
    _channel.sink.close(status.goingAway);
    for (ChatMessage message in _messages)
      message.animationController.dispose();
    _controller.dispose();
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

  _addMessage() {
    if (_messageController.text.isNotEmpty) {
      _sendMessage('text', _messageController.text);
      _messageController.text = '';
    }
  }

  _sendMessage(type, content) {
    Message message = Message(
      type: type,
      content: content,
      sendid: uid,
      roomid: widget.roomid,
      private: widget.private,
      toid: widget.chatid,
    );
    _channel.sink.add(message.toString());
  }

  _addImage() async {
    FormData formData = new FormData.from(
        {'file': new UploadFileInfo(_imageFile, _imageFile.path)});
    var fileRes = await dioHttp.httpPost('/uploadFile', req: formData);
    String imageUrl = fileRes['urls'];
    _sendMessage('image', imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.roomName),
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            // image: Image.asset('assets/images/login_bg.jpg',fit: BoxFit.fill),
            // image: DecorationImage(
            //   image: AssetImage('assets/images/chat_bg.jpeg'),
            //   fit: BoxFit.fill,
            // ),
            borderRadius: BorderRadius.circular(3.0), //3像素圆角
          ),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                _isLoadingMore
                    ? SpinKitCircle(
                        color: Colors.blue,
                        size: 50.0,
                      )
                    : Container(),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      controller: _controller,
                      itemBuilder: (BuildContext context, int index) =>
                          _messages[index]),
                ),
                // Expanded(
                //   flex: 1,
                //   child: StreamBuilder(
                //     stream: _channel.stream,
                //     builder: (BuildContext context, snapshot) {
                //       return Text(snapshot.hasData ? '${snapshot.data}' : '');
                //     },
                //   ),
                // ),
                Row(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.call),
                      onPressed: () {
                        evtBus.emit('message', {
                          'type': 'call',
                          'sendid': uid,
                          'roomid': widget.roomid,
                          'toid': widget.chatid
                        });
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return CallPage(
                            channelName: widget.roomid.toString(),
                          );
                        }));
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.image),
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
                                    _imageFile =
                                        await _compressAndGetFile(image);
                                    Navigator.pop(context);
                                    _addImage();
                                  },
                                ),
                                new ListTile(
                                  leading: new Icon(Icons.photo_library),
                                  title: new Text("Gallery"),
                                  onTap: () async {
                                    File image = await ImagePicker.pickImage(
                                        source: ImageSource.gallery);
                                    _imageFile =
                                        await _compressAndGetFile(image);
                                    Navigator.pop(context);
                                    _addImage();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    Expanded(
                      flex: 1,
                      child: Form(
                        child: TextFormField(
                          controller: _messageController,
                          // autofocus: true,
                          // keyboardType: TextInputType.multiline,
                          // maxLines: 4,
                          // maxLength: 1000,
                          // maxLengthEnforced: true,
                          textInputAction: TextInputAction.send,
                          onFieldSubmitted: (String value) {
                            _addMessage();
                          },
                          decoration:
                              new InputDecoration(hintText: 'Send a message'),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _addMessage();
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ));
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage(
      {this.message, this.animationController, @required this.user, this.uid});
  final Message message;
  final User user;
  final uid;
  final AnimationController animationController;

  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
          parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: new Container(
        // color: Colors.red,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection:
              user.uid == uid ? TextDirection.rtl : TextDirection.ltr,
          children: <Widget>[
            new Container(
              // color: Colors.white,
              padding: const EdgeInsets.only(right: 8.0, left: 8.0),
              child: new CircleAvatar(
                  backgroundImage: new NetworkImage(urlPath + user.uavator)),
            ),
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection:
                    user.uid == uid ? TextDirection.rtl : TextDirection.ltr,
                children: <Widget>[
                  // new Text(user.uname,
                  //     style: Theme.of(context).textTheme.subhead),
                  new Container(
                    margin: EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.lightGreenAccent,
                      // image: Image.asset('assets/images/login_bg.jpg',fit: BoxFit.fill),
                      image: DecorationImage(
                        image: AssetImage(user.uid == uid
                            ? 'assets/images/text_bg_rtl.jpeg'
                            : 'assets/images/text_bg_ltr.jpeg'),
                        fit: BoxFit.fill,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: message.type == 'image'
                        ? GestureDetector(
                            child: Image.network(urlPath + message.content),
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  // transitionDuration:
                                  //     Duration(milliseconds: 500),
                                  pageBuilder: (BuildContext context,
                                      Animation animation,
                                      Animation secondaryAnimation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: PhotoViewPage(
                                          [urlPath + message.content]),
                                    );
                                  },
                                ),
                              );
                              // Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //       builder: (context) {
                              //         return PhotoViewPage(
                              //             [urlPath + message.content]);
                              //       },
                              //       fullscreenDialog: true,
                              //     ));
                            },
                          )
                        : new Text(message.content),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
