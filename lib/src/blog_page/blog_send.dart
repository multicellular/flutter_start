import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_flutter/src/component/toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geocoder/geocoder.dart';
import 'package:location/location.dart';
import './blog_widgets.dart';
import '../models/config.dart';
import '../component/dioHttp.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

var urlPath = DefaultConfig.urlPath;

class PostBlogDialog extends StatefulWidget {
  @override
  State createState() => PostBlogDialogState();
}

class PostBlogDialogState extends State<PostBlogDialog> {
  TextEditingController _contentController = new TextEditingController();
  List<Asset> _images = List<Asset>();
  File _video;
  bool _isPrivate = false;
  bool _isSending = false;
  //Strings required to save address
  Address address;

  @override
  initState() {
    super.initState();
    // initLocation();
  }

  _postBlog() async {
    if (_isSending) {
      showToast('seding...please wait a moment!', type: ToastType.tip());
      return;
    }
    setState(() {
      _isSending = true;
    });

    String mediaType = 'image';
    FormData formData;
    if (_video != null) {
      mediaType = 'video';
      formData =
          new FormData.from({'file': new UploadFileInfo(_video, _video.path)});
    } else {
      List _uploadFiles = [];
      for (var asset in _images) {
        ByteData byteData = await asset.requestThumbnail(300, 300, quality: 60);
        List<int> imageData = byteData.buffer.asUint8List();
        _uploadFiles.add(new UploadFileInfo.fromBytes(imageData, 'blog.jpeg'));
      }
      formData = new FormData.from({'file': _uploadFiles});
    }
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

  Widget _buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: List.generate(_images.length, (index) {
        Asset asset = _images[index];
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          overflow: Overflow.clip,
          children: <Widget>[
            AssetThumb(
              asset: asset,
              width: 300,
              height: 300,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                color: Colors.redAccent,
                icon: Icon(Icons.delete_forever),
                onPressed: () {
                  setState(() {
                    _images.removeAt(index);
                  });
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildButtonView() {
    bool isHideImageBtn = _images.length > 8 || _video != null;
    bool isHideVideoBtn = _images.length > 0 || _video != null;
    return Row(
      children: <Widget>[
        isHideImageBtn
            ? Container()
            : IconButton(
                icon: Icon(Icons.photo), onPressed: () => loadAssets()),
        isHideVideoBtn
            ? Container()
            : IconButton(
                icon: Icon(Icons.videocam),
                onPressed: () async {
                  _video = await FilePicker.getFile(type: FileType.VIDEO);
                }),
        Expanded(
          flex: 1,
          child: PopupMenuButton<String>(
            offset: Offset(30, 40),
            child: IconButton(
              icon: Icon(Icons.add_location),
              onPressed: () async {
                if (address == null) {
                  address = await getUserLocation();
                }
              },
            ),
            // overflow menu
            onSelected: (value) async {},
            itemBuilder: (BuildContext context) {
              return address == null
                  ? Text('定位中...')
                  : [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: buildLocationButton(address.featureName),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: buildLocationButton(address.subLocality),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: buildLocationButton(address.locality),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: buildLocationButton(address.subAdminArea),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: buildLocationButton(address.adminArea),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: buildLocationButton(address.countryName),
                      ),
                    ];
            },
          ),
        ),
      ],
    );
  }

  //method to build buttons with location.
  buildLocationButton(String locationName) {
    if (locationName != null ?? locationName.isNotEmpty) {
      return InkWell(
        onTap: () {
          // locationController.text = locationName;
        },
        child: Center(
          child: Container(
            //width: 100.0,
            height: 30.0,
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            margin: EdgeInsets.only(right: 3.0, left: 3.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Center(
              child: Text(
                locationName,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Future<void> loadAssets() async {
    // setState(() {
    //   _images = List<Asset>();
    // });

    List<Asset> resultList;
    // String error;

    try {
      resultList =
          await MultiImagePicker.pickImages(maxImages: 9, enableCamera: true);
    } catch (e) {
      // error = e.message;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _images.addAll(resultList);
    });
  }

  getUserLocation() async {
    LocationData currentLocation;
    String error;
    Location location = Location();
    try {
      currentLocation = await location.getLocation();
    } catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'please grant permission';
        print(error);
      }
      if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error = 'permission denied- please enable it from app settings';
        print(error);
      }
      currentLocation = null;
    }
    final coordinates =
        Coordinates(currentLocation.latitude, currentLocation.longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    return first;
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
              // textInputAction: TextInputAction.send,
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
            child: _buildGridView(),
          ),
          // Center(child: Text('Error: $_error')),
        ],
      ),
    );
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
              // textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: '说点什么吧...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              // onFieldSubmitted: (String value) {
              //   // _sendComment(value);
              //   Navigator.pop(context);
              // },
            ),
          ),
          BuildBlog(
              blog: blog, type: BuildBlog.forward_blog, showHeader: false),
        ],
      ),
    );
  }
}

/* File to get location of user
* used dependencies - location => to get location coordinates of user,
*   - geoLocation => To get Address from the location coordinates
 */
// import 'package:flutter/services.dart';
// import 'package:geocoder/geocoder.dart';
// import 'package:location/location.dart';
