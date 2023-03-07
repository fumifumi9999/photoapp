import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:photoapp/sign_in_screen.dart';
import 'package:photoapp/photo_list_screen.dart';

import 'package:photoapp/providers.dart';

void main() async {
  // Flutterの初期化処理を待つ
  WidgetsFlutterBinding.ensureInitialized();

  // アプリ起動前にFirebase初期化処理を入れる
  // initializeApp()の返り値がFutureなので非同期処理
  // 非同期処理(Future)はawaitで処理が終わるのを待つことができる
  // ただし、awaitを使うときは関数にasyncを付ける必要がある
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) =>
            ref.watch(userProvider).when(
                  data: (User? data) =>
                      data == null ? SignInScreen() : PhotoListScreen(),
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
                ),
      ),
    );
  }
}
