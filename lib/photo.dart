class Photo {
  Photo({
    this.id,
    required this.imageURL,
    required this.imagePath,
    required this.isFavorite,
    this.createdAt,
  });

  final String? id;
  final String imageURL;
  final String imagePath;
  final bool isFavorite;
  final DateTime? createdAt;

  Photo toggleFavorite() {
    return Photo(
      id: id,
      imageURL: imageURL,
      imagePath: imagePath,
      isFavorite: !isFavorite,
      createdAt: createdAt,
    );
  }
}
