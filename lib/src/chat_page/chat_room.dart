import 'package:cached_network_image/cached_network_image.dart';
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

class ChatRoomPage extends StatefulWidget {
  @override
  ChatRoomPageState createState() => ChatRoomPageState();
}

class searchBarDelegate extends SearchDelegate<String> {
  List _searchUsers = [];

  TextEditingController _applyController = new TextEditingController();

  _sendApply(user, BuildContext context) async {
    // verify_message: this.verify_message,
    // apply_uid: this.userId,
    // apply_flist_id: this.friendRoom.id,
    // invitees_uid: this.applyUser.uid,
    // invitees_flist_id: this.applyUser.flist_id
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = await prefs.getInt('uid');
    Response response = await dio.post('$baseUrl/room/createApply', data: {
      'verify_message': _applyController.text,
      'apply_uid': uid,
      'invitees_uid': user['uid'],
      'invitees_flist_id': user['flist_id']
    });
    if (response.data['code'] == 0) {
      Navigator.pop(context);
    } else {
      print(response.data);
    }
  }

  @override
  void showResults(BuildContext context) async {
    // TODO: implement showResults
    Response response = await dio.get('$baseUrl/room/searchUsersByName',
        queryParameters: {'uname': query});
    if (response.data['code'] == 0) {
      _searchUsers = response.data['users'];
    }
    super.showResults(context);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
          icon: AnimatedIcons.menu_arrow, progress: transitionAnimation),
      onPressed: () {
        if (query.isEmpty) {
          close(context, null);
        } else {
          query = "";
          showSuggestions(context);
        }
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(),
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: _searchUsers.length,
            itemBuilder: (context, index) {
              var user = _searchUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  // backgroundImage: NetworkImage(urlPath + comment['uavator']),
                  backgroundImage: NetworkImage(urlPath + user['uavator']),
                ),
                title: Text(
                    user['uremark'] != null ? user['uremark'] : user['uname']),
                subtitle: Text(user['ubio'] != null ? user['ubio'] : ''),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          title: Text('好友申请'),
                          children: <Widget>[
                            Container(
                              child: TextFormField(
                                controller: _applyController,
                                decoration: InputDecoration(
                                  hintText: '请输入验证消息',
                                ),
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.check),
                                  onPressed: () {
                                    _sendApply(user, context);
                                  },
                                ),
                              ],
                            )
                          ],
                        );
                      });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Text('请输入名称');
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    // TODO: implement appBarTheme
    return super.appBarTheme(context);
  }
}

class Room {
  final String uremark;
  final String uavator;
  final String uname;
  final String ubio;
  final int uid;
  Room({this.uavator, this.uremark, this.ubio, this.uname, this.uid});

  Room.fromJson(Map<String, dynamic> json)
      : uid = json['uid'],
        uname = json['uname'],
        uavator = json['uavator'] != null ? json['uavator'] : '',
        uremark = json['uremark'] != null ? json['uremark'] : '',
        ubio = json['ubio'] != null ? json['ubio'] : '';
}

class ChatRoomPageState extends State<ChatRoomPage> {
  List<Room> rooms = [];
  int uid;
  List _searchUsers = [];

  _initRooms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = await prefs.getInt('uid');
    Response response = await dio
        .get('$baseUrl/room/getUserFriends', queryParameters: {'uid': uid});
    if (response.data['code'] == 0) {
      List<Room> temps = <Room>[];
      List friends = response.data['friends'];
      for (var friend in friends) {
        temps.add(Room.fromJson(friend));
      }
      setState(() {
        rooms.addAll(temps);
      });
    }
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

  _sendMessage() {}

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () {
              showSearch(context: context, delegate: searchBarDelegate());
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: ListView.separated(
                itemCount: rooms.length,
                itemBuilder: (BuildContext context, int index) {
                  Room room = rooms[index];
                  return ListTile(
                    leading: CircleAvatar(
                      // backgroundImage: NetworkImage(urlPath + comment['uavator']),
                      backgroundImage: new CachedNetworkImageProvider(
                          urlPath + room.uavator),
                    ),
                    title: Text(room.uremark != null && room.uremark.isNotEmpty
                        ? room.uremark
                        : room.uname),
                    subtitle: Text(room.ubio),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ChatGroupPage(room.uid, chatName: room.uname);
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
