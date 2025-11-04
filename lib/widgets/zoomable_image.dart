import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class ZoomableImage extends StatefulWidget {
  final String imageUrl;

  const ZoomableImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  ZoomableImageState createState() => ZoomableImageState();
}

class ZoomableImageState extends State<ZoomableImage> {
  // final _transformationController = TransformationController();
  final _viewController = PhotoViewController();
  double correctScaleValue = 1.0;

  @override
  Widget build(BuildContext context) {
    // return InteractiveViewer(
    //   panEnabled: true,
    //   minScale: 1,
    //   maxScale: 10,
    //   transformationController: _transformationController,
    //   onInteractionEnd: (details) {
    //     setState(() {
    //       correctScaleValue =
    //           _transformationController.value.getMaxScaleOnAxis();
    //     });
    //   },
    //   child: CachedNetworkImage(
    //     placeholder: (context, url) => const CircularProgressIndicator(),
    //     imageUrl: widget.imageUrl,
    //     filterQuality: FilterQuality.high,
    //     imageBuilder: (context, imageProvider) {
    //       return Image(
    //         image: ResizeImage(
    //           imageProvider,
    //           height: (correctScaleValue * MediaQuery.of(context).size.height)
    //               .toInt(),
    //         ),
    //         fit: BoxFit.contain,
    //       );
    //     },
    //   ),
    // );
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final delta = event.scrollDelta.dy;
          final controller = _viewController;
          final scale = controller.scale ?? 1.0;
          final newScale = scale - delta / 1000;
          controller.scale = newScale.clamp(1.0, 10.0);
          setState(() {
            correctScaleValue = newScale.clamp(1.0, 10.0);
          });
        }
      },
      child: PhotoView.customChild(
        // enablePanAlways: true,
        // minScale: PhotoViewComputedScale.contained,
        // maxScale: PhotoViewComputedScale.covered * 10,
        basePosition: Alignment.center,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
        ),
        controller: _viewController,
        child: CachedNetworkImage(
          placeholder: (context, url) => Center(
            child: const CircularProgressIndicator(),
          ),
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
          errorWidget: (context, url, error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  '이미지를 불러올 수 없습니다',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '네트워크 연결을 확인하거나\n나중에 다시 시도해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
