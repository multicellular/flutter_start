import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import './component/photo_view.dart';
import './component/video_player.dart';

// Options options = new BaseOptions(baseUrl: 'localhost:3000/api');
// Dio dio = new Dio(options);
Dio dio = new Dio();
// dio.options.baseUrl = 'localhost:3000/api';

class BlogPage extends StatefulWidget {
  @override
  BlogPageState createState() => new BlogPageState();
}

class BlogPageState extends State<BlogPage> {
  List blogs = [];
  Response response;
  var urlPath = 'http://localhost:3000/';

  _initData() async {
    response = await dio.get('http://localhost:3000/api/blog/getblogs');
    setState(() {
      blogs = response.data['blogs'];
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    _initData();
  }

  _showPostBlogDialog() {}

  _previewImage(String imageUrls) {
    List images = [];
    if (imageUrls.isNotEmpty) {
      images = imageUrls.split(',');
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return PhotoViewPage(images);
    }));
  }

  _previewVideo(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      // return PhotoViewPage(images);
      return VideoApp(url);
    }));
  }

  List<Widget> _initImages(String imagesStr) {
    List images = [];
    if (imagesStr.isNotEmpty) {
      images = imagesStr.split(',');
    }
    List<Widget> widgets = <Widget>[];
    var len = images.length;
    double width;
    if (len == 1) {
      width = 336;
    } else if (len == 2) {
      width = 168;
    } else {
      width = 120;
    }
    for (var image in images) {
      Widget widget = Image.network(
        urlPath + image,
        height: 120,
        width: width,
        fit: BoxFit.contain,
      );
      widgets.add(widget);
    }
    return widgets;
  }

  Widget initMediaWidget(String mediaType, String mediaUrls) {
    return GestureDetector(
      onTap: () {
        mediaType == 'image'
            ? _previewImage(mediaUrls)
            : _previewVideo(mediaUrls);
      },
      child: Container(
        margin: EdgeInsets.all(10),
        child: mediaType == 'image'
            ? Wrap(
                spacing: 5, //主轴上子控件的间距
                runSpacing: 5, //交叉轴上子控件之间的间距
                children: _initImages(mediaUrls),
              )
            : Image.asset('assets/images/video_default.jpg'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blog'),
      ),
      drawer: Drawer(),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              iconSize: 50,
              onPressed: () {},
            ),
            SizedBox(),
            IconButton(
              icon: Icon(Icons.group),
              iconSize: 50,
              onPressed: () {},
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceAround,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_circle_outline),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                // return PhotoViewPage(images);
                return PostBlogDialog();
              },
              fullscreenDialog: true,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Container(
        child: ListView.builder(
          itemCount: blogs.length,
          // itemExtent: 200,
          itemBuilder: (BuildContext context, int index) {
            var blog = blogs[index];
            return Container(
              margin: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundImage:
                            NetworkImage(urlPath + blog['uavator']),
                        // child: Text(blog['uname']),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              blog['uname'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              blog['moment'],
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    child: Text(
                      blog['content'],
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  initMediaWidget(blog['media_type'], blog['media_urls']),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Icon(Icons.redo),
                            Text('0'),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.comment),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      // return PhotoViewPage(images);
                                      return BlogDetail();
                                    },
                                  ),
                                );
                              },
                            ),
                            Text('0'),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Icon(Icons.thumb_up),
                            Text('0'),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class PostBlogDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('post blog'),
        actions: <Widget>[
          Container(
            child: Text('send'),
          )
        ],
      ),
      body: Text('Dialog'),
    );
  }
}

class BlogDetail extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new BlogDetailState();
}

class BlogDetailState extends State<BlogDetail> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('blog detail'),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.redo),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.comment),
              onPressed: () {
                showModalBottomSheet(
                  builder: (BuildContext context) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      height: 100,
                      child: Text('build bottom sheet'),
                    );
                  },
                  context: context,
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.thumb_up),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              child: Text('blog content'),
            ),
            Container(
              child: Text('blog media'),
            ),
            Container(
              child: Text('blog comment'),
            )
          ],
        ),
      ),
    );
  }
}
