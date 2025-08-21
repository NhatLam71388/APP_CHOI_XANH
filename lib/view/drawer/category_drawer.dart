import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/widgets/widget_auth.dart';
import 'package:http/http.dart' as http;

class DanhMucDrawer extends StatelessWidget {
  final void Function(int) onCategorySelected;
  DanhMucDrawer({required this.onCategorySelected});

  Future<List<dynamic>> fetchDanhMuc() async {
    // [THAY_DOI_1]: Sử dụng URL API mới
    final response = await http.get(Uri.parse('${APIService.baseUrl}/ww2/app.menu.dautrang.asp'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // [THAY_DOI_2]: API mới trả về trực tiếp danh sách, không cần json[0]['data']
      // Chuyển đổi và lọc dữ liệu để tương thích với logic hiện tại
      return json
          .where((item) => !['Test 3 cấp', 'Thành viên đăng nhập', 'Tìm kiếm'].contains(item['tieude']))
          .map((item) => {
        'id': item['idpart'], // [THAY_DOI_3]: Sử dụng 'idpart' thay vì 'id'
        'tieude': item['tieude'],
        'children': item['menucap1'] ?? [], // [THAY_DOI_4]: Sử dụng 'menucap1' thay vì 'children'
      })
          .toList();
    } else {
      throw Exception('Không thể tải danh mục');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top;

    return Drawer(
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              height: appBarHeight,
              width: double.infinity,
              color: Color(0xFF198754),
              child: Stack(
                children: [
                  Center(
                    child: Image.asset(
                      'asset/logoapp.png',
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.keyboard_double_arrow_left,
                          color: Colors.white70, size: 30),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: fetchDanhMuc(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }

                  final danhMucList = snapshot.data ?? [];

                  return ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      ...danhMucList.map((item) {
                        final id = item['id'];
                        final title = item['tieude'];
                        final children = item['children'] ?? [];

                        if (children.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF198754).withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF198754).withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                            onTap: () {
                              onCategorySelected(
                                  int.tryParse(id.toString()) ?? 0);
                              Navigator.of(context).pop();
                            },
                                borderRadius: BorderRadius.circular(12),
                                splashColor: const Color(0xFF198754).withOpacity(0.1),
                                highlightColor: const Color(0xFF198754).withOpacity(0.05),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF198754).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.category_outlined,
                                          size: 20,
                                          color: const Color(0xFF198754),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          title ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1a1a1a),
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: const Color(0xFF198754).withOpacity(0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF198754).withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF198754).withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                              iconColor: const Color(0xFF198754),
                              collapsedIconColor: const Color(0xFF198754),
                            title: InkWell(
                              onTap: () {
                                onCategorySelected(
                                    int.tryParse(id.toString()) ?? 0);
                                Navigator.of(context).pop();
                              },
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF198754).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.folder_outlined,
                                        size: 20,
                                        color: const Color(0xFF198754),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        title ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1a1a1a),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ),
                            children: children.map<Widget>((subItem) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF198754).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF198754).withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                onTap: () {
                                        final id = subItem['idpart'];
                                  onCategorySelected(
                                      int.tryParse(id.toString()) ?? 0);
                                  Navigator.of(context).pop();
                                },
                                      borderRadius: BorderRadius.circular(8),
                                      splashColor: const Color(0xFF198754).withOpacity(0.1),
                                      highlightColor: const Color(0xFF198754).withOpacity(0.05),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF198754).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.subdirectory_arrow_right,
                                                size: 16,
                                                color: const Color(0xFF198754),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                subItem['tieude'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF1a1a1a),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: const Color(0xFF198754).withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              );
                            }).toList(),
                            ),
                          );
                        }
                      }),
                      const SizedBox(height: 24),
                      Divider(thickness: 1),
                      const SizedBox(height: 12),
                      _buildCompanyInfo(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Chồi Xanh Media ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF198754),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                  'cung cấp các loại máy tính, laptop và thiết bị công nghệ chất lượng cao, đáp ứng mọi nhu cầu của doanh nghiệp và cá nhân.',
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.3,
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        _InfoRow(icon: Icons.apartment, text: 'Công ty Chồi Xanh Media'),
        SizedBox(height: 12),
        _InfoRow(
            icon: Icons.location_on, text: '82A - 82B Dân Tộc, Q. Tân Phú'),
        SizedBox(height: 12),
        _InfoRow(icon: Icons.document_scanner, text: 'MST: 0314581926'),
        SizedBox(height: 12),
        _InfoRow(icon: Icons.phone, text: '028 3974 3179'),
        SizedBox(height: 12),
        _InfoRow(icon: Icons.email, text: 'info@choixanh.vn'),
        SizedBox(height: 12),
        _InfoRow(icon: Icons.share, text: 'Theo dõi Chồi Xanh Media'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: Color(0xFF198754),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}