import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/screens/layout/layout.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../Controller/home.dart';

class AuthService {
  static late CookieJar cookieJar;

  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage("${appDir.path}/cookies"),
    );
  }

  static Future<Map<String, String?>> fetchCookies() async {
    try {
      final url = Uri.parse('${APIService.baseUrl}/ww1/cookie.mabaogia.asp');
      final cookies = await cookieJar.loadForRequest(url);
      final headers = {
        'Accept': 'application/json',
        if (cookies.isNotEmpty) 'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
      };
      print('Cookie request headers: $headers');
      final response = await http.get(url, headers: headers).timeout(Duration(seconds: 5));

      print('Cookie response status: ${response.statusCode}');
      print('Cookie response body: ${response.body}');

      if (response.headers.containsKey('set-cookie')) {
        await cookieJar.saveFromResponse(url, [
          Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]),
        ]);
      }

      if (response.statusCode == 200) {
        final cookieData = json.decode(response.body);
        if (cookieData is List && cookieData.isNotEmpty) {
          final dathangMabaogia = cookieData.firstWhere(
                (item) => item['DathangMabaogia'] != null,
            orElse: () => {'DathangMabaogia': ''},
          )['DathangMabaogia'] as String;

          final wishlistMabaogia = cookieData.firstWhere(
                (item) => item['WishlistMabaogia'] != null,
            orElse: () => {'WishlistMabaogia': ''},
          )['WishlistMabaogia'] as String;

          final prefs = await SharedPreferences.getInstance();
          if (dathangMabaogia.isNotEmpty) {
            await prefs.setString('cartCookie', dathangMabaogia);
          }
          if (wishlistMabaogia.isNotEmpty) {
            await prefs.setString('wishlistCookie', wishlistMabaogia);
          }

          return {
            'DathangMabaogia': dathangMabaogia.isNotEmpty ? dathangMabaogia : null,
            'WishlistMabaogia': wishlistMabaogia.isNotEmpty ? wishlistMabaogia : null,
          };
        }
      }
      print('Không lấy được cookie');
      return {'DathangMabaogia': null, 'WishlistMabaogia': null};
    } catch (e) {
      print('Lỗi lấy cookie: $e');
      return {'DathangMabaogia': null, 'WishlistMabaogia': null};
    }
  }

  static Future<Map<String, dynamic>?> _login(String username, String password) async {
    try {
      final url = Uri.parse('${APIService.loginUrl}?userid=$username&pass=$password');
      print('Login URL: $url');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(Duration(seconds: 5));

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      //print('Login response headers: ${response.headers}');

      if (response.headers.containsKey('set-cookie')) {
        await cookieJar.saveFromResponse(url, [
          Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]),
        ]);
      }

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is List && body.isNotEmpty && body[0]['maloi'] == "1") {
          return {
            'CustomerID': body[0]['memberid']?.toString() ?? '',
            'CustomerName': body[0]['user']?.toString() ?? '',
            'MaKH': body[0]['MaKH']?.toString() ?? '',
          };
        } else {
          print('Lỗi đăng nhập: ${body[0]['ThongBao'] ?? 'No message provided'}');
          return null;
        }
      } else {
        print('Lỗi server: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return null;
    }
  }

  static String generateMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  static Future<void> handleLogin(BuildContext context, String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      showToast('Vui lòng nhập đầy đủ thông tin', backgroundColor: Colors.red);
      return;
    }

    var userData = await _login(username, password);

    if (userData != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('customerID', userData['CustomerID']);
      await prefs.setString('customerName', userData['CustomerName']);
      await prefs.setString('maKH', userData['MaKH']);
      await prefs.setString('emailAddress', username);
      await prefs.setString('passWord', password);

      // Cập nhật Global variables
      Global.email = username;
      Global.pass = password;
      Global.name = userData['CustomerName'] ?? '';

      final cookies = await fetchCookies();
      if (cookies['DathangMabaogia'] != null) {
        print('Saved cart cookie: ${cookies['DathangMabaogia']}');
      }
      if (cookies['WishlistMabaogia'] != null) {
        print('Saved wishlist cookie: ${cookies['WishlistMabaogia']}');
      }

      print('Đăng nhập thành công: $username && mật khẩu: $password');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AllPageView()),
            (route) => false,
      );
    } else {
      CustomSnackBar.showError(context, message: 'Đăng nhập không thành công');
    }
  }

  static Future<void> handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('isLoggedIn');
    await prefs.remove('emailAddress');
    await prefs.remove('passWord');
    await prefs.remove('customerName');
    await prefs.remove('customerID');
    await prefs.remove('maKH');
    await prefs.remove('cartCookie');
    await prefs.remove('wishlistCookie');
    await cookieJar.deleteAll();

    Global.name = '';
    Global.email = '';
    Global.pass = '';

    print('== Đã đăng xuất và xóa dữ liệu ==');
    print('isLoggedIn: ${prefs.getBool('isLoggedIn')}');
    print('emailAddress: ${prefs.getString('emailAddress')}');
    print('passWord: ${prefs.getString('passWord')}');
    print('customerName: ${prefs.getString('customerName')}');
    print('cartCookie: ${prefs.getString('cartCookie')}');
    print('wishlistCookie: ${prefs.getString('wishlistCookie')}');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AllPageView()),
          (route) => false,
    );
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('emailAddress') ?? '';
  }

  static Future<String> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('passWord') ?? '';
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  static Future<void> handleGoogleLogin(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.standard();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        showToast('Đăng nhập Google bị hủy', backgroundColor: Colors.orange);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('customerID', user.uid);
        await prefs.setString('customerName', user.displayName ?? '');
        await prefs.setString('maKH', '');
        await prefs.setString('emailAddress', user.email ?? '');
        await prefs.setString('passWord', '');

        final cookies = await fetchCookies();
        if (cookies['DathangMabaogia'] != null) {
          print('Saved cart cookie for Google login: ${cookies['DathangMabaogia']}');
        }
        if (cookies['WishlistMabaogia'] != null) {
          print('Saved wishlist cookie for Google login: ${cookies['WishlistMabaogia']}');
        }

        print('Đăng nhập Google thành công: ${user.displayName} (${user.email})');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AllPageView()),
              (route) => false,
        );
      } else {
        showToast('Đăng nhập Google thất bại', backgroundColor: Colors.red);
      }
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      showToast('Có lỗi khi đăng nhập Google', backgroundColor: Colors.red);
    }
  }
}