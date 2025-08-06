class CartItemModel {
  final String id;
  final String name;
  final String image;
  final double price;
  final String moduleType;
  int quantity;
  bool isSelect;
  final int categoryId; // Thêm thuộc tính này
  

  CartItemModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.moduleType,
    required this.quantity,
    this.isSelect = false,
    required this.categoryId, // Thêm tham số
    
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'moduleType': moduleType,
      'quantity': quantity,
      'isSelect': isSelect,
      'categoryId': categoryId, // Thêm vào JSON
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      moduleType: json['moduleType'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      isSelect: json['isSelect'] ?? false,
      categoryId: int.tryParse(json['categoryId']?.toString() ?? '0') ?? 0, // Thêm ánh xạ
    );
  }
}