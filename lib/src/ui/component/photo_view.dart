import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

// import 'package:cached_network_image/cached_network_image.dart';

class PhotoViewPage extends StatelessWidget {
  final List images;
  final List<PhotoViewGalleryPageOptions> widgets =
      <PhotoViewGalleryPageOptions>[];
  PhotoViewPage(this.images) {
    for (var image in images) {
      PhotoViewGalleryPageOptions widget = PhotoViewGalleryPageOptions(
        imageProvider: NetworkImage(image),
        // imageProvider: CachedNetworkImageProvider(image),
        heroTag: "tag1",
      );
      widgets.add(widget);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('preview image'),
      ),
      body: Container(
        child: PhotoViewGallery(
          pageOptions: widgets,
          backgroundDecoration: BoxDecoration(color: Colors.black87),
        ),
      ),
    );
  }
}
