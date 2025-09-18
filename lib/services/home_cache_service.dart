import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeCacheService {
  static const String _cacheKeyPrefix = 'home_cache_';
  static const String _cacheTimePrefix = 'home_cache_time_';
  static const String _categoryDataKey = 'category_data_cache';
  static const String _categoryDataTimeKey = 'category_data_cache_time';
  
  // Thời gian cache (phút)
  static const int _cacheExpireMinutes = 15;

  /// Lưu dữ liệu sản phẩm theo categoryId vào cache
  static Future<void> cacheProducts(int categoryId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$categoryId';
      final timeKey = '$_cacheTimePrefix$categoryId';
      
      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Đã cache dữ liệu cho categoryId: $categoryId');
    } catch (e) {
      print('❌ Lỗi khi cache dữ liệu: $e');
    }
  }

  /// Lấy dữ liệu sản phẩm từ cache theo categoryId
  static Future<Map<String, dynamic>?> getCachedProducts(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$categoryId';
      final timeKey = '$_cacheTimePrefix$categoryId';
      
      final cachedData = prefs.getString(cacheKey);
      final cacheTime = prefs.getInt(timeKey);
      
      if (cachedData == null || cacheTime == null) {
        return null;
      }
      
      // Kiểm tra thời gian hết hạn
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = (now - cacheTime) / (1000 * 60); // Đổi ra phút
      
      if (timeDiff > _cacheExpireMinutes) {
        print('⏰ Cache đã hết hạn cho categoryId: $categoryId');
        await clearCachedProducts(categoryId);
        return null;
      }
      
      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      print('✅ Đã lấy dữ liệu cache cho categoryId: $categoryId');
      return data;
    } catch (e) {
      print('❌ Lỗi khi lấy cache: $e');
      return null;
    }
  }

  /// Xóa cache cho categoryId cụ thể
  static Future<void> clearCachedProducts(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$categoryId';
      final timeKey = '$_cacheTimePrefix$categoryId';
      
      await prefs.remove(cacheKey);
      await prefs.remove(timeKey);
      
      print('🗑️ Đã xóa cache cho categoryId: $categoryId');
    } catch (e) {
      print('❌ Lỗi khi xóa cache: $e');
    }
  }

  /// Lưu dữ liệu danh mục vào cache
  static Future<void> cacheCategoryData(Map<String, dynamic> categoryData, List<int> dynamicCategoryIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final data = {
        'categoryData': categoryData,
        'dynamicCategoryIds': dynamicCategoryIds,
      };
      
      await prefs.setString(_categoryDataKey, jsonEncode(data));
      await prefs.setInt(_categoryDataTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Đã cache dữ liệu danh mục');
    } catch (e) {
      print('❌ Lỗi khi cache dữ liệu danh mục: $e');
    }
  }

  /// Lấy dữ liệu danh mục từ cache
  static Future<Map<String, dynamic>?> getCachedCategoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cachedData = prefs.getString(_categoryDataKey);
      final cacheTime = prefs.getInt(_categoryDataTimeKey);
      
      if (cachedData == null || cacheTime == null) {
        return null;
      }
      
      // Kiểm tra thời gian hết hạn (danh mục cache lâu hơn - 60 phút)
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = (now - cacheTime) / (1000 * 60); // Đổi ra phút
      
      if (timeDiff > 60) {
        print('⏰ Cache danh mục đã hết hạn');
        await clearCachedCategoryData();
        return null;
      }
      
      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      print('✅ Đã lấy dữ liệu danh mục từ cache');
      return data;
    } catch (e) {
      print('❌ Lỗi khi lấy cache danh mục: $e');
      return null;
    }
  }

  /// Xóa cache danh mục
  static Future<void> clearCachedCategoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_categoryDataKey);
      await prefs.remove(_categoryDataTimeKey);
      
      print('🗑️ Đã xóa cache danh mục');
    } catch (e) {
      print('❌ Lỗi khi xóa cache danh mục: $e');
    }
  }

  /// Xóa toàn bộ cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (String key in keys) {
        if (key.startsWith(_cacheKeyPrefix) || 
            key.startsWith(_cacheTimePrefix) ||
            key == _categoryDataKey ||
            key == _categoryDataTimeKey) {
          await prefs.remove(key);
        }
      }
      
      print('🗑️ Đã xóa toàn bộ cache home');
    } catch (e) {
      print('❌ Lỗi khi xóa toàn bộ cache: $e');
    }
  }

  /// Kiểm tra xem có cache cho categoryId hay không
  static Future<bool> hasCachedProducts(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$categoryId';
      final timeKey = '$_cacheTimePrefix$categoryId';
      
      final cachedData = prefs.getString(cacheKey);
      final cacheTime = prefs.getInt(timeKey);
      
      if (cachedData == null || cacheTime == null) {
        return false;
      }
      
      // Kiểm tra thời gian hết hạn
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = (now - cacheTime) / (1000 * 60);
      
      return timeDiff <= _cacheExpireMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Lấy thông tin về cache hiện tại
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      List<Map<String, dynamic>> cachedCategories = [];
      bool hasCategoryData = false;
      
      for (String key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          final categoryId = key.replaceFirst(_cacheKeyPrefix, '');
          final timeKey = '$_cacheTimePrefix$categoryId';
          final cacheTime = prefs.getInt(timeKey);
          
          if (cacheTime != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final timeDiff = (now - cacheTime) / (1000 * 60);
            final isExpired = timeDiff > _cacheExpireMinutes;
            
            cachedCategories.add({
              'categoryId': int.tryParse(categoryId) ?? 0,
              'cacheTime': DateTime.fromMillisecondsSinceEpoch(cacheTime),
              'minutesAgo': timeDiff.round(),
              'isExpired': isExpired,
            });
          }
        } else if (key == _categoryDataKey) {
          hasCategoryData = true;
        }
      }
      
      return {
        'cachedCategories': cachedCategories,
        'hasCategoryData': hasCategoryData,
        'totalCachedItems': cachedCategories.length,
      };
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin cache: $e');
      return {
        'cachedCategories': [],
        'hasCategoryData': false,
        'totalCachedItems': 0,
      };
    }
  }
}





