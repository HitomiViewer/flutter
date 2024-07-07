import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ZoomableImage extends StatefulWidget {
  final String imageUrl;

  const ZoomableImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  ZoomableImageState createState() => ZoomableImageState();
}

class ZoomableImageState extends State<ZoomableImage> {
  final _transformationController = TransformationController();
  double correctScaleValue = 1.0;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 1,
      maxScale: 10,
      transformationController: _transformationController,
      onInteractionEnd: (details) {
        setState(() {
          correctScaleValue =
              _transformationController.value.getMaxScaleOnAxis();
        });
      },
      child: CachedNetworkImage(
        placeholder: (context, url) => const CircularProgressIndicator(),
        imageUrl: widget.imageUrl,
        filterQuality: FilterQuality.high,
        imageBuilder: (context, imageProvider) {
          return Image(
            image: ResizeImage(
              imageProvider,
              height: (correctScaleValue * MediaQuery.of(context).size.height)
                  .toInt(),
            ),
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}
