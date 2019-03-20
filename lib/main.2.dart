import 'package:flutter/material.dart';
import './src/ui/login.dart';
import './src/ui/models/choice.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  MyAppState createState() => new MyAppState();
}

class MyAppState extends State<MyApp> {
  Choice _selectedChoice = choices[0];
  void _select(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text('My AppBar'),
            actions: <Widget>[
              IconButton(
                  icon: Icon(choices[0].icon),
                  onPressed: () {
                    _select(choices[0]);
                  }),
              PopupMenuButton<Choice>(
                // overflow menu
                onSelected: _select,
                itemBuilder: (BuildContext context) {
                  return choices.skip(2).map((Choice choice) {
                    return PopupMenuItem<Choice>(
                      value: choice,
                      child: Text(choice.title),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          drawer: Drawer(),
          bottomNavigationBar: BottomAppBar(
              shape: CircularNotchedRectangle(),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(choices[0].icon),
                    onPressed: () {},
                  ),
                  SizedBox(),
                  IconButton(
                    icon: Icon(choices[1].icon),
                    onPressed: () {},
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.spaceAround,
              )),
          floatingActionButton: FloatingActionButton(
            child: Icon(choices[0].icon),
            onPressed: () {
              _select(choices[0]);
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: ChoiceCard(choice: _selectedChoice),
          )),
    );
  }
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Car', icon: Icons.directions_car),
  const Choice(title: 'Bicycle', icon: Icons.directions_bike),
  const Choice(title: 'Boat', icon: Icons.directions_boat),
  const Choice(title: 'Bus', icon: Icons.directions_bus),
  const Choice(title: 'Train', icon: Icons.directions_railway),
  const Choice(title: 'Walk', icon: Icons.directions_walk),
];

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({Key key, this.choice}) : super(key: key);

  final Choice choice;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return new Card(
      color: Colors.white,
      child: new Center(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(choice.icon),
              onPressed: () {
                // print('ChoiceCard onPressed');
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  // return NewRoute(choice);
                  return LoginPage();
                }));
              },
            ),
            Icon(choice.icon, size: 128.0, color: textStyle.color),
            Text(choice.title, style: textStyle),
          ],
        ),
      ),
    );
  }
}
