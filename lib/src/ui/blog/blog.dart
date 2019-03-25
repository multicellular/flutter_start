import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../component/photo_view.dart';
import '../component/video_player.dart';

import 'package:photo/photo.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

// import 'package:cached_network_image/cached_network_image.dart';

import '../models/config.dart';

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
  bool isLoading = false;
  Duration duration = new Duration(seconds: 1);
  Timer timer;

  _initData() async {
    isLoading = true;
    response = await dio.get('$baseUrl/blog/getblogs');
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
        timer?.cancel();
        timer = new Timer(duration, () {
          _initData();
        });
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

class PostBlogDialog extends StatefulWidget {
  @override
  State createState() => PostBlogDialogState();
}

class PostBlogDialogState extends State<PostBlogDialog> {
  TextEditingController _contentController = new TextEditingController();
  List<AssetEntity> _images = [];
  List<AssetEntity> _videos = [];
  // String _error = '';
  List _uploadFiles = [];
  bool _isPrivate = false;

  _postBlog() async {
    FormData formData = new FormData.from({'file': _uploadFiles});
    Response uplaodFile = await dio.post('$baseUrl/uploadFile', data: formData);
    String mediaUrls = uplaodFile.data['urls'];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = await prefs.get('uid');
    Response response = await dio.post('$baseUrl/blog/postblog', data: {
      // 'title': '',
      'content': _contentController.text,
      // 'media_type': '',image
      'media_urls': mediaUrls,
      'uid': uid,
      'is_private': _isPrivate
    });
    if (response.data['code'] == 0) {
      Navigator.pop(context);
    }
  }

  void _testPhotoListParams() async {
    var result = await PhotoManager.requestPermission();
    if (result) {
      // success
      var assetPathList = await PhotoManager.getAssetPathList(isCache: true);
      _pickAsset(PickType.all, pathList: assetPathList);
    } else {
      // fail
      /// if result is fail, you can call `PhotoManger.openSetting();`  to open android/ios applicaton's setting to get permission
    }
  }

  Widget _buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: List.generate(_images.length, (index) {
        return AssetImageWidget(
          assetEntity: _images[index],
          width: 300,
          height: 200,
          boxFit: BoxFit.contain,
          onPressed: () {
            setState(() {
              // _images
            });
          },
        );
      }),
    );
  }

  Widget _buildButtonView() {
    bool isHideImageBtn = _images.length > 8 || _videos.length > 0;
    bool isHideVideoBtn = _images.length > 0 || _videos.length > 0;
    return Row(
      children: <Widget>[
        isHideImageBtn
            ? Container()
            : IconButton(
                icon: Icon(Icons.photo),
                onPressed: () => _pickAsset(PickType.onlyImage)),
        isHideVideoBtn
            ? Container()
            : IconButton(
                icon: Icon(Icons.videocam),
                onPressed: () => _pickAsset(PickType.onlyVideo)),
        IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () => _testPhotoListParams()),
      ],
    );
  }

  void _pickAsset(PickType type, {List<AssetPathEntity> pathList}) async {
    List<AssetEntity> imgList = await PhotoPicker.pickAsset(
      // BuildContext required
      context: context,

      /// The following are optional parameters.
      themeColor: Colors.blue,
      // the title color and bottom color
      padding: 1.0,
      // item padding
      dividerColor: Colors.grey,
      // divider color
      disableColor: Colors.grey.shade300,
      // the check box disable color
      itemRadio: 0.88,
      // the content item radio
      maxSelected: type == PickType.onlyVideo ? 1 : 9,
      // max picker image count
      // provider: I18nProvider.english,
      provider: I18nProvider.chinese,
      // i18n provider ,default is chinese. , you can custom I18nProvider or use ENProvider()
      rowCount: 3,
      // item row count
      textColor: Colors.white,
      // text color
      thumbSize: 150,
      // preview thumb size , default is 64
      sortDelegate: SortDelegate.common,
      // default is common ,or you make custom delegate to sort your gallery
      checkBoxBuilderDelegate: DefaultCheckBoxBuilderDelegate(
        activeColor: Colors.white,
        unselectedColor: Colors.white,
      ),
      // default is DefaultCheckBoxBuilderDelegate ,or you make custom delegate to create checkbox
      badgeDelegate: const DurationBadgeDelegate(),
      // badgeDelegate to show badge widget
      pickType: type,
      photoPathList: pathList,
    );

    if (imgList == null) {
      // _error = "not select item";
    } else {
      List<String> r = [];
      // print(imgList);
      for (var e in imgList) {
        var file = await e.file;
        // r.add(file.absolute.path);
        if (type == PickType.onlyVideo) {
          _uploadFiles.add(new UploadFileInfo(file, '.mp4'));
        } else {
          _uploadFiles.add(new UploadFileInfo(file, '.png'));
        }
      }
      // _error = r.join("\n\n");
      setState(() {
        if (type == PickType.onlyVideo) {
          _videos.addAll(imgList);
        } else {
          _images.addAll(imgList);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Dialog'),
        actions: <Widget>[
          Center(
            child: GestureDetector(
              onTap: () {
                _postBlog();
              },
              child: Text('send'),
            ),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            // height: 300,
            child: TextFormField(
              autofocus: true,
              controller: _contentController,
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
            ),
          ),
          CheckboxListTile(
            // secondary: const Icon(Icons.shutter_speed),
            title: const Text('私人发送'),
            value: _isPrivate,
            onChanged: (bool value) {
              setState(() {
                _isPrivate = !_isPrivate;
              });
            },
          ),
          _buildButtonView(),
          Expanded(
            child: _images.length > 0 ? _buildGridView() : Container(),
          ),
          // Center(child: Text('Error: $_error')),
        ],
      ),
    );
  }
}

class AssetImageWidget extends StatelessWidget {
  final AssetEntity assetEntity;
  final double width;
  final double height;
  final BoxFit boxFit;
  final VoidCallback onPressed;

  const AssetImageWidget({
    Key key,
    @required this.assetEntity,
    this.width,
    this.height,
    this.boxFit,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (assetEntity == null) {
      return _buildContainer();
    }
    return FutureBuilder<Size>(
      builder: (c, s) {
        if (!s.hasData) {
          return Container();
        }
        var size = s.data;
        return FutureBuilder<Uint8List>(
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasData) {
              return _buildContainer(
                child: Image.memory(
                  snapshot.data,
                  width: width,
                  height: height,
                  fit: boxFit,
                ),
              );
            } else {
              return _buildContainer();
            }
          },
          future: assetEntity.thumbDataWithSize(
            size.width.toInt(),
            size.height.toInt(),
          ),
        );
      },
      future: assetEntity.size,
    );
  }

  Widget _buildContainer({Widget child}) {
    child ??= Container();
    return Stack(
      // alignment: Alignment.topRight,
      fit: StackFit.expand,
      overflow: Overflow.clip,
      children: <Widget>[
        Container(
          width: width,
          height: height,
          child: child,
        ),
        Positioned(
          right: -2,
          child: IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: onPressed,
          ),
        ),
      ],
    );
    // return Container(
    //   width: width,
    //   height: height,
    //   child: child,
    // );
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
    await dio.post('$baseUrl/blog/postblog', data: {
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
    Response response = await dio.get('$baseUrl/blog/getcomments',
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
      '$baseUrl/blog/postcomment',
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
            // backgroundImage: new CachedNetworkImageProvider(urlPath + comment['uavator']),
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
            ? _initImages(mediaUrls)
            : Image.asset('assets/images/video_default.jpg'),
      ),
    );
  }

  _previewImage(String imageUrls, BuildContext context) {
    List images = [];
    List viewImages = [];
    if (imageUrls.isNotEmpty) {
      images = imageUrls.split(',');
    }
    for (var image in images) {
      viewImages.add(urlPath + image);
    }
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PhotoViewPage(viewImages);
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

  Widget _initImages(String imagesStr) {
    List images = [];
    if (imagesStr.isNotEmpty) {
      images = imagesStr.split(',');
    }
    var len = images.length;
    if (len == 0) {
      return Container();
    }
    List<Widget> widgets = <Widget>[];

    // double width;
    // if (len == 1) {
    //   width = 336;
    // } else if (len == 2) {
    //   width = 168;
    // } else {
    //   width = 120;
    // }
    for (var image in images) {
      // Widget widget = Image.network(
      //   urlPath + image,
      //   height: 100,
      //   width: 100,
      //   fit: BoxFit.cover,
      // );
      Widget widget = new Image(
        // image: new CachedNetworkImageProvider(urlPath + image),
        image: NetworkImage(urlPath + image),
        width: 100,
        height: 100,
        fit: BoxFit.contain
      );
      widgets.add(widget);
    }
    return GridView.count(
      crossAxisCount: images.length > 2 ? 3 : images.length,
      // crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: images.length > 2 ? 1 : 3/2,
      shrinkWrap: true, //增加
      physics: new NeverScrollableScrollPhysics(), //增加
      children: widgets,
    );
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
                    // backgroundImage: new CachedNetworkImageProvider(urlPath + blog['uavator']),
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
        // 评论内容 转发时的评�� type区分是否为转发
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
  Duration duration = new Duration(seconds: 1);
  Timer timer;

  _initData() async {
    isLoading = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = await prefs.get('uid');
    response = await dio
        .get('$baseUrl/blog/getBlogsByUser', queryParameters: {'uid': uid});
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
        timer?.cancel();
        timer = new Timer(duration, () {
          _initData();
        });
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
