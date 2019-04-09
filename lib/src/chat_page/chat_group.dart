import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/config.dart';
import '../models/user.dart';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

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
        ChatMessage chatMessage = new ChatMessage(
          message: Message.fromJson(json.decode(message)),
          user: User().filterUser(uid, widget.roomUsers),
          animationController: new AnimationController(
              duration: new Duration(milliseconds: 700), vsync: this),
        );
        setState(() {
          _messages.insert(0, chatMessage);
        });
        chatMessage.animationController.forward();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initChannel();
  }

  @override
  void dispose() {
    super.dispose();
    // _message = Message(type: 'leave', content: '', sendid: uid);
    // _channel.sink.add(_message.toString());
    _channel.sink.close(status.goingAway);
    for (ChatMessage message in _messages)
      message.animationController.dispose();
  }

  _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      Message message = Message(
        type: 'text',
        content: _messageController.text,
        sendid: uid,
        roomid: widget.roomid,
        private: widget.private,
        toid: widget.chatid,
      );
      _channel.sink.add(message.toString());
      _messageController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) =>
                    _messages[index],
              ),
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
                  icon: Icon(Icons.file_upload),
                  onPressed: () {},
                ),
                Expanded(
                  flex: 1,
                  child: Form(
                    child: TextFormField(
                      controller: _messageController,
                      decoration:
                          new InputDecoration(hintText: 'Send a message'),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage();
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({this.message, this.animationController, @required this.user});
  final Message message;
  final User user;
  final AnimationController animationController;

  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
          parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          // textDirection: TextDirection.rtl,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: new CircleAvatar(
                  backgroundImage: new NetworkImage(urlPath + user.uavator)),
            ),
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(user.uname,
                      style: Theme.of(context).textTheme.subhead),
                  new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: message.type == 'image'
                        ? Image.network(message.content)
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
