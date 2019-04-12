import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/config.dart';
import '../models/user.dart';
import './chat_group.dart';
import './call.dart';

Dio dio = new Dio();
// dio.options.baseUrl = 'localhost:3000/api';
var urlPath = DefaultConfig.urlPath;
var baseUrl = DefaultConfig.baseUrl;
var socketPath = DefaultConfig.socketPath;

class ChatContactPage extends StatefulWidget {
  @override
  ChatContactPageState createState() => ChatContactPageState();
}

class ChatContactPageState extends State<ChatContactPage> {
  List<User> users = [];
  int uid;
  List _searchUsers = [];

  _initUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getInt('uid');
    Response response = await dio
        .get('$baseUrl/room/getUserFriends', queryParameters: {'uid': uid});
    if (response.data['code'] == 0) {
      List<User> temps = <User>[];
      List friends = response.data['friends'];
      for (var friend in friends) {
        temps.add(User.fromJson(friend));
      }
      setState(() {
        users.addAll(temps);
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initUsers();
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
              showSearch(context: context, delegate: SearchBarDelegate());
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
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (BuildContext context, int index) {
                  User user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      // backgroundImage: NetworkImage(urlPath + comment['uavator']),
                      backgroundImage: new CachedNetworkImageProvider(
                          urlPath + user.uavator),
                    ),
                    title: Text(user.uremark != null && user.uremark.isNotEmpty
                        ? user.uremark
                        : user.uname),
                    subtitle: Text(user.ubio),
                    onTap: () async {
                      // insertChat  uid, fuid
                      Response response = await dio.post(
                        '$baseUrl/room/insertChat',
                        data: {'uid': uid, 'fuid': user.uid},
                      );
                      if (response.data['code'] == 0) {
                        var chatRoom = response.data['chat'];
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            return RoomDetailPage(chatRoom['id'],
                                room: chatRoom, chatObj: user);
                          },
                        ));
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBarDelegate extends SearchDelegate<String> {
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

class RoomDetailPage extends StatefulWidget {
  final int roomid;
  final room;
  final User chatObj;
  RoomDetailPage(this.roomid, {this.room, this.chatObj});
  @override
  State<StatefulWidget> createState() => RoomDetailPageState();
}

class RoomDetailPageState extends State<RoomDetailPage> {
  Widget _buildUser() {
    User user = widget.chatObj;
    return Row(
      children: <Widget>[
        ClipOval(
          child: SizedBox(
            width: 40.0,
            height: 40.0,
            // child: Image.network(urlPath + _profile['avator'],
            //     fit: BoxFit.cover),
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              placeholder: (context, string) {
                return Image.asset('assets/images/no_avatar.jpeg');
              },
              errorWidget: (context, string, obj) {
                return Image.asset('assets/images/no_avatar.jpeg');
              },
              imageUrl:
                  urlPath + (user.uavator == null ? 'null' : user.uavator),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user.uname != null ? user.uname : '',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                user.ubio,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Column(
          children: <Widget>[
            _buildUser(),
            RaisedButton(
              child: Text('设置备注'),
              onPressed: () {},
            ),
            RaisedButton(
              child: Text('发消息'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ChatGroupPage(widget.roomid,
                      chatid: widget.room['chatid'],
                      private: widget.room['isChat'],
                      roomName: widget.room['name'],
                      roomUsers: widget.room['room_users']);
                }));
              },
            ),
            RaisedButton(
              child: Text('视频聊天'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return CallPage(
                    channelName: widget.roomid.toString(),
                  );
                }));
              },
            )
          ],
        ),
      ),
    );
  }
}
