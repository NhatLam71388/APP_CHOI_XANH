import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/favourite_service.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/hieuung_card.dart';

class favouritePage extends StatefulWidget {
  final Function(dynamic) onProductTap;
  final VoidCallback? onFavouriteToggle;
  final GlobalKey<favouritePageState> key;

  const favouritePage({
    required this.onProductTap,
    this.onFavouriteToggle,
    required this.key,
  }) : super(key: key);

  @override
  favouritePageState createState() => favouritePageState();
}

class favouritePageState extends State<favouritePage> {
  List<Map<String, dynamic>> wishlistItems = [];
  bool isLoading = true;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    reloadFavourites();
  }

  Future<void> reloadFavourites() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('emailAddress') ?? '';
    final password = prefs.getString('passWord') ?? '';
    final items = await APIFavouriteService.fetchWishlistItems(
      userId: userId.isNotEmpty ? userId : null,
      password: userId.isNotEmpty ? password : null,
    );
    setState(() {
      wishlistItems = items;
      isLoading = false;
    });
  }

  Future<void> _toggleFavourite(Map<String, dynamic> item, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('emailAddress') ?? '';
    final password = prefs.getString('passWord') ?? '';

    final result = await APIFavouriteService.toggleFavourite(
      context: context,
      userId: userId.isNotEmpty ? userId : null,
      password: userId.isNotEmpty ? password : null,
      id: item['id'] is String ? int.parse(item['id']) : item['id'],
      idbg: item['idbg'],
      tieude: item['tieude'],
      gia: item['gia'].toString(),
      hinhdaidien: item['hinhdaidien'],
      moduleType: item['moduleType'],
    );

    if (result is bool && !result) {
      final removedItem = wishlistItems[index];
      wishlistItems.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
            (context, animation) => _buildItem(removedItem, animation),
        duration: const Duration(milliseconds: 300),
      );
      if (widget.onFavouriteToggle != null) {
        widget.onFavouriteToggle!();
      }
    }
  }

  Widget _buildItem(Map<String, dynamic> item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axis: Axis.vertical,
      child: GlowingCard(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12, width: 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item['hinhdaidien'].startsWith('assets/')
                      ? Image.asset(
                    item['hinhdaidien'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  )
                      : Image.network(
                    item['hinhdaidien'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/placeholder.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['tieude'] ?? 'Không có tên',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giá: ${formatCurrency(item['gia'])}₫',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _toggleFavourite(item, wishlistItems.indexOf(item)),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        color: const Color(0xff0066FF),
        onRefresh: reloadFavourites,
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xff0066FF)))
              : wishlistItems.isEmpty
              ? const Center(child: Text('Danh sách yêu thích trống'))
              : AnimatedList(
            key: _listKey,
            initialItemCount: wishlistItems.length,
            itemBuilder: (context, index, animation) =>
                _buildItem(wishlistItems[index], animation),
          ),
        ),
      ),
    );
  }
}

String formatCurrency(dynamic price) {
  try {
    final doublePrice = price is String ? double.parse(price) : price.toDouble();
    return doublePrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  } catch (e) {
    return price?.toString() ?? '0';
  }
}