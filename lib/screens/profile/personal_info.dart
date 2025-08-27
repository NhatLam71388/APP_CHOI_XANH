import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/personal_info_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_service.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => PersonalInfoPageState();
}

class PersonalInfoPageState extends State<PersonalInfoPage> {
  PersonalInfoModel? personalInfo;
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  
  // Controllers for form fields
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _loadPersonalInfo();
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPersonalInfo() async {
    try {
      setState(() {
        isLoading = true;
        isError = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('emailAddress') ?? '';
      final password = prefs.getString('passWord') ?? '';
      final customerId = prefs.getString('customerID') ?? '';

      if (email.isEmpty || password.isEmpty || customerId.isEmpty) {
        throw Exception('Thông tin đăng nhập không đầy đủ');
      }

      final md5Password = AuthService.generateMd5(password);
      final url = Uri.parse(
        '${APIService.baseUrl}/ww1/member.1/Quanlythongtin.asp?userid=$email&pass=$md5Password&mql=Quanlythongtin&id=$customerId'
      );

      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isNotEmpty && data[0]['maloi'] == '1') {
          final info = PersonalInfoModel.fromJson(data[0]);
          setState(() {
            personalInfo = info;
            isLoading = false;
          });
          
          // Initialize controllers and focus nodes for editable fields
          _initializeFormFields();
        } else {
          throw Exception(data.isNotEmpty ? data[0]['ThongBao'] ?? 'Lỗi không xác định' : 'Dữ liệu trống');
        }
      } else {
        throw Exception('Lỗi kết nối: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString();
      });
      print('Error loading personal info: $e');
    }
  }

  void _initializeFormFields() {
    if (personalInfo == null) return;

    // Initialize controllers for thongtinthanhvien fields
    for (var item in personalInfo!.thongtinthanhvien) {
      final cauhinh = item.cauhinh;
      // Initialize controllers for editable fields
      if (cauhinh.isEditable && cauhinh.kieu != 'hidden' && cauhinh.kieu != 'file') {
        final key = item.tennhom.isNotEmpty ? item.tennhom : cauhinh.tieude;
        _controllers[key] = TextEditingController(text: cauhinh.giatri);
        _focusNodes[key] = FocusNode();
      }
      // Also initialize controllers for read-only fields that we want to display
      else if (cauhinh.kieu != 'hidden' && cauhinh.kieu != 'file' && 
               (item.tennhom == 'nganhang' || item.tennhom == 'email' || 
                item.tennhom == 'dienthoai')) {
        final key = item.tennhom.isNotEmpty ? item.tennhom : cauhinh.tieude;
        _controllers[key] = TextEditingController(text: cauhinh.giatri);
        _focusNodes[key] = FocusNode();
      }
    }

    // Initialize controllers for bolocthanhvien fields (Quận huyện, Phường xã)
    for (var item in personalInfo!.bolocthanhvien) {
      final cauhinh = item.cauhinh;
      if (cauhinh.kieu != 'hidden' && cauhinh.kieu != 'file') {
        final key = item.tennhom.isNotEmpty ? item.tennhom : cauhinh.tieude;
        _controllers[key] = TextEditingController(text: cauhinh.giatri);
        _focusNodes[key] = FocusNode();
      }
    }
  }

  Widget _buildFormField(ThongTinThanhVien item) {
    final cauhinh = item.cauhinh;
    final key = item.tennhom.isNotEmpty ? item.tennhom : cauhinh.tieude;
    
    // Skip hidden fields
    if (cauhinh.kieu == 'hidden') {
      return const SizedBox.shrink();
    }

    // Handle different field types
    switch (cauhinh.kieu) {
      case 'inputtext':
      case 'inputemail':
      case 'inputtel':
        return _buildTextInputField(key, cauhinh);
      case 'inputdate':
        return _buildDateField(key, cauhinh);
      case 'file':
        return _buildFileField(key, cauhinh);
      case 'text':
        return _buildInfoText(cauhinh);
      case 'dropdown':
        return _buildDropdownField(key, cauhinh);
      default:
        return _buildTextInputField(key, cauhinh);
    }
  }

  Widget _buildFilterField(BoLocThanhVien item) {
    final cauhinh = item.cauhinh;
    final key = item.tennhom.isNotEmpty ? item.tennhom : cauhinh.tieude;
    
    // Skip hidden fields
    if (cauhinh.kieu == 'hidden') {
      return const SizedBox.shrink();
    }

    // Handle different field types
    switch (cauhinh.kieu) {
      case 'inputtext':
      case 'inputemail':
      case 'inputtel':
        return _buildTextInputField(key, cauhinh);
      case 'inputdate':
        return _buildDateField(key, cauhinh);
      case 'file':
        return _buildFileField(key, cauhinh);
      case 'text':
        return _buildInfoText(cauhinh);
      case 'dropdown':
        return _buildDropdownField(key, cauhinh);
      default:
        return _buildTextInputField(key, cauhinh);
    }
  }

  Widget _buildTextInputField(String key, CauHinh cauhinh) {
    final controller = _controllers[key];
    final focusNode = _focusNodes[key];
    
    if (controller == null || focusNode == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cauhinh.isEditable ? Colors.grey[200]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cauhinh.tieude,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (cauhinh.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Bắt buộc',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (!cauhinh.isEditable && key == 'email')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Chỉ xem',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (cauhinh.nhandan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                cauhinh.nhandan,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: cauhinh.isEditable ? const Color(0xff0066FF) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: cauhinh.isEditable ? Colors.white : Colors.grey[100],
              hintText: cauhinh.isEditable ? 'Nhập ${cauhinh.tieude.toLowerCase()}' : 'Chỉ xem',
              hintStyle: TextStyle(
                color: cauhinh.isEditable ? Colors.grey[500] : Colors.grey[400],
                fontSize: 14,
              ),
            ),
            keyboardType: _getKeyboardType(cauhinh.kieu),
            enabled: cauhinh.isEditable,
            style: TextStyle(
              color: cauhinh.isEditable ? Colors.black87 : Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String key, CauHinh cauhinh) {
    final controller = _controllers[key];
    final focusNode = _focusNodes[key];
    
    if (controller == null || focusNode == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cauhinh.isEditable ? Colors.grey[200]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cauhinh.tieude,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (cauhinh.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Bắt buộc',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (!cauhinh.isEditable && key == 'email')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Chỉ xem',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (cauhinh.nhandan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                cauhinh.nhandan,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          InkWell(
            onTap: cauhinh.isEditable ? () => _selectDate(context, controller) : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: cauhinh.isEditable ? Colors.grey[300]! : Colors.grey[400]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
                color: cauhinh.isEditable ? Colors.white : Colors.grey[100],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: cauhinh.isEditable ? const Color(0xff0066FF) : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.text.isNotEmpty ? controller.text : 'Chọn ngày',
                      style: TextStyle(
                        color: controller.text.isNotEmpty ? Colors.black87 : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: cauhinh.isEditable ? const Color(0xff0066FF) : Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileField(String key, CauHinh cauhinh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cauhinh.isEditable ? Colors.grey[200]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cauhinh.tieude,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (cauhinh.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Bắt buộc',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (!cauhinh.isEditable && key == 'email')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Chỉ xem',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (cauhinh.huongdan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                cauhinh.huongdan,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: cauhinh.isEditable ? Colors.grey[300]! : Colors.grey[400]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: cauhinh.isEditable ? Colors.white : Colors.grey[100],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff0066FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.upload_file, 
                    color: const Color(0xff0066FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    cauhinh.isEditable ? 'Chọn file để tải lên' : 'Không thể chỉnh sửa',
                    style: TextStyle(
                      color: cauhinh.isEditable ? Colors.black87 : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                if (cauhinh.isEditable)
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement file picker
                      showToast('Tính năng tải file sẽ được cập nhật sau', backgroundColor: Colors.blue);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Chọn file',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(CauHinh cauhinh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cauhinh.tieude,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (!cauhinh.isEditable && cauhinh.tieude.contains('email'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Chỉ xem',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (cauhinh.huongdan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xff0066FF).withOpacity(0.05),
                      const Color(0xff0066FF).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xff0066FF).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xff0066FF),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cauhinh.huongdan,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xff0066FF),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String key, CauHinh cauhinh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cauhinh.isEditable ? Colors.grey[200]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cauhinh.tieude,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (!cauhinh.isEditable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Chỉ xem',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (cauhinh.nhandan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                cauhinh.nhandan,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: cauhinh.isEditable ? Colors.grey[300]! : Colors.grey[400]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: cauhinh.isEditable ? Colors.white : Colors.grey[100],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: cauhinh.isEditable ? const Color(0xff0066FF) : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cauhinh.isEditable 
                        ? 'Chọn ${cauhinh.tieude.toLowerCase()}'
                        : 'Không thể chỉnh sửa',
                    style: TextStyle(
                      color: cauhinh.isEditable ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down, 
                  color: cauhinh.isEditable ? const Color(0xff0066FF) : Colors.grey[400],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextInputType _getKeyboardType(String kieu) {
    switch (kieu) {
      case 'inputemail':
        return TextInputType.emailAddress;
      case 'inputtel':
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    
    if (picked != null) {
      controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  Future<void> _savePersonalInfo() async {
    try {
      // TODO: Implement save API call
      showToast('Tính năng lưu thông tin sẽ được cập nhật sau', backgroundColor: Colors.blue);
    } catch (e) {
      showToast('Lỗi khi lưu thông tin: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (personalInfo != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: _savePersonalInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xff0066FF),
        onRefresh: _loadPersonalInfo,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xff0066FF),
                ),
              )
            : isError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Có lỗi xảy ra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPersonalInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff0066FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : personalInfo == null
                    ? const Center(
                        child: Text('Không có thông tin'),
                      )
                                         : SingleChildScrollView(
                         padding: const EdgeInsets.all(20),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // Header info
                             Container(
                               width: double.infinity,
                               padding: const EdgeInsets.all(24),
                               decoration: BoxDecoration(
                                 gradient: const LinearGradient(
                                   begin: Alignment.topLeft,
                                   end: Alignment.bottomRight,
                                   colors: [Color(0xff0066FF), Color(0xff0052CC)],
                                 ),
                                 borderRadius: BorderRadius.circular(20),
                                 boxShadow: [
                                   BoxShadow(
                                     color: const Color(0xff0066FF).withOpacity(0.3),
                                     blurRadius: 20,
                                     offset: const Offset(0, 8),
                                   ),
                                 ],
                               ),
                               child: Row(
                                 children: [
                                   Container(
                                     width: 64,
                                     height: 64,
                                     decoration: BoxDecoration(
                                       color: Colors.white.withOpacity(0.2),
                                       borderRadius: BorderRadius.circular(32),
                                       border: Border.all(
                                         color: Colors.white.withOpacity(0.3),
                                         width: 2,
                                       ),
                                     ),
                                     child: Center(
                                       child: Text(
                                         personalInfo!.user.isNotEmpty 
                                             ? personalInfo!.user[0].toUpperCase()
                                             : 'U',
                                         style: const TextStyle(
                                           color: Colors.white,
                                           fontSize: 26,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                     ),
                                   ),
                                   const SizedBox(width: 24),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                           personalInfo!.user,
                                           style: const TextStyle(
                                             fontSize: 22,
                                             fontWeight: FontWeight.bold,
                                             color: Colors.white,
                                           ),
                                         ),
                                         const SizedBox(height: 6),
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                           decoration: BoxDecoration(
                                             color: Colors.white.withOpacity(0.2),
                                             borderRadius: BorderRadius.circular(14),
                                           ),
                                           child: Text(
                                             'ID: ${personalInfo!.memberid}',
                                             style: const TextStyle(
                                               fontSize: 13,
                                               color: Colors.white,
                                               fontWeight: FontWeight.w600,
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                             const SizedBox(height: 24),
                             
                             // Form fields
                             Container(
                               width: double.infinity,
                               padding: const EdgeInsets.all(24),
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(
                                   color: Colors.grey[200]!,
                                   width: 1,
                                 ),
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withOpacity(0.08),
                                     blurRadius: 20,
                                     offset: const Offset(0, 4),
                                   ),
                                 ],
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     children: [
                                       Container(
                                         padding: const EdgeInsets.all(10),
                                         decoration: BoxDecoration(
                                           color: const Color(0xff0066FF).withOpacity(0.1),
                                           borderRadius: BorderRadius.circular(10),
                                         ),
                                         child: const Icon(
                                           Icons.person_outline,
                                           color: Color(0xff0066FF),
                                           size: 22,
                                         ),
                                       ),
                                       const SizedBox(width: 14),
                                       const Text(
                                         'Thông tin chi tiết',
                                         style: TextStyle(
                                           fontSize: 20,
                                           fontWeight: FontWeight.bold,
                                           color: Colors.black87,
                                         ),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 24),
                                   ...personalInfo!.thongtinthanhvien.map(_buildFormField).toList(),
                                   if (personalInfo!.bolocthanhvien.isNotEmpty) ...[
                                     const SizedBox(height: 32),
                                     Container(
                                       height: 1,
                                       decoration: BoxDecoration(
                                         gradient: LinearGradient(
                                           colors: [
                                             Colors.grey[300]!,
                                             Colors.grey[200]!,
                                             Colors.grey[300]!,
                                           ],
                                         ),
                                       ),
                                     ),
                                     const SizedBox(height: 32),
                                     Row(
                                       children: [
                                         Container(
                                           padding: const EdgeInsets.all(10),
                                           decoration: BoxDecoration(
                                             color: Colors.orange.withOpacity(0.1),
                                             borderRadius: BorderRadius.circular(10),
                                           ),
                                           child: const Icon(
                                             Icons.location_on_outlined,
                                             color: Colors.orange,
                                             size: 22,
                                           ),
                                         ),
                                         const SizedBox(width: 14),
                                         const Text(
                                           'Thông tin bổ sung',
                                           style: TextStyle(
                                             fontSize: 20,
                                             fontWeight: FontWeight.bold,
                                             color: Colors.black87,
                                           ),
                                         ),
                                       ],
                                     ),
                                     const SizedBox(height: 24),
                                     ...personalInfo!.bolocthanhvien.map(_buildFilterField).toList(),
                                   ],
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ),
      ),
    );
  }
}
