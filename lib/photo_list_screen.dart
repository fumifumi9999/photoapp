import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/photo_repository.dart';
import 'package:photoapp/photo_view_screen.dart';
import 'package:photoapp/providers.dart';
import 'package:photoapp/sign_in_screen.dart';
import 'package:photoapp/photo.dart';

class PhotoListScreen extends ConsumerStatefulWidget {
  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends ConsumerState<PhotoListScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    // PageViewで表示されているWidgetの番号を持っておく

    // PageViewの表示を切り替えるのに使う
    _controller = PageController(
      initialPage: ref.read(photoListIndexProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo App'),
        actions: [
          // ログアウト用ボタン
          IconButton(
            onPressed: () => _onSignOut(),
            icon: Icon(Icons.exit_to_app),
          )
        ],
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (int index) => _onPageChanged(index),
        children: [
          //「全ての画像」を表示する部分
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              return ref.watch(photoListProvider).when(
                    data: (List<Photo> photoList) => PhotoGridView(
                      // コールバックを設定しタップした画像のURLを受け取る
                      // Cloud Firestoreから取得した画像のURL一覧を渡す
                      photoList: photoList,
                      onTap: (photo) => _onTapPhoto(photo, photoList),
                      onTapFav: (photo) => _onTapFav(photo),
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
            },
          ),
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              return ref.watch(favoritePhotoListProvider).when(
                    data: (List<Photo> photoList) => PhotoGridView(
                      photoList: photoList,
                      onTap: (photo) => _onTapPhoto(photo, photoList),
                      onTapFav: (photo) => _onTapFav(photo),
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
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddPhoto(),
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final photoIndex = ref.watch(photoListIndexProvider);
          return BottomNavigationBar(
            onTap: (int index) => _onTapBottomNavigationItem(index),
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.image),
                label: 'フォト',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'お気に入り',
              ),
            ],
          );
        },
      ),
    );
  }

  void _onPageChanged(int index) {
    ref.read(photoListIndexProvider.notifier).state = index;
  }

  void _onTapBottomNavigationItem(int index) {
    // PageViewで表示するWidgetを切り替える
    _controller.animateToPage(
      // 表示するWidgetの番号
      // 0: 全ての画像
      // 1: お気に入り登録した画像
      index,
      // 表示を切り替える時にかかる時間（300ミリ秒）
      duration: Duration(milliseconds: 300),
      // アニメーションの動き方
      // この値を変えることで、アニメーションの動きを変えることができる
      // https://api.flutter.dev/flutter/animation/Curves-class.html
      curve: Curves.easeIn,
    );
    // PageViewで表示されているWidgetの番号を更新
    ref.watch(photoListIndexProvider.notifier).state = index;
  }

  void _onTapPhoto(Photo photo, List<Photo> photoList) {
    final initialIndex = photoList.indexOf(photo);
    print("ontapphoto" + initialIndex.toString());
//    ref.read(photoViewInitialIndexProvider.notifier).state = initialIndex;

    // 最初に表示する画像のURLを指定して、画像詳細画面に切り替える
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [
            photoViewInitialIndexProvider.overrideWith((ref) => initialIndex)
          ],
          child: PhotoViewScreen(),
        ),
      ),
    );
  }

  Future<void> _onSignOut() async {
    try {
      // ログアウト処理
      await FirebaseAuth.instance.signOut();

      // ログアウトに成功したらログイン画面に戻す
      // 現在の画面は不要になるのでpushReplacementを使う
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SignInScreen(),
        ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('エラー'),
            content: Text(e.toString()),
          );
        },
      );
    }
  }

  Future<void> _onAddPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      final User user = FirebaseAuth.instance.currentUser!;
      final PhotoRepository repository = PhotoRepository(user);
      // final File file = File(result.files.single.path!);
      await repository.addPhoto(result.files.first);
    }
    /*
    // 画像ファイル選択
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, //追加
    );

    // 画像ファイルが選択された場合
    if (result != null) {
      PlatformFile platformFile = result.files.first;
      String path = utf8.decode(platformFile.bytes!);
      final File file = File(path);
      // ログイン中のユーザー情報を取得
      

      // フォルダとファイル名を指定し画像ファイルをアップロード
      final int timestamp = DateTime.now().microsecondsSinceEpoch;
      // final File file = File(result.files.single.path!);
      final String name = file.path.split('/').last;
      final String filename = '${timestamp}_$name';
      final TaskSnapshot task = await FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/photos') //フォルダ
          .child(filename) //ファイル名
          .putFile(file); //画像ファイル
    }
    */
  }

  Future<void> _onTapFav(Photo photo) async {
    final photoRepository = ref.read(photoRepositoryProvider);
    final togglePhoto = photo.toggleFavorite();
    await photoRepository!.updatePhoto(togglePhoto);
  }
}

class PhotoGridView extends StatelessWidget {
  const PhotoGridView({
    Key? key,
    required this.photoList,
    required this.onTap,
    required this.onTapFav,
  }) : super(key: key);

  final List<Photo> photoList;
  // コールバックからタップされた画像のURLを受け渡す
  final void Function(Photo photo) onTap;
  final void Function(Photo photo) onTapFav;

  @override
  Widget build(BuildContext context) {
    // GridViewを使いタイル状にWidgetを表示する
    return GridView.count(
      // 1行あたりに表示するWidgetの数
      crossAxisCount: 2,
      // Widget間のスペース（上下）
      mainAxisSpacing: 8,
      // Widget間のスペース（左右）
      crossAxisSpacing: 8,
      // 全体の余白
      padding: const EdgeInsets.all(8),
      // 画像一覧
      children: photoList.map((Photo photo) {
        // Stackを使いWidgetを前後に重ねる
        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              // Widgetをタップ可能にする
              child: InkWell(
                // タップしたらコールバックを実行する
                onTap: () => onTap(photo),
                // URLを指定して画像を表示
                child: Image.network(
                  photo.imageURL,
                  // 画像の表示の仕方を調整できる
                  // 比率は維持しつつ余白が出ないようにするのでcoverを指定
                  // https://api.flutter.dev/flutter/painting/BoxFit-class.html
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 画像の上にお気に入りアイコンを重ねて表示
            // Alignment.topRightを指定し右上部分にアイコンを表示
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => onTapFav(photo),
                color: Colors.white,
                icon: Icon(
                  photo.isFavorite == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
