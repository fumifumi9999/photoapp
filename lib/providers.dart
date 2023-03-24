import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoapp/photo.dart';
import 'package:photoapp/Photo_repository.dart';

final userProvider = StreamProvider.autoDispose((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final photoListProvider = StreamProvider.autoDispose((ref) {
  //autoDisposeは自動的にメモリを開放するProvider
  final photoRepository = ref.watch(photoRepositoryProvider);
  return photoRepository == null
      ? Stream.value(<Photo>[]) //Streamは一度だけ値を流す単一イベントを生成する
      : photoRepository.getPhotoList();
});

final photoListIndexProvider = StateProvider.autoDispose((ref) {
  return 0;
});

final photoViewInitialIndexProvider = StateProvider.autoDispose((ref) {
  return 0;
});

final photoRepositoryProvider = Provider.autoDispose((ref) {
  final User? user = ref.watch(userProvider).value;
  return user == null ? null : PhotoRepository(user);
});

final favoritePhotoListProvider = Provider.autoDispose((ref) {
  return ref.watch(photoListProvider).whenData((List<Photo> data) {
    return data.where((photo) => photo.isFavorite == true).toList();
  });
});
