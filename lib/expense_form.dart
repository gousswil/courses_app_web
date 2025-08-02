// ... imports inchangés ...
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js' as js;
import 'package:js/js_util.dart' show allowInterop;
import 'services/supabase_service.dart'; // 👈 Nouveau
import 'cache/expenses_cache.dart'; // <- à créer

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  bool _isAnalyzing = false;
  String _selectedCategory = 'Alimentaire';
  DateTime _selectedDate = DateTime.now();
  String? _ocrSummary;
  String? _ticketImageBase64;

  bool _showMobileOptions = false;

  bool get _isMobile {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('android') || userAgent.contains('iphone') || userAgent.contains('ipad');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _uploadAndScanImage({bool useCamera = false}) {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    if (useCamera) uploadInput.setAttribute('capture', 'environment');
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) async {
        final base64Image = reader.result as String;
        _ticketImageBase64 = null; // Réinitialise temporairement
        final callbackId = 'ocr_callback_${DateTime.now().millisecondsSinceEpoch}';
        final eventKey = "ocrResult-$callbackId";

        html.EventListener? listener;
        listener = allowInterop((e) {
          final customEvent = e as html.CustomEvent;
          final detail = customEvent.detail as Map;

          _ticketImageBase64 = detail['compressedImage'] as String? ?? '';

          updateFormFieldsFromOCR(jsonEncode(detail));

          setState(() {
            _isAnalyzing = false;
          });

          if (listener != null) {
            html.window.removeEventListener(eventKey, listener);
          }
        });

        html.window.addEventListener(eventKey, listener);

        setState(() {
          _isAnalyzing = true;
          _ocrSummary = null;
        });

        if (!js.context.hasProperty('compressAndSendToVisionAPI')) {
          print("❌ Fonction compressAndSendToVisionAPI non disponible !");
          return;
        }

        js.context.callMethod('compressAndSendToVisionAPI', [base64Image, callbackId]);
        setState(() {
          _showMobileOptions = false;
        });
      });
    });
  }

  void updateFormFieldsFromOCR(String jsonString) {
    print("🧠 updateFormFieldsFromOCR appelé");
    print("📦 JSON OCR reçu : $jsonString");

    try {
      final data = jsonDecode(jsonString);
      final montant = data['total']?.toString()?.replaceAll(',', '.');
      final dateString = data['date'];
      final category = data['category'];

      DateTime? parsedDate;
      if (dateString != null && dateString.isNotEmpty) {
        try {
          parsedDate = DateTime.parse(dateString);
        } catch (e) {
          print("⚠️ Erreur parsing date : $e");
        }
      }

      setState(() {
        if (montant != null) {
          _amountController.text = montant.replaceAll(RegExp(r'[^\d.,]'), '');
        }

        if (parsedDate != null) {
          _selectedDate = parsedDate;
          _dateController.text = '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
        }

        if (category != null && category.isNotEmpty) {
          _selectedCategory = category;
        }

        _ocrSummary = "💡 Dépense détectée : "
            "${montant != null ? '$montant €' : 'montant inconnu'}, "
            "$_selectedCategory, "
            "${parsedDate != null ? 'le ${_dateController.text}' : 'date inconnue'}.";
      });
    } catch (e) {
      print("❌ Erreur parsing JSON OCR : $e");
    }
  }

  void _saveExpense() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) return;

    final expense = {
      'amount': amount,
      'category': _selectedCategory,
      'date': _selectedDate.toIso8601String(),
    };

    final supabaseService = SupabaseService();
    await supabaseService.addExpense(expense, _ticketImageBase64);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Dépense enregistrée')),
    );

    _amountController.clear();
    _dateController.clear();
    ExpensesCache().clear();
    setState(() {
      _selectedCategory = 'Alimentaire';
      _selectedDate = DateTime.now();
      _ocrSummary = null;
      _ticketImageBase64 = null;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une dépense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ElevatedButton.icon(
              onPressed: _isAnalyzing
                  ? null
                  : () {
                      if (isSmallScreen) {
                        setState(() => _showMobileOptions = !_showMobileOptions);
                      } else {
                        _uploadAndScanImage(useCamera: false);
                      }
                    },
              icon: const Icon(Icons.photo_camera),
              label: const Text('Scanner un ticket'),
            ),
            if (_showMobileOptions && !_isAnalyzing) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _uploadAndScanImage(useCamera: true),
                child: const Text('📷 Prendre une photo'),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => _uploadAndScanImage(useCamera: false),
                child: const Text('📁 Choisir un fichier'),
              ),
            ],
            if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 12),
                    Text('Analyse du ticket en cours...'),
                  ],
                ),
              ),
            if (_ocrSummary != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _ocrSummary!,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant (€)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: const [
                DropdownMenuItem(value: 'Alimentaire', child: Text('Alimentaire')),
                DropdownMenuItem(value: 'Carburant', child: Text('Carburant')),
                DropdownMenuItem(value: 'Santé', child: Text('Santé')),
                DropdownMenuItem(value: 'Mode', child: Text('Mode')),
                DropdownMenuItem(value: 'Beauté', child: Text('Beauté')),
                DropdownMenuItem(value: 'Maison', child: Text('Maison')),
                DropdownMenuItem(value: 'Bricolage', child: Text('Bricolage')),
                DropdownMenuItem(value: 'Sport', child: Text('Sport')),
                DropdownMenuItem(value: 'Culture', child: Text('Culture')),
                DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                DropdownMenuItem(value: 'Electronique', child: Text('Electronique')),
                DropdownMenuItem(value: 'Enfants', child: Text('Enfants')),
                DropdownMenuItem(value: 'Animaux', child: Text('Animaux')),
                DropdownMenuItem(value: 'Tabac', child: Text('Tabac')),
                DropdownMenuItem(value: 'Services', child: Text('Services')),
                DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date'),
              onTap: _pickDate,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveExpense,
              child: const Text('Ajouter la dépense'),
            ),
          ],
        ),
      ),
    );
  }
}
