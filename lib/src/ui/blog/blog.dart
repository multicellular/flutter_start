import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/photo_view.dart';
import '../component/video_player.dart';

// Options options = new BaseOptions(baseUrl: 'localhost:3000/api');
// Dio dio = new Dio(options);
Dio dio = new Dio();
// dio.options.baseUrl = 'localhost:3000/api';
var urlPath = 'http://localhost:3000/';

class BlogPage extends StatefulWidget {
  @override
  BlogPageState createState() => new BlogPageState();
}

class BlogPageState extends State<BlogPage> {
  List blogs = [];
  Response response;
  ScrollController _controller = new ScrollController();
  bool isLoading = false;

  _initData() async {
    isLoading = true;
    response = await dio.get('http://localhost:3000/api/blog/getblogs');
    isLoading = false;
    setState(() {
      blogs = response.data['blogs'];
    });
  }

  @override
  void initState() {
    super.initState();
    _initData();
    _controller.addListener(() {
      // 顶端下拉刷新数据
      if (_controller.offset <= 0 && !isLoading) {
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
                        blog,
                        isForward
                            ? BuildBlog.forward_blog
                            : BuildBlog.normal_blog,
                        true),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.redo),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        // return PhotoViewPage(images);
                                        return ForwardBlogDialog(blog);
                                      },
                                      fullscreenDialog: true,
                                    ),
                                  );
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        // return PhotoViewPage(images);
                                        return BlogDetailPage(blog);
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
    );
  }
}

class PostBlogDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('post blog'),
        actions: <Widget>[Text('send')],
      ),
      body: Text('Dialog'),
    );
  }
}

class ForwardBlogDialog extends StatelessWidget {
  final dynamic blog;
  ForwardBlogDialog(this.blog);
  final TextEditingController _commentController = new TextEditingController();

  _forwardBlog(BuildContext context) async {
    String comment = _commentController.text;
    if (comment == null || comment.isEmpty) {
      return;
    }
    int sourceId;
    if (blog['source_id'] == null) {
      sourceId = blog['id'];
    } else {
      sourceId = blog['source_id'];
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = await prefs.get('uid');
    // data: { title, content, media_urls, media_type, uid, forward_comment, source_id, is_private }
    await dio.post('http://localhost:3000/api/blog/postblog', data: {
      'forward_comment': _commentController.text,
      'uid': uid,
      'source_id': sourceId
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('forward blog'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _forwardBlog(context);
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: TextFormField(
                autofocus: true,
                controller: _commentController,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                maxLength: 200,
                maxLengthEnforced: true,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: '说点什么吧...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
                onFieldSubmitted: (String value) {
                  // _sendComment(value);
                  Navigator.pop(context);
                }),
          ),
          BuildBlog(blog, BuildBlog.forward_blog, false),
        ],
      ),
    );
  }
}

class BlogDetailPage extends StatefulWidget {
  final dynamic blog;
  BlogDetailPage(this.blog);
  @override
  State<StatefulWidget> createState() => new BlogDetailPageState();
}

class BlogDetailPageState extends State<BlogDetailPage> {
  // TextEditingController _commentController = new TextEditingController();
  List _comments = [];

  _getComments() async {
    Response response = await dio.get(
        'http://localhost:3000/api/blog/getcomments',
        queryParameters: {'blogid': widget.blog['id']});
    setState(() {
      _comments = response.data['comments'];
    });
  }

  _sendComment(String content) async {
    if (content == null || content.isEmpty) {
      // content = _commentController.text;
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = await prefs.get('uid');
    Response response = await dio.post(
      'http://localhost:3000/api/blog/postcomment',
      data: {
        'blogid': widget.blog['id'],
        'content': content,
        'uid': uid,
      },
    );
    var comment = response.data['comment'];
    setState(() {
      _comments.add(comment);
    });
  }

  Widget _buildCommentsWidget(List comments) {
    return Column(
      children: comments.map((comment) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(urlPath + comment['uavator']),
          ),
          title: Text(comment['content']),
          subtitle: Text(comment['uname']),
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    _getComments();
  }

  @override
  Widget build(BuildContext context) {
    bool isForward = false;
    if (widget.blog['forwardObj'] != null &&
        widget.blog['forwardObj']['source_id'] != null) {
      isForward = true;
    }
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
                      height: 300,
                      child: TextFormField(
                          autofocus: true,
                          // controller: _commentController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          maxLength: 200,
                          maxLengthEnforced: true,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: '说点什么吧...',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                          ),
                          onFieldSubmitted: (String value) {
                            _sendComment(value);
                            Navigator.pop(context);
                          }),
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
        margin: EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              BuildBlog(
                  widget.blog,
                  isForward ? BuildBlog.forward_blog : BuildBlog.normal_blog,
                  true),
              Container(
                margin: EdgeInsets.only(top: 12),
                child: Text('comments'),
              ),
              _buildCommentsWidget(_comments),
            ],
          ),
        ),
      ),
    );
  }
}

class BuildBlog extends StatelessWidget {
  final dynamic blog;
  final String type;
  final bool showHeader;
  static const String normal_blog = 'normal_blog';
  static const String forward_blog = 'forward_blog';
  static const String my_blog = 'my_blog';

  BuildBlog(this.blog, this.type, this.showHeader);

  Widget _initMediaWidget(
      String mediaType, String mediaUrls, BuildContext context) {
    return GestureDetector(
      onTap: () {
        mediaType == 'image'
            ? _previewImage(mediaUrls, context)
            : _previewVideo(mediaUrls, context);
      },
      child: Container(
        margin: EdgeInsets.all(2),
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

  _previewImage(String imageUrls, BuildContext context) {
    List images = [];
    if (imageUrls.isNotEmpty) {
      images = imageUrls.split(',');
    }
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PhotoViewPage(images);
          },
          fullscreenDialog: true,
        ));
  }

  _previewVideo(String url, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            // return PhotoViewPage(images);
            return VideoApp(url);
          },
          fullscreenDialog: true,
        ));
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

  @override
  Widget build(BuildContext context) {
    String sourceUname = blog['uname'];
    String forwardComment = '';
    if (blog['forwardObj'] != null &&
        blog['forwardObj']['source_uid'] != null) {
      sourceUname = blog['forwardObj']['source_uname'];
      forwardComment = blog['forwardObj']['forward_comment'];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 博客标题 头像、名称、时间，showHeader控制是否展示
        showHeader
            ? Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundImage: NetworkImage(urlPath + blog['uavator']),
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
              )
            : Container(),
        // 评论内容 转发时的评论 type区分是否为转发
        type == BuildBlog.forward_blog 
            ? Container(
                child: Text(
                  forwardComment,
                  style: TextStyle(fontSize: 20),
                ),
              )
            : Container(),
        // 博客内容 转发时内容+@name type区分是否为转发
        Container(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          child: Text(
            type == BuildBlog.forward_blog
                ? '@$sourceUname//' + blog['content']
                : blog['content'],
            style: TextStyle(fontSize: 20),
          ),
        ),
        // 博客媒资 media_type区分 图片或视频或文件
        _initMediaWidget(blog['media_type'], blog['media_urls'], context),
        // 博客时间 暂用于我的博客 type区分是否个人博客
        type == BuildBlog.my_blog
            ? Container(
                margin: EdgeInsets.only(top: 12),
                child: Text(blog['moment']),
              )
            : Container()
      ],
    );
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
  bool isLoading = false;

  _initData() async {
    isLoading = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = await prefs.get('uid');
    response = await dio.get('http://localhost:3000/api/blog/getBlogsByUser',
        queryParameters: {'uid': uid});
    isLoading = false;
    setState(() {
      blogs = response.data['blogs'];
    });
  }

  @override
  void initState() {
    super.initState();
    _initData();
    _controller.addListener(() {
      // 顶端下拉刷新数据
      if (_controller.offset <= 0 && !isLoading) {
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
      body: Container(
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
                  children: <Widget>[BuildBlog(blog, BuildBlog.my_blog, false)],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
