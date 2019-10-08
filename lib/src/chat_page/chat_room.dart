import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/config.dart';
import './chat_group.dart';
import '../component/dioHttp.dart';
import '../component/db_bus.dart';

var urlPath = DefaultConfig.urlPath;
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
  final dynamic message;
  Room(
      {this.id,
      this.name,
      this.avators,
      this.caption,
      this.ownerid,
      this.moment,
      this.isChat,
      this.chatid,
      this.message,
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
        message = json['message'],
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
    List res = await Future.wait([
      dioHttp.httpGet('/room/getUserRooms', needToken: true),
      dioHttp.httpGet('/room/getUserChats', needToken: true),
    ]);
    List<Room> _temps = <Room>[];
    List tempRooms = res[0]!=null ? res[0]['rooms'] : [];
    List tempChats = res[1]!=null ? res[1]['chats'] : [];
    tempChats.addAll(tempRooms);
    for (var room in tempChats) {
      var message = await _initRoomMessages(room);
      room['message'] = message;
      _temps.add(Room.fromJson(room));
    }
    setState(() {
      _rooms.addAll(_temps);
    });
  }

  _initRoomMessages(room) async {
    List results = await dbBus.queryMessage(
        columns: ['msg'],
        where: '"groupid"=?',
        whereArgs: [room['id']],
        orderBy: 'localid desc',
        limit: 1);
    if (results.isNotEmpty) {
      return json.decode(results[0]['msg']);
    } else {
      return {'content': '', 'moment': ''};
    }
  }

  @override
  void initState() {
    super.initState();
    _initRooms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    subtitle: Text(room.message['content']),
                    trailing: Text(
                      room.message['moment'].toString().isNotEmpty
                          ? DateTime.fromMillisecondsSinceEpoch(
                              int.parse(room.message['moment']),
                              // isUtc: true,
                            ).toString().substring(0, 16)
                          : '',
                    ),
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
