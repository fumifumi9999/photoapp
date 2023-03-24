import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/photo.dart';

class PhotoRepository {
  PhotoRepository(this.user);

  final User user;

  Stream<List<Photo>> getPhotoList() {
    return FirebaseFirestore.instance
        .collection('users/${user.uid}/photos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_queryToPhotoList);
  }

  Future<void> addPhoto(PlatformFile file) async {
    Uint8List fileBytes = file.bytes!;
    String name = file.name;
    final int timestamp = DateTime.now().microsecondsSinceEpoch;
    final String path = '${timestamp}_$name';
    final TaskSnapshot task = await FirebaseStorage.instance
        .ref()
        .child('users/${user.uid}/photos') //フォルダ
        .child(path) //ファイル名
        .putData(fileBytes); //画像ファイル

    // アップロードした画像のURLを取得
    final String imageURL = await task.ref.getDownloadURL();
    // アップロードした画像の保存先を取得
    final String imagePath = task.ref.fullPath;
    final Photo photo = Photo(
      imageURL: imageURL,
      imagePath: imagePath,
      isFavorite: false, // お気に入り登録
      createdAt: Timestamp.now().toDate(), //現在時刻
    );

    // データをCloud Firestoreに保存
    await FirebaseFirestore.instance
        .collection('users/${user.uid}/photos') //コレクション
        .doc() // ドキュメント（何も指定しない場合は自動的にIDが決まる）
        .set(_photoToMap(photo)); // データ
  }

  List<Photo> _queryToPhotoList(QuerySnapshot query) {
    return query.docs.map((doc) {
      return Photo(
        id: doc.id,
        imageURL: doc.get('imageURL'),
        imagePath: doc.get('imagePath'),
        isFavorite: doc.get('isFavorite'),
        createdAt: (doc.get('createdAt') as Timestamp).toDate(),
      );
    }).toList();
  }

  Map<String, dynamic> _photoToMap(Photo photo) {
    return {
      'imageURL': photo.imageURL,
      'imagePath': photo.imagePath,
      'isFavorite': photo.isFavorite,
      'createdAt': photo.createdAt == null
          ? Timestamp.now()
          : Timestamp.fromDate(photo.createdAt!)
    };
  }

  Future<void> deletePhoto(Photo photo) async {
    // Cloud Firestoreのデータを削除
    await FirebaseFirestore.instance
        .collection('users/${user.uid}/photos') //コレクション
        .doc(photo.id)
        .delete();

    // Storageの画像ファイルを削除
    await FirebaseStorage.instance.ref().child(photo.imagePath).delete();
  }

  Future<void> updatePhoto(Photo photo) async {
    // Cloud Firestoreのデータを削除
    await FirebaseFirestore.instance
        .collection('users/${user.uid}/photos') //コレクション
        .doc(photo.id)
        .update(_photoToMap(photo));
  }
}
