import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import './blog_widgets.dart';
import '../models/config.dart';

Dio dio = new Dio();
var urlPath = DefaultConfig.urlPath;
var baseUrl = DefaultConfig.baseUrl;

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
    if (response.data['code'] == 0) {
      var comment = response.data['comment'];
      setState(() {
        _comments.add(comment);
        widget.blog['comments'] = _comments.length.toString();
      });
    }
  }

  Widget _buildCommentsWidget(List comments) {
    return Column(
      children: comments.map((comment) {
        return ListTile(
          leading: CircleAvatar(
            // backgroundImage: NetworkImage(urlPath + comment['uavator']),
            backgroundImage:
                new CachedNetworkImageProvider(urlPath + comment['uavator']),
          ),
          title: Text(comment['uname']),
          subtitle: Text(comment['content']),
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
                blog: widget.blog,
                type:
                    isForward ? BuildBlog.forward_blog : BuildBlog.normal_blog,
              ),
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
