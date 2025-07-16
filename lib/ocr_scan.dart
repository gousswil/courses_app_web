import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class OcrScanPage extends StatefulWidget {
  const OcrScanPage({super.key});

  @override
  State<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends State<OcrScanPage> {
  String _recognizedText = '';
  bool _isLoading = false;

  Future<void> _startOcrScan() async {
    setState(() {
      _isLoading = true;
      _recognizedText = '';
    });

    try {
      final result = await js_util.promiseToFuture<String>(
        js.context.callMethod('recognizeFromFile'),
      );

      setState(() {
        _recognizedText = result;
      });
    } catch (e) {
      setState(() {
        _recognizedText = 'Erreur : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un ticket')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _startOcrScan,
              child: const Text('Choisir une image'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _recognizedText.isEmpty
                            ? 'Aucun texte reconnu pour le moment.'
                            : _recognizedText,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
