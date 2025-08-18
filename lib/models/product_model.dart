class CartItemModel {
  final String id;
  final String idbg; // Thêm trường idbg
  final String name;
  final String image;
  final double price;
  final String moduleType;
  int quantity;
  bool isSelect;
  final int categoryId;

  CartItemModel({
    required this.id,
    required this.idbg, // Thêm idbg vào constructor
    required this.name,
    required this.image,
    required this.price,
    required this.moduleType,
    required this.quantity,
    this.isSelect = false,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idbg': idbg, // Thêm idbg vào JSON
      'name': name,
      'image': image,
      'price': price,
      'moduleType': moduleType,
      'quantity': quantity,
      'isSelect': isSelect,
      'categoryId': categoryId,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'].toString(),
      idbg: json['idbg']?.toString() ?? '', // Ánh xạ idbg từ JSON
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      moduleType: json['moduleType'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      isSelect: json['isSelect'] ?? false,
      categoryId: int.tryParse(json['categoryId']?.toString() ?? '0') ?? 0,
    );
  }
}