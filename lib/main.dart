// ignore_for_file: deprecated_member_use, avoid_unnecessary_containers, unnecessary_null_comparison, unused_element

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/rendering.dart' show ViewportOffset;
import 'package:camera_deep_ar/camera_deep_ar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'config.dart';

//https://github.com/daptee/question-color-deepAr-modified.git
//https://github.com/mtellect/CameraDeepAR.git

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // CameraDeepArControllerX cameraDeepArController;
  // Effects currentEffect = Effects.none;
  // Filters currentFilter = Filters.none;
  // Masks currentMask = Masks.empty;

  var deepArController = CameraDeepArController(config);
  String _platformVersion = 'Unknown';
  CameraMode cameraMode = config.cameraMode;
  DisplayMode displayMode = config.displayMode;
  int currentEffect = 0;
  String imgSrc = '';

  List filters = [
    "none",
    "assets/drawingmanga",
    "assets/sepia",
    "assets/bleachbypass",
    "assets/realvhs",
    "assets/filmcolorperfection",
    "assets/aviators",
    "assets/bigmouth",
    "assets/lion",
    "assets/dalmatian",
    "assets/bcgseg",
    "assets/fatify",
    "assets/flowers",
    "assets/grumpycat",
    "assets/koala",
    "assets/mudmask",
    "assets/obama",
    "assets/pug",
    "assets/slash",
    "assets/sleepingmask",
    "assets/smallface",
    "assets/teddycigar",
    "assets/tripleface",
    "assets/twistedface",
    "assets/fire",
    "assets/heart",
    "assets/blizzard",
    "assets/rain"
  ];

  @override
  void initState() {
    super.initState();
    CameraDeepArController.checkPermissions();
    deepArController.setEventHandler(DeepArEventHandler(onCameraReady: (v) {
      _platformVersion = "onCameraReady $v";
      setState(() {});
    }, onSnapPhotoCompleted: (v) {
      _platformVersion = "onSnapPhotoCompleted $v";
      imgSrc = v;
      setState(() {});
    }, onVideoRecordingComplete: (v) {
      _platformVersion = "onVideoRecordingComplete $v";
      setState(() {});
    }, onSwitchEffect: (v) {
      _platformVersion = "onSwitchEffect $v";
      setState(() {});
    }));
  }

  @override
  void dispose() {
    deepArController.dispose();
    super.dispose();
  }

  void _onFilterChanged(int p) {
    if (!deepArController.value.isInitialized) return;
    currentEffect = p;
    deepArController.switchEffect(cameraMode, filters[p]);
    setState(() {});
  }

  void _onfilterSelected() {
    deepArController.snapPhoto();
  }

  _onStepCancel(BuildContext context) {
    imgSrc = '';
    setState(() {});
  }

  _onStepContinue(BuildContext context) {
    Share.shareFiles([imgSrc], text: 'Great picture', subject: 'Ynov Snap');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: DeepArPreview(deepArController),
            ),
            Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: _buildFilterSelector(),
            ),
            if (imgSrc != '')
              Positioned.fill(
                child: DisplayPictureScreen(
                  imagePath: imgSrc,
                  onStepCancel: () => _onStepCancel(context),
                  onStepContinue: () => _onStepContinue(context),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return FilterSelector(
        onFilterChanged: _onFilterChanged,
        filters: filters,
        onFilterSelected: _onfilterSelected);
  }

  static Future<File> _loadFile(String path, String name) async {
    final ByteData data = await rootBundle.load(path);
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/$name');
    await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return tempFile;
  }
}

@immutable
class FilterSelector extends StatefulWidget {
  const FilterSelector({
    Key? key,
    required this.filters,
    required this.onFilterChanged,
    required this.onFilterSelected,
    this.padding = const EdgeInsets.symmetric(vertical: 24.0),
  }) : super(key: key);

  final List filters;
  final void Function(int p) onFilterChanged;
  final void Function() onFilterSelected;
  final EdgeInsets padding;

  @override
  _FilterSelectorState createState() => _FilterSelectorState();
}

class _FilterSelectorState extends State<FilterSelector> {
  static const _filtersPerScreen = 5;
  static const _viewportFractionPerItem = 1.0 / _filtersPerScreen;

  late final PageController _controller;
  late int _page;

  int get filterCount => widget.filters.length;

  String itemColor(int index) => widget.filters[index % filterCount];

  @override
  void initState() {
    super.initState();
    _page = 0;
    _controller = PageController(
      initialPage: _page,
      viewportFraction: _viewportFractionPerItem,
    );
    _controller.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = (_controller.page ?? 0).round();
    if (page != _page) {
      _page = page;
      widget.onFilterChanged(page);
    }
  }

  void _onFilterTapped(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollable(
      controller: _controller,
      axisDirection: AxisDirection.right,
      physics: const PageScrollPhysics(),
      viewportBuilder: (context, viewportOffset) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final itemSize = constraints.maxWidth * _viewportFractionPerItem;
            viewportOffset
              ..applyViewportDimension(constraints.maxWidth)
              ..applyContentDimensions(0.0, itemSize * (filterCount - 1));

            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _buildShadowGradient(itemSize),
                _buildCarousel(
                  viewportOffset: viewportOffset,
                  itemSize: itemSize,
                ),
                _buildSelectionRing(itemSize),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShadowGradient(double itemSize) {
    return SizedBox(
      height: itemSize * 2 + widget.padding.vertical,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
            ],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }

  Widget _buildCarousel({
    required ViewportOffset viewportOffset,
    required double itemSize,
  }) {
    return Container(
      height: itemSize,
      margin: widget.padding,
      child: Flow(
        delegate: CarouselFlowDelegate(
          viewportOffset: viewportOffset,
          filtersPerScreen: _filtersPerScreen,
        ),
        children: [
          for (int i = 0; i < filterCount; i++)
            FilterItem(
              onFilterSelected: () => _onFilterTapped(i),
              color: itemColor(i),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionRing(double itemSize) {
    return GestureDetector(
      onTap: widget.onFilterSelected,
      child: Padding(
        padding: widget.padding,
        child: SizedBox(
          width: itemSize,
          height: itemSize,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(width: 6.0, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CarouselFlowDelegate extends FlowDelegate {
  CarouselFlowDelegate({
    required this.viewportOffset,
    required this.filtersPerScreen,
  }) : super(repaint: viewportOffset);

  final ViewportOffset viewportOffset;
  final int filtersPerScreen;

  @override
  void paintChildren(FlowPaintingContext context) {
    final count = context.childCount;

    // All available painting width
    final size = context.size.width;

    // The distance that a single item "page" takes up from the perspective
    // of the scroll paging system. We also use this size for the width and
    // height of a single item.
    final itemExtent = size / filtersPerScreen;

    // The current scroll position expressed as an item fraction, e.g., 0.0,
    // or 1.0, or 1.3, or 2.9, etc. A value of 1.3 indicates that item at
    // index 1 is active, and the user has scrolled 30% towards the item at
    // index 2.
    final active = viewportOffset.pixels / itemExtent;

    // Index of the first item we need to paint at this moment.
    // At most, we paint 3 items to the left of the active item.
    final min = math.max(0, active.floor() - 3).toInt();

    // Index of the last item we need to paint at this moment.
    // At most, we paint 3 items to the right of the active item.
    final max = math.min(count - 1, active.ceil() + 3).toInt();

    // Generate transforms for the visible items and sort by distance.
    for (var index = min; index <= max; index++) {
      final itemXFromCenter = itemExtent * index - viewportOffset.pixels;
      final percentFromCenter = 1.0 - (itemXFromCenter / (size / 2)).abs();
      final itemScale = 0.5 + (percentFromCenter * 0.5);
      final opacity = 0.25 + (percentFromCenter * 0.75);

      final itemTransform = Matrix4.identity()
        ..translate((size - itemExtent) / 2)
        ..translate(itemXFromCenter)
        ..translate(itemExtent / 2, itemExtent / 2)
        ..multiply(Matrix4.diagonal3Values(itemScale, itemScale, 1.0))
        ..translate(-itemExtent / 2, -itemExtent / 2);

      context.paintChild(
        index,
        transform: itemTransform,
        opacity: opacity,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CarouselFlowDelegate oldDelegate) {
    return oldDelegate.viewportOffset != viewportOffset;
  }
}

@immutable
class FilterItem extends StatelessWidget {
  const FilterItem({
    Key? key,
    required this.color,
    this.onFilterSelected,
  }) : super(key: key);

  final String color;
  final VoidCallback? onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFilterSelected,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: Image.network(
              'https://docs.flutter.dev/cookbook/img-files/effects/instagram-buttons/millenial-texture.jpg',
              color: Colors.blue.withOpacity(0.5),
              colorBlendMode: BlendMode.hardLight,
            ),
          ),
        ),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final void Function() onStepCancel;
  final void Function() onStepContinue;

  const DisplayPictureScreen(
      {Key? key,
      required this.imagePath,
      required this.onStepCancel,
      required this.onStepContinue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Image.file(File(imagePath)),
        Container(
          color: Colors.white,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FlatButton(
                onPressed: onStepCancel,
                child: const Text('Retour'),
              ),
              FlatButton(
                onPressed: onStepContinue,
                child: const Text('Partager'),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
