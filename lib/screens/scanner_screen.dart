import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📷 Сканировать ISBN'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Камера
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_isProcessing) return; // Защита от повторных срабатываний

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  final isbn = barcode.rawValue!;

                  // Проверяем, что это ISBN-13 (13 цифр)
                  final cleanIsbn = isbn.replaceAll(RegExp(r'[-\s]'), '');
                  if (cleanIsbn.length == 13 && cleanIsbn.startsWith('978') ||
                      cleanIsbn.length == 10) {
                    setState(() => _isProcessing = true);

                    // Возвращаем ISBN и закрываем экран
                    if (mounted) {
                      Navigator.pop(context, cleanIsbn);
                    }
                    break;
                  }
                }
              }
            },
          ),

          // Рамка для сканирования
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Подсказка
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: const Text(
                '📖 Наведите камеру на штрих-код книги (ISBN)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Индикатор обработки
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
