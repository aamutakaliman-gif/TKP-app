import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const TkpApp());

class TkpApp extends StatelessWidget {
  const TkpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKP Collector',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const CollectorPage(),
    );
  }
}

class CollectorPage extends StatefulWidget {
  const CollectorPage({super.key});

  @override
  State<CollectorPage> createState() => _CollectorPageState();
}

class _CollectorPageState extends State<CollectorPage> {
  final _serverCtrl = TextEditingController(text: 'http://192.168.1.15:8000');
  final _caseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  File? _photo;
  Position? _position;
  bool _busy = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final saved = p.getString('server');
      if (saved != null) setState(() => _serverCtrl.text = saved);
    });
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _caseCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _server => _serverCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');

  void _setStatus(String s) => setState(() => _status = s);

  Future<void> _saveServer() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('server', _server);
  }

  Future<void> _testConnection() async {
    await _saveServer();
    _setStatus('Mengecek server...');
    try {
      final res = await http
          .get(Uri.parse('$_server/api/health'))
          .timeout(const Duration(seconds: 5));
      _setStatus(res.statusCode == 200
          ? 'Server terhubung ✓'
          : 'Server menjawab kode ${res.statusCode}');
    } catch (e) {
      _setStatus('Tidak bisa terhubung: $e\n'
          'Cek: HP & laptop satu Wi-Fi, IP benar, server jalan, firewall port 8000.');
    }
  }

  Future<void> _takePhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _getLocation() async {
    _setStatus('Mengambil lokasi GPS...');
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setStatus('GPS mati. Nyalakan Lokasi di HP.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _setStatus('Izin lokasi ditolak. Izinkan di Pengaturan > Aplikasi.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      setState(() => _position = pos);
      _setStatus('Lokasi didapat (akurasi ±${pos.accuracy.toStringAsFixed(0)} m)');
    } catch (e) {
      _setStatus('Gagal ambil lokasi: $e');
    }
  }

  Future<void> _upload() async {
    if (_caseCtrl.text.trim().isEmpty) {
      _setStatus('Isi nomor perkara dulu.');
      return;
    }
    if (_photo == null) {
      _setStatus('Ambil foto dulu.');
      return;
    }
    await _saveServer();
    setState(() {
      _busy = true;
      _status = 'Mengirim...';
    });
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('$_server/api/upload_evidence'))
        ..fields['case_id'] = _caseCtrl.text.trim()
        ..fields['label'] = _noteCtrl.text.trim()
        ..fields['captured_at'] = DateTime.now().toUtc().toIso8601String()
        ..files.add(await http.MultipartFile.fromPath('file', _photo!.path));
      final pos = _position;
      if (pos != null) {
        req.fields['latitude'] = pos.latitude.toString();
        req.fields['longitude'] = pos.longitude.toString();
        req.fields['accuracy'] = pos.accuracy.toString();
      }
      final res = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 60)));
      if (res.statusCode == 200) {
        setState(() {
          _photo = null;
          _position = null;
          _noteCtrl.clear();
        });
        _setStatus('Terkirim ✓\n${res.body}');
      } else {
        _setStatus('Gagal (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      _setStatus('Gagal kirim: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = _position;
    return Scaffold(
      appBar: AppBar(title: const Text('TKP Collector')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _serverCtrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Alamat server (IP laptop)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.wifi_find),
                tooltip: 'Tes koneksi',
                onPressed: _busy ? null : _testConnection,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caseCtrl,
            decoration: const InputDecoration(
              labelText: 'Nomor perkara / kode TKP',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Keterangan barang bukti',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_photo!, height: 240, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_photo == null ? 'Ambil Foto' : 'Foto Ulang'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _getLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Ambil GPS'),
                ),
              ),
            ],
          ),
          if (pos != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'Lat ${pos.latitude.toStringAsFixed(6)}, '
                  'Lng ${pos.longitude.toStringAsFixed(6)} '
                  '(±${pos.accuracy.toStringAsFixed(0)} m)'),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _upload,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload),
            label: const Text('Kirim ke Server'),
          ),
          const SizedBox(height: 16),
          Text(_status),
        ],
      ),
    );
  }
}
