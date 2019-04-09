import 'dart:async';

// import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/config.dart';
import './chat_group.dart';

Dio dio = new Dio();
// dio.options.baseUrl = 'localhost:3000/api';
var urlPath = DefaultConfig.urlPath;
var baseUrl = DefaultConfig.baseUrl;
var socketPath = DefaultConfig.socketPath;

class Room {
  final int id;
  final String name;
  final dynamic avators;
  final String caption;
  final String ownerid;
  final String moment;
  final bool isChat;
  final dynamic roomUsers;
  final int chatid;
  Room(
      {this.id,
      this.name,
      this.avators,
      this.caption,
      this.ownerid,
      this.moment,
      this.isChat,
      this.chatid,
      this.roomUsers});

  Room.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        avators = json['avators'],
        caption = json['caption'],
        ownerid = json['ownerid'],
        moment = json['moment'],
        isChat = json['isChat'],
        chatid = json['chatid'],
        roomUsers = json['room_users'];
}

class ChatRoomPage extends StatefulWidget {
  @override
  ChatRoomPageState createState() => ChatRoomPageState();
}

class ChatRoomPageState extends State<ChatRoomPage> {
  List<Room> _rooms = [];
  int uid;

  _initRooms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getInt('uid');
    List<Response> response = await Future.wait([
      dio.get('$baseUrl/room/getUserRooms', queryParameters: {'uid': uid}),
      dio.get('$baseUrl/room/getUserChats', queryParameters: {'uid': uid})
    ]);
    List<Room> _temps = <Room>[];
    List tempRooms = response[0].data['rooms'];
    List tempChats = response[1].data['chats'];
    tempChats.addAll(tempRooms);
    for (var room in tempChats) {
      _temps.add(Room.fromJson(room));
    }
    setState(() {
      _rooms.addAll(_temps);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initRooms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: ListView.separated(
                itemCount: _rooms.length,
                itemBuilder: (BuildContext context, int index) {
                  Room room = _rooms[index];
                  return ListTile(
                    leading: Image.network(
                      urlPath + room.avators[0],
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(room.name),
                    subtitle: Text('lastMessage.content'),
                    trailing: Text('lastMessage.time'),
                    onTap: () async {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ChatGroupPage(
                          room.id,
                          chatid: room.chatid,
                          private: room.isChat,
                          roomName: room.name,
                          roomUsers: room.roomUsers,
                        );
                      }));
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  //下划线widget预定义以供复用。
                  Widget divider1 = Divider(
                    color: Colors.blue,
                  );
                  Widget divider2 = Divider(color: Colors.green);
                  return index % 2 == 0 ? divider1 : divider2;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
