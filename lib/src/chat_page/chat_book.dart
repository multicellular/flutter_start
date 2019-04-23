import 'package:flutter/material.dart';
import './chat_contact.dart';
import './chat_room.dart';

class ChatBookPage extends StatefulWidget {
  @override
  ChatBookPageState createState() => ChatBookPageState();
}

class ChatBookPageState extends State<ChatBookPage> {
  int _selectIndex = 0;
  final _widgetOptions = [ChatRoomPage(), ChatContactPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectIndex,
          fixedColor: Colors.deepPurple,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.message), title: Text('消息')),
            BottomNavigationBarItem(
                icon: Icon(Icons.contacts), title: Text('好友'))
          ],
          onTap: (index) {
            setState(() {
              _selectIndex = index;
            });
          },
        ),
        body: Center(
          child: _widgetOptions.elementAt(_selectIndex),
        ));
  }
}