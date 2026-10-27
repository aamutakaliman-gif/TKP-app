import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const TKPCollectorApp());

class TKPCollectorApp extends StatelessWidget {
  const TKPCollectorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FE4RD0WN TKP Collector',
      theme: ThemeData.dark(),
      home: const TKPHomeScreen(),
    );
  }
}

class TKPHomeScreen extends StatefulWidget {
  const TKPHomeScreen({Key? key}) : super(key: key);

  @override
  _TKPHomeScreenState createState() => _TKPHomeScreenState();
}

class _TKPHomeScreenState extends State<TKPHomeScreen> {
  final TextEditingController _caseIdController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  File? _imageFile;
  Position? _currentPosition;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() { _currentPosition = position; });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() { _imageFile = File(pickedFile.path); });
      await _getCurrentLocation();
    }
  }

  Future<void> _uploadData() async {
    if (_imageFile == null || _currentPosition == null || _caseIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi Case ID, Foto, dan GPS dulu, bajingan!')),
      );
      return;
    }
    setState(() { _isUploading = true; });

    // Ganti IP di bawah ini dengan IP Laptop Server lu yang aktif!
    var uri = Uri.parse('http://192.168.1.50:8000/api/upload_evidence');
    var request = http.MultipartRequest('POST', uri)
      ..fields['case_id'] = _caseIdController.text
      ..fields['label'] = _labelController.text.isEmpty ? 'Unlabeled' : _labelController.text
      ..fields['latitude'] = _currentPosition!.latitude.toString()
      ..fields['longitude'] = _currentPosition!.longitude.toString()
      ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

    var response = await request.send();
    setState(() { _isUploading = false; });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Bukti Berhasil Dikirim ke Laptop Pusat!')),
      );
      setState(() {
        _imageFile = null;
        _labelController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal kirim data, cek server laptop!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FE4RD0WN Evidence Collector')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _caseIdController, decoration: const InputDecoration(labelText: 'Case ID')),
            TextField(controller: _labelController, decoration: const InputDecoration(labelText: 'Label Bukti')),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.camera_alt), label: const Text('Ambil Foto & GPS')),
            const SizedBox(height: 20),
            _imageFile != null ? Image.file(_imageFile!, height: 200) : const Text('Belum ada foto.'),
            const SizedBox(height: 10),
            _currentPosition != null ? Text('GPS: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}') : const Text('GPS belum dikunci.'),
            const SizedBox(height: 30),
            _isUploading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: _uploadData, document: null, child: const Text('Kirim ke Laptop')),
          ],
        ),
      ),
    );
  }
}
