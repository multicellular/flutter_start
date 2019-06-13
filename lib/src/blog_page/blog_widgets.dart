import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../login_page/profile.dart';
import '../component/photo_view.dart';
import '../component/video_player.dart';
import '../models/config.dart';

var urlPath = DefaultConfig.urlPath;
// var baseUrl = DefaultConfig.baseUrl;

class BuildBlog extends StatelessWidget {
  final dynamic blog;
  final String type;
  final bool showHeader;
  static const String normal_blog = 'normal_blog';
  static const String forward_blog = 'forward_blog';
  static const String my_blog = 'my_blog';

  BuildBlog({this.blog, this.type, this.showHeader = true});

  Widget _initContentWidget({uname = '', int uid, BuildContext context}) {
    // 博客内容 转发时内容+@name type区分是否为转发
    // TODO 此次无法销毁_tapGestureRecognizer，可能会内存泄露，后期修正
    TapGestureRecognizer _tapGestureRecognizer = new TapGestureRecognizer();
    Widget text = type == BuildBlog.forward_blog
        ? Text.rich(TextSpan(children: [
            TextSpan(
              text: '@$uname:',
              style: TextStyle(color: Colors.blue),
              recognizer: _tapGestureRecognizer
                ..onTap = () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ProfilePage(uid);
                  }));
                },
            ),
            TextSpan(text: blog['content']),
          ]))
        : Text(blog['content']);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child:
          (blog['content'] == null || blog['content'].isNotEmpty) ? text : null,
    );
  }

  Widget _initMediaWidget(
      String mediaType, String mediaUrls, BuildContext context, String tag) {
    return Container(
      margin: EdgeInsets.all(10),
      child: mediaType == 'image'
          ? _initImages(mediaUrls, context, tag)
          : GestureDetector(
              child: Image.asset('assets/images/video_default.jpg'),
              onTap: () {
                _previewVideo(mediaUrls, context);
              },
            ),
    );
  }

  _previewImage(String imageUrls, BuildContext context, int page, String tag) {
    List images = [];
    List viewImages = [];
    if (imageUrls.isNotEmpty) {
      images = imageUrls.split(',');
    }
    for (var image in images) {
      // viewImages.add(urlPath + image);
      viewImages.add({'tag': tag, 'url': urlPath + image});
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        // transitionDuration:
        //     Duration(milliseconds: 500),
        pageBuilder: (BuildContext context, Animation animation,
            Animation secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: PhotoViewPage(
              viewImages,
              page: page,
            ),
          );
        },
      ),
    );
  }

  _previewVideo(String url, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            // return PhotoViewPage(images);
            return VideoApp(urlPath + url);
          },
          fullscreenDialog: true,
        ));
  }

  Widget _initImages(String imagesStr, BuildContext context, String tag) {
    List images = [];
    if (imagesStr.isNotEmpty) {
      images = imagesStr.split(',');
    }
    var len = images.length;
    if (len == 0) {
      return Container();
    }
    List<Widget> widgets = <Widget>[];
    for (int i = 0; i < images.length; i++) {
      String image = images[i];
      // Widget widget = new Image(
      //     image: new CachedNetworkImageProvider(urlPath + image),
      //     // image: NetworkImage(urlPath + image),
      //     width: 100,
      //     height: 100,
      //     fit: BoxFit.cover);
      Widget widget = Hero(
          tag: tag + image,
          child: GestureDetector(
            onTap: () {
              _previewImage(imagesStr, context, i, tag + image);
            },
            child: CachedNetworkImage(
              width: 300,
              height: 300,
              fit: BoxFit.cover,
              placeholder: (context, string) {
                return Image.asset('assets/images/no_image.jpeg');
              },
              errorWidget: (context, string, obj) {
                return Image.asset('assets/images/no_image.jpeg');
              },
              imageUrl: urlPath + image,
            ),
          ));
      widgets.add(widget);
    }
    return GridView.count(
      crossAxisCount: images.length > 2 ? 3 : images.length,
      // crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: images.length > 2 ? 1 : 3 / 2,
      shrinkWrap: true, //增加
      physics: new NeverScrollableScrollPhysics(), //增加
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    String sourceUname = blog['uname'];
    int scurceUid;
    String forwardComment = '';
    if (blog['forwardObj'] != null && blog['forwardObj']['source_id'] != null) {
      sourceUname = blog['forwardObj']['source_uname'];
      scurceUid = blog['forwardObj']['source_uid'];
      forwardComment = blog['forwardObj']['forward_comment'];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 博客标题 头像、名称、时间，showHeader控制是否展示
        showHeader
            ? GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ProfilePage(blog['uid']);
                  }));
                },
                child: Row(
                  children: <Widget>[
                    ClipOval(
                      child: SizedBox(
                        width: 40.0,
                        height: 40.0,
                        // child: Image.network(urlPath + _profile['avator'],
                        //     fit: BoxFit.cover),
                        child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          // placeholder: (context, string) {
                          //   return Image.asset('assets/images/no_avatar.jpeg');
                          // },
                          errorWidget: (context, string, obj) {
                            return Image.asset('assets/images/no_avatar.jpeg');
                          },
                          imageUrl: urlPath + (blog['uavator'] ?? ''),
                        ),
                      ),
                    ),
                    // CircleAvatar(
                    //   // backgroundImage: NetworkImage(urlPath + blog['uavator']),
                    //   backgroundImage: blog['uavator'] != null
                    //       ? new CachedNetworkImageProvider(
                    //           urlPath + blog['uavator'])
                    //       : AssetImage('assets/images/no_avatar.jpeg'),
                    //   // child: Text(blog['uname']),
                    // ),
                    Container(
                      margin: EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            blog['uname'] ?? '',
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
              )
            : Container(),
        // 评论内容 转���时的评����� type区分是否为转发
        type == BuildBlog.forward_blog
            ? Container(
                child: forwardComment.isNotEmpty
                    ? Text(
                        forwardComment,
                        style: TextStyle(fontSize: 20),
                      )
                    : null,
              )
            : Container(),
        Container(
          color: type == BuildBlog.forward_blog
              ? const Color(0XFFf5f5f5)
              : Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 博客内容 转发时内容+@name type区分是否为转发
              _initContentWidget(
                  uname: sourceUname, uid: scurceUid, context: context),
              // 博客媒资 media_type区分 图片或视频或文件
              _initMediaWidget(
                  blog['media_type'], blog['media_urls'], context, blog['id'].toString()),
            ],
          ),
        ),
        // 博客时间 暂用于我的博客 type区分��否个人博客
        type == BuildBlog.my_blog
            ? Row(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    child: Text(blog['moment']),
                  ),
                ],
                // Response response = await dio.get(
                //         '$baseUrl/blog/deleteBlog',
                //         queryParameters: {'blogid': blog['id']});
                //     if (response.data['code'] == 0) {
                //       _onPressed;
                //     }
              )
            : Container(),
      ],
    );
  }
}
