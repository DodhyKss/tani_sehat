import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  String? _token;
  Map<String, dynamic>? _currentUser;
  
  // Global refresh notifier
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);
  
  void notifyRefresh() {
    refreshNotifier.value++;
  }

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  int? get userId => _currentUser?['id'];

  void setToken(String token) {
    _token = token;
  }

  void setCurrentUser(Map<String, dynamic> user) {
    _currentUser = user;
  }

  void clearSession() {
    _token = null;
    _currentUser = null;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ========================
  //  AUTH
  // ========================

  Future<Map<String, dynamic>> login(String nik, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'nik': nik, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      _token = data['data']['token'];
      _currentUser = data['data']['user'];
    }
    return data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      _currentUser = data['data'];
    }
    return data;
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    clearSession();
    return data;
  }

  // ========================
  //  CHAT / MESSAGES
  // ========================

  Future<List<dynamic>> getAdmins() async {
    final response = await http.get(Uri.parse('$baseUrl/admins'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? data['data'] : [];
  }

  Future<List<dynamic>> getKaders() async {
    final response = await http.get(Uri.parse('$baseUrl/kaders'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? data['data'] : [];
  }

  Future<Map<String, dynamic>> startConversation(int receiverId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/start'),
      headers: _headers,
      body: jsonEncode({'receiver_id': receiverId}),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getInbox() async {
    final response = await http.get(Uri.parse('$baseUrl/messages'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? data['data'] : [];
  }

  Future<Map<String, dynamic>> getConversationDetail(int conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/$conversationId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> sendMessage(int conversationId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/$conversationId/send'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteMessage(int messageId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/messages/detail/$messageId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ========================
  //  HEALTH DATA
  // ========================

  Future<Map<String, dynamic>> cekJadwal(String jenis) async {
    final response = await http.get(
      Uri.parse('$baseUrl/status-kesehatan/cek-jadwal?jenis=$jenis'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getKuesionerGAD() async {
    final response = await http.get(Uri.parse('$baseUrl/gad/kuesioner'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? data['data'] : [];
  }

  Future<Map<String, dynamic>> storeTekananDarah(int systolic, int diastolic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tekanan-darah'),
      headers: _headers,
      body: jsonEncode({'systolic': systolic, 'diastolic': diastolic}),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) notifyRefresh();
    return data;
  }

  Future<Map<String, dynamic>> storeGAD(int skor, List<Map<String, dynamic>> jawaban) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gad'),
      headers: _headers,
      body: jsonEncode({'skor': skor, 'jawaban': jawaban}),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) notifyRefresh();
    return data;
  }

  Future<List<dynamic>> getRiwayatTD() async {
    final response = await http.get(Uri.parse('$baseUrl/tekanan-darah'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? (data['data']['data'] ?? []) : [];
  }

  Future<List<dynamic>> getRiwayatGAD() async {
    final response = await http.get(Uri.parse('$baseUrl/gad'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? (data['data']['data'] ?? []) : [];
  }

  // ========================
  //  REPRODUKSI
  // ========================

  Future<List<dynamic>> getReproduksi() async {
    final response = await http.get(Uri.parse('$baseUrl/reproduksi'), headers: _headers);
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      // Laravel pagination returns the list in data['data']['data']
      if (data['data'] is Map && data['data']['data'] is List) {
        return data['data']['data'];
      }
      return data['data'] is List ? data['data'] : [];
    }
    return [];
  }

  Future<Map<String, dynamic>> storeReproduksi({
    required String keterangan,
    required String tglMenstruasi,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reproduksi'),
      headers: _headers,
      body: jsonEncode({
        'keterangan': keterangan,
        'tgl_menstruasi': tglMenstruasi,
      }),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) notifyRefresh();
    return data;
  }

  Future<Map<String, dynamic>> deleteReproduksi(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reproduksi/$id'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ========================
  //  REKOMENDASI & EDUKASI
  // ========================

  Future<Map<String, dynamic>> getRekomendasi({String? kategoriTd, String? kategoriGad}) async {
    String url = '$baseUrl/rekomendasi?';
    if (kategoriTd != null) url += 'kategori_td=$kategoriTd&';
    if (kategoriGad != null) url += 'kategori_gad=$kategoriGad';
    final response = await http.get(Uri.parse(url), headers: _headers);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getMateri() async {
    final response = await http.get(Uri.parse('$baseUrl/materi'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? data['data'] : [];
  }

  Future<List<dynamic>> getVideo() async {
    final response = await http.get(Uri.parse('$baseUrl/video'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? data['data'] : [];
  }

  Future<List<dynamic>> getGambar() async {
    final response = await http.get(Uri.parse('$baseUrl/gambar'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? data['data'] : [];
  }

  Future<List<dynamic>> getOlahraga() async {
    final response = await http.get(Uri.parse('$baseUrl/olahraga'), headers: _headers);
    final data = jsonDecode(response.body);
    return data['success'] == true ? data['data'] : [];
  }
}
