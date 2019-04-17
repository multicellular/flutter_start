import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hello_flutter/src/component/toast.dart';
import 'package:photo/photo.dart';
import 'package:photo_manager/photo_manager.dart';
import './blog_widgets.dart';
import '../models/config.dart';
import '../component/dioHttp.dart';

var urlPath = DefaultConfig.urlPath;

class PostBlogDialog extends StatefulWidget {
  @override
  State createState() => PostBlogDialogState();
}

class PostBlogDialogState extends State<PostBlogDialog> {
  TextEditingController _contentController = new TextEditingController();
  List<AssetEntity> _images = [];
  List<AssetEntity> _videos = [];
  // String _error = '';
  bool _isPrivate = false;
  bool _isSending = false;

  _postBlog() async {
    if (_isSending) {
      showToast('seding...please wait a moment!', type: ToastType.tip());
      return;
    }
    setState(() {
      _isSending = true;
    });
    List<AssetEntity> uploads = _videos.length > 0 ? _videos : _images;
    String mediaType = _videos.length > 0 ? 'video' : 'image';
    List _uploadFiles = [];
    for (var upload in uploads) {
      File tempFile = await upload.file;
      File file =
          mediaType == 'image' ? await _compressAndGetFile(tempFile) : tempFile;
      // String extension = path.extension(file.path);
      // print(extension);
      _uploadFiles.add(new UploadFileInfo(file, file.path));
    }
    FormData formData = new FormData.from({'file': _uploadFiles});

    var uploadRes = await dioHttp.httpPost('/uploadFile', req: formData);
    String mediaUrls = uploadRes['urls'];

    var blogRes = await dioHttp.httpPost('/blog/postblog',
        req: {
          'content': _contentController.text,
          'media_type': mediaType,
          'media_urls': mediaUrls,
          'is_private': _isPrivate
        },
        needToken: true);
    if (blogRes != null) {
      Navigator.pop(context, blogRes['blog']);
    }
    setState(() {
      _isSending = false;
    });
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

  Future<File> _compressAndGetFile(File file) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      file.absolute.path,
      minWidth: 300,
      minHeight: 300,
      quality: 100,
      // rotate: 90,
    );
    // print(file.lengthSync());
    // print(result.length);
    return result;
  }

  Widget _buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: List.generate(_images.length, (index) {
        return AssetImageWidget(
          assetEntity: _images[index],
          width: 200,
          height: 200,
          boxFit: BoxFit.cover,
          onPressed: () {
            setState(() {
              // _images
              _images.removeAt(index);
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
        // IconButton(
        //     icon: Icon(Icons.videocam),
        //     onPressed: () => _testPhotoListParams()),
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
      // rowCount: 3,
      // item row count
      textColor: Colors.white,
      // text color
      // thumbSize: 64,
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
      // List<String> r = [];
      // for (var e in imgList) {
      //   var file = await e.file;
      //   // r.add(file.absolute.path);
      //   if (type == PickType.onlyVideo) {
      //     _uploadFiles.add(new UploadFileInfo(file, '.mp4'));
      //   } else {
      //     _uploadFiles.add(new UploadFileInfo(file, '.png'));
      //   }
      // }
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
          Container(
            margin: EdgeInsets.only(top: 18, right: 12),
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
      alignment: Alignment.center,
      fit: StackFit.expand,
      overflow: Overflow.clip,
      children: <Widget>[
        Container(
          width: width,
          height: height,
          child: child,
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            color: Colors.redAccent,
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
    // if (comment == null || comment.isEmpty) {
    //   return;
    // }
    int sourceId;
    if (blog['forwardObj'] != null && blog['forwardObj']['source_id'] != null) {
      sourceId = blog['forwardObj']['source_id'];
    } else {
      sourceId = blog['id'];
    }
    var blogRes = dioHttp.httpPost('/blog/postblog',
        req: {'forward_comment': comment, 'source_id': sourceId},
        needToken: true);
    if (blogRes != null) {
      Navigator.pop(context, blogRes['blog']);
    }
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
          BuildBlog(
              blog: blog, type: BuildBlog.forward_blog, showHeader: false),
        ],
      ),
    );
  }
}
