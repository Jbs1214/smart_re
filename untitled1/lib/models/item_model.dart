// item_model.dart

class Item {
  final String name;
  final String description;
  final String imageUrl;

  Item({required this.name, required this.description, required this.imageUrl});

  factory Item.fromJson(Map<dynamic, dynamic> json) {
    return Item(
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}
