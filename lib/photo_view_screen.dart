import 'package:flutter/material.dart';
import 'package:photoapp/photo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoapp/photo_repository.dart';
import 'package:photoapp/providers.dart';
import 'package:share_plus/share_plus.dart';

class PhotoViewScreen extends ConsumerStatefulWidget {
  @override
  _PhotoViewScreenState createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends ConsumerState<PhotoViewScreen> {
  late PageController _controller;
  @override
  void initState() {
    super.initState();
    print(ref.read(photoViewInitialIndexProvider));
    _controller = PageController(
      initialPage: ref.read(photoViewInitialIndexProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBarの裏までbodyの表示エリアを広げる
      extendBodyBehindAppBar: true,
      // 透明なAppBarを作る
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              int photoListIndex = ref.read(photoListIndexProvider);
              if (photoListIndex == 0) {
                return ref.watch(photoListProvider).when(
                      data: (List<Photo> photoList) =>
                          // 画像 一覧
                          PageView(
                        controller: _controller,
                        onPageChanged: (int index) => {},
                        children: photoList.map((Photo photo) {
                          return Image.network(
                            photo.imageURL,
                            fit: BoxFit.cover,
                          );
                        }).toList(),
                      ),
                      loading: () => Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, stackTrace) => Scaffold(
                        body: Center(
                          child: Text(e.toString()),
                        ),
                      ),
                    );
              } else {
                return ref.watch(favoritePhotoListProvider).when(
                      data: (List<Photo> photoList) =>
                          // 画像 一覧
                          PageView(
                        controller: _controller,
                        onPageChanged: (int index) => {},
                        children: photoList.map((Photo photo) {
                          return Image.network(
                            photo.imageURL,
                            fit: BoxFit.cover,
                          );
                        }).toList(),
                      ),
                      loading: () => Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, stackTrace) => Scaffold(
                        body: Center(
                          child: Text(e.toString()),
                        ),
                      ),
                    );
              }
            },
          ),

          // アイコンボタンを画像の手前に重ねる
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // フッター部分にグラデーションを入れてみる
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: FractionalOffset.bottomCenter,
                  end: FractionalOffset.topCenter,
                  // 半透明の黒から透明にグラデーションさせる
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 共有ボタン
                  IconButton(
                      onPressed: () => _onTapShare(),
                      color: Colors.white,
                      icon: Icon(Icons.share)),
                  // 削除ボタン
                  IconButton(
                      onPressed: () => _onTapDelete(),
                      color: Colors.white,
                      icon: Icon(Icons.delete)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTapDelete() async {
    final photoRepository = ref.read(photoRepositoryProvider);
    int photoListIndex = ref.read(photoListIndexProvider);
    final photoList;
    if (photoListIndex == 0) {
      photoList = ref.read(photoListProvider).value!;
    } else {
      photoList = ref.read(favoritePhotoListProvider).value!;
    }

    final photo = photoList[_controller.page!.toInt()];

    if (photoList.length == 1) {
      Navigator.of(context).pop();
    } else if (photoList.last == photo) {
      await _controller.previousPage(
        duration: Duration(microseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    await photoRepository!.deletePhoto(photo);
  }

  Future<void> _onTapShare() async {
    int photoListIndex = ref.read(photoListIndexProvider);
    final photoList;
    if (photoListIndex == 0) {
      photoList = ref.read(photoListProvider).value!;
    } else {
      photoList = ref.read(favoritePhotoListProvider).value!;
    }
    final photo = photoList[_controller.page!.toInt()];

    await Share.share(photo.imageURL);
  }
}
