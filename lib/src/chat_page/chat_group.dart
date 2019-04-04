import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/config.dart';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

var socketPath = DefaultConfig.socketPath;

class Message {
  final int id;
  final String type;
  final String content;
  final String moment;
  final int chatid;
  final int sendid;
  Message(
      {@required this.type,
      @required this.content,
      @required this.sendid,
      this.id,
      this.moment,
      this.chatid});

  @override
  String toString() {
    // JSON.stringify
    return '{ "id": $id ,"type": "$type", "content": "$content", "moment": "$moment", "chatid": $chatid, "sendid": $sendid }';
  }

  static Message toJson(String msg) {
    dynamic jsonMsg = json.decode(msg);
    return Message.fromJson(jsonMsg);
  }

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type = json['type'],
        content = json['content'],
        chatid = json['chatid'],
        sendid = json['sendid'],
        moment = json['moment'];
}

class ChatGroupPage extends StatefulWidget {
  final int chatid;
  final String chatName;
  ChatGroupPage(this.chatid, {this.chatName});
  @override
  ChatGroupPageState createState() => ChatGroupPageState();
}

class ChatGroupPageState extends State<ChatGroupPage> {
  List<Message> _messages = [];
  TextEditingController _messageController = new TextEditingController();
  IOWebSocketChannel _channel;
  int uid;
  Message message;
  _initChannel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = await prefs.getInt('uid');
    if (uid != null) {
      message = Message(type: 'server', content: 'connect', sendid: uid);
      _channel = IOWebSocketChannel.connect(socketPath);
      _channel.sink.add(message.toString());
      _channel.stream.listen((message) {
        setState(() {
          _messages.add(Message.toJson(message));
        });
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initChannel();
  }

  @override
  void dispose() {
    super.dispose();
    _channel.sink.close(status.goingAway);
  }

  _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      Message message = Message(
        type: 'text',
        content: _messageController.text,
        sendid: uid,
        chatid: widget.chatid,
      );
      _channel.sink.add(message.toString());
      _messageController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  Message _message = _messages[index];
                  return Row(
                    mainAxisAlignment: _message.sendid == uid ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: <Widget>[
                      Text(_message.content)
                    ],
                  );
                },
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
