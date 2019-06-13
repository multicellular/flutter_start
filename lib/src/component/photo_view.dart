import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:cached_network_image/cached_network_image.dart';

class PhotoViewPage extends StatefulWidget {
  final List images;
  final int page;
  PhotoViewPage(this.images, {this.page = 0});

  @override
  State<StatefulWidget> createState() {
    return PhotoViewPageState();
  }
}

class PhotoViewPageState extends State<PhotoViewPage> {
  List<PhotoViewGalleryPageOptions> _widgets = <PhotoViewGalleryPageOptions>[];
  int _page;
  @override
  void initState() {
    super.initState();
    List<PhotoViewGalleryPageOptions> temp = [];
    for (var image in widget.images) {
      PhotoViewGalleryPageOptions widget = PhotoViewGalleryPageOptions(
        imageProvider: CachedNetworkImageProvider(image['url']),
        heroTag: image['tag'],
      );
      temp.add(widget);
    }
    setState(() {
      _widgets.addAll(temp);
      _page = widget.page + 1;
    });
  }
  // PhotoViewPage(this.images, {this.page = 0}) {
  //   for (var image in images) {
  //     PhotoViewGalleryPageOptions widget = PhotoViewGalleryPageOptions(
  //       // imageProvider: NetworkImage(image),
  //       imageProvider: CachedNetworkImageProvider(image),
  //       heroTag: image,
  //     );
  //     widgets.add(widget);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_page/${widget.images.length}'),
      ),
      body: Container(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: PhotoViewGallery(
            pageController: PageController(initialPage: widget.page),
            pageOptions: _widgets,
            backgroundDecoration: BoxDecoration(color: Colors.black54),
            onPageChanged: (int index) {
              setState(() {
                _page = index + 1;
              });
            },
          ),
        ),
      ),
    );
  }
}
