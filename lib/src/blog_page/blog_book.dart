import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../component/kf_drawer.dart';
import './blog_detail.dart';
import './blog_send.dart';
import './blog_widgets.dart';
import '../models/config.dart';
// import '../home_page/home.dart';
// import '../chat_page/chat_book.dart';
import '../component/dioHttp.dart';
var urlPath = DefaultConfig.urlPath;
class BlogPage extends KFDrawerContent {
  @override
  BlogPageState createState() => new BlogPageState();
}

class BlogPageState extends State<BlogPage> {
  List blogs = [];
  ScrollController _controller = new ScrollController();
  bool isRefreshing = false;
  String _tip = 'no data';
  // CircularProgressIndicator progressIndicator = CircularProgressIndicator();

  _initData() async {
    setState(() {
      isRefreshing = true;
    });
    var blogRes = await dioHttp.httpGet('/blog/getblogs');
    if (blogRes != null) {
      setState(() {
        blogs = blogRes['blogs'];
        isRefreshing = false;
      });
    } else {
      setState(() {
        isRefreshing = false;
      });
    }
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
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: widget.onMenuPressed,
            ),
            PopupMenuButton<String>(
              offset: Offset(30, 40),
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
        // drawer: Drawer(
        //   child: ListView(
        //     children: <Widget>[
        //       SizedBox(height: 90,),
        //       ListTile(
        //         leading: Icon(Icons.home),
        //         title: Text('Home'),
        //         onTap: () {
        //           Navigator.push(context, MaterialPageRoute(builder: (context) {
        //             return HomePage();
        //           }));
        //         },
        //       ),
        //       ListTile(
        //         leading: Icon(Icons.chat),
        //         title: Text('Chat'),
        //         onTap: () {
        //           Navigator.push(context, MaterialPageRoute(builder: (context) {
        //             return ChatBookPage();
        //           }));
        //         },
        //       )
        //     ],
        //   ),
        // ),
        // bottomNavigationBar: BottomAppBar(
        //   shape: CircularNotchedRectangle(),
        //   child: Row(
        //     children: <Widget>[
        //       IconButton(
        //         icon: Icon(Icons.home),
        //         iconSize: 50,
        //         onPressed: () {
        //           Navigator.push(context, MaterialPageRoute(builder: (context) {
        //             return HomePage();
        //           }));
        //         },
        //       ),
        //       SizedBox(),
        //       IconButton(
        //         icon: Icon(Icons.group),
        //         iconSize: 50,
        //         onPressed: () {
        //           // Navigator.push(context, MaterialPageRoute(builder: (context) {
        //           //   return ChatRoomPage();
        //           // }));
        //         },
        //       )
        //     ],
        //     mainAxisAlignment: MainAxisAlignment.spaceAround,
        //   ),
        // ),
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Column(
          children: <Widget>[
            isRefreshing
                ? SpinKitCircle(
                    color: Colors.blue,
                    size: 50.0,
                  )
                : blogs.length > 0 ? Text(_tip) : Container(),
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
  ScrollController _controller = new ScrollController();
  bool isRefreshing = false;

  _initData() async {
    setState(() {
      isRefreshing = true;
    });
    var blogRes =
        await dioHttp.httpGet('/blog/getBlogsByUser', needToken: true);
    if (blogRes != null) {
      setState(() {
        blogs = blogRes['blogs'];
        isRefreshing = false;
      });
    }
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
                          PopupMenuButton<String>(
                            offset: Offset(30, 40),
                            // overflow menu
                            onSelected: (value) async {
                              var res = await dioHttp.httpGet(
                                  '/blog/deleteBlog',
                                  req: {'blogid': blog['id']});
                              if (res != null) {
                                setState(() {
                                  blogs.removeAt(index);
                                });
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('delete blog'),
                                )
                              ];
                            },
                          ),
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
