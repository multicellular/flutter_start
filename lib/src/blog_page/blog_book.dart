import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import './blog_detail.dart';
import './blog_send.dart';
import './blog_widgets.dart';
import '../models/config.dart';
import '../home_page/home.dart';
import '../chat_page/chat_room.dart';

// BaseOptions options = new BaseOptions(baseUrl: 'localhost:3000/api');
// Dio dio = new Dio(options);
Dio dio = new Dio();
// dio.options.baseUrl = 'localhost:3000/api';
var urlPath = DefaultConfig.urlPath;
var baseUrl = DefaultConfig.baseUrl;

class BlogPage extends StatefulWidget {
  @override
  BlogPageState createState() => new BlogPageState();
}

class BlogPageState extends State<BlogPage> {
  List blogs = [];
  Response response;
  ScrollController _controller = new ScrollController();
  bool isRefreshing = false;
  CircularProgressIndicator progressIndicator = CircularProgressIndicator();

  _initData() async {
    setState(() {
      isRefreshing = true;
    });
    response = await dio.get('$baseUrl/blog/getblogs');
    setState(() {
      blogs = response.data['blogs'];
      isRefreshing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initData();
    _controller.addListener(() {
      // 顶端下拉刷新数据
      if (_controller.offset <= 0 && !isRefreshing) {
        _initData();
      }
    });
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用_controller.dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Blog'),
          actions: <Widget>[
            PopupMenuButton<String>(
              // overflow menu
              onSelected: (value) {
                if (value == 'is_private') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      // return PhotoViewPage(images);
                      return MyBlogPage();
                    }),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'is_private',
                    child: Text('my blogs'),
                  )
                ];
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
                icon: Icon(Icons.home),
                iconSize: 50,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return HomePage();
                  }));
                },
              ),
              SizedBox(),
              IconButton(
                icon: Icon(Icons.group),
                iconSize: 50,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ChatRoomPage();
                  }));
                },
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceAround,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add_circle_outline),
          onPressed: () async {
            var newBlog = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  // return PhotoViewPage(images);
                  return PostBlogDialog();
                },
                fullscreenDialog: true,
              ),
            );
            if (newBlog != null) {
              blogs.insert(0, newBlog);
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: Column(
          children: <Widget>[
            isRefreshing
                ? SpinKitCircle(
                    color: Colors.blue,
                    size: 50.0,
                  )
                : Container(),
            Expanded(
              child: ListView.builder(
                controller: _controller,
                itemCount: blogs.length,
                // itemExtent: 200,
                itemBuilder: (BuildContext context, int index) {
                  var blog = blogs[index];
                  bool isForward = false;
                  if (blog['forwardObj'] != null &&
                      blog['forwardObj']['source_id'] != null) {
                    isForward = true;
                  }
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          BuildBlog(
                            blog: blog,
                            type: isForward
                                ? BuildBlog.forward_blog
                                : BuildBlog.normal_blog,
                          ),
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(Icons.redo),
                                      onPressed: () async {
                                        var newBlog = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              // return PhotoViewPage(images);
                                              return ForwardBlogDialog(blog);
                                            },
                                            fullscreenDialog: true,
                                          ),
                                        );
                                        if (newBlog != null) {
                                          blog['forwards'] =
                                              (int.parse(blog['forwards']) + 1)
                                                  .toString();
                                          blogs.insert(0, newBlog);
                                        }
                                      },
                                    ),
                                    Text(blog['forwards']),
                                  ],
                                ),
                                Column(
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(Icons.comment),
                                      onPressed: () {
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder: (context) {
                                        //       // return PhotoViewPage(images);
                                        //       return BlogDetailPage(blog);
                                        //     },
                                        //   ),
                                        // );
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
                                                child: BlogDetailPage(blog),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                    Text(blog['comments']),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ));
  }
}

class MyBlogPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyBlogPageState();
}

class MyBlogPageState extends State<MyBlogPage> {
  List blogs = [];
  Response response;
  ScrollController _controller = new ScrollController();
  bool isRefreshing = false;

  _initData() async {
    setState(() {
      isRefreshing = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = await prefs.get('uid');
    response = await dio
        .get('$baseUrl/blog/getBlogsByUser', queryParameters: {'uid': uid});

    setState(() {
      blogs = response.data['blogs'];
      isRefreshing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initData();
    _controller.addListener(() {
      // 顶端下拉刷新数据
      if (_controller.offset <= -40 && !isRefreshing) {
        _initData();
      }
    });
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用_controller.dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text('my blog'),
        ),
        body: Column(
          children: <Widget>[
            isRefreshing
                ? SpinKitCircle(
                    color: Colors.blue,
                    size: 50.0,
                  )
                : Container(),
            Expanded(
              child: ListView.builder(
                controller: _controller,
                itemCount: blogs.length,
                // itemExtent: 200,
                itemBuilder: (BuildContext context, int index) {
                  var blog = blogs[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          BuildBlog(
                              blog: blog,
                              type: BuildBlog.my_blog,
                              showHeader: false)
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ));
  }
}
