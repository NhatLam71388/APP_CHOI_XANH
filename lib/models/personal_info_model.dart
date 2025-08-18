class PersonalInfoModel {
  final String thongBao;
  final String maloi;
  final String id;
  final String memberid;
  final String user;
  final String chucnang;
  final String maQuanLy;
  final List<ThongTinThanhVien> thongtinthanhvien;
  final List<BoLocThanhVien> bolocthanhvien;

  PersonalInfoModel({
    required this.thongBao,
    required this.maloi,
    required this.id,
    required this.memberid,
    required this.user,
    required this.chucnang,
    required this.maQuanLy,
    required this.thongtinthanhvien,
    required this.bolocthanhvien,
  });

  factory PersonalInfoModel.fromJson(Map<String, dynamic> json) {
    return PersonalInfoModel(
      thongBao: json['ThongBao'] ?? '',
      maloi: json['maloi'] ?? '',
      id: json['id'] ?? '',
      memberid: json['memberid'] ?? '',
      user: json['user'] ?? '',
      chucnang: json['chucnang'] ?? '',
      maQuanLy: json['MaQuanLy'] ?? '',
      thongtinthanhvien: (json['thongtinthanhvien'] as List?)
          ?.map((item) => ThongTinThanhVien.fromJson(item))
          .toList() ?? [],
      bolocthanhvien: (json['bolocthanhvien'] as List?)
          ?.map((item) => BoLocThanhVien.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ThongTinThanhVien {
  final String tennhom;
  final CauHinh cauhinh;

  ThongTinThanhVien({
    required this.tennhom,
    required this.cauhinh,
  });

  factory ThongTinThanhVien.fromJson(Map<String, dynamic> json) {
    return ThongTinThanhVien(
      tennhom: json['tennhom'] ?? '',
      cauhinh: CauHinh.fromJson(json['cauhinh']),
    );
  }
}

class CauHinh {
  final String tieude;
  final String kieu;
  final String nhandan;
  final String batbuoc;
  final String sua;
  final String huongdan;
  final String giatri;
  final String nhom;
  final String? id;
  final String? loai;

  CauHinh({
    required this.tieude,
    required this.kieu,
    required this.nhandan,
    required this.batbuoc,
    required this.sua,
    required this.huongdan,
    required this.giatri,
    required this.nhom,
    this.id,
    this.loai,
  });

  factory CauHinh.fromJson(Map<String, dynamic> json) {
    return CauHinh(
      tieude: json['tieude'] ?? '',
      kieu: json['kieu'] ?? '',
      nhandan: json['nhandan'] ?? '',
      batbuoc: json['batbuoc'] ?? '',
      sua: json['sua'] ?? '',
      huongdan: json['huongdan'] ?? '',
      giatri: json['giatri'] ?? '',
      nhom: json['nhom'] ?? '',
      id: json['id'],
      loai: json['loai'],
    );
  }

  bool get isRequired => batbuoc.toLowerCase() == 'true';
  bool get isEditable => sua.toLowerCase() == 'true';
}

class BoLocThanhVien {
  final String tennhom;
  final CauHinh cauhinh;
  final String? ord;

  BoLocThanhVien({
    required this.tennhom,
    required this.cauhinh,
    this.ord,
  });

  factory BoLocThanhVien.fromJson(Map<String, dynamic> json) {
    return BoLocThanhVien(
      tennhom: json['tennhom'] ?? '',
      cauhinh: CauHinh.fromJson(json['cauhinh']),
      ord: json['ord'],
    );
  }
}
