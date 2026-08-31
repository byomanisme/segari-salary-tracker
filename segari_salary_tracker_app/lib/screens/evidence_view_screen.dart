import 'dart:io';
import 'package:flutter/material.dart';

class EvidenceViewScreen extends StatelessWidget {
  final String dateStr;
  final String? assetPath;
  final String? localFilePath;

  const EvidenceViewScreen({
    Key? key,
    required this.dateStr,
    this.assetPath,
    this.localFilePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (localFilePath != null && localFilePath!.isNotEmpty) {
      imageWidget = Image.file(
        File(localFilePath!),
        fit: BoxFit.contain,
      );
    } else if (assetPath != null && assetPath!.isNotEmpty) {
      imageWidget = Image.asset(
        assetPath!,
        fit: BoxFit.contain,
      );
    } else {
      imageWidget = const Center(
        child: Text(
          'Tidak ada foto bukti',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Bukti Absensi: $dateStr',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: imageWidget,
        ),
      ),
    );
  }
}
