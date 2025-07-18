import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:js' as js;
import 'package:js/js_util.dart' show allowInterop;

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  String _selectedCategory = 'Alimentaire';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _categoryController = TextEditingController();


    @override
      void dispose() {
        _amountController.dispose();
        _dateController.dispose();
        _categoryController.dispose();
        super.dispose();
      }

  void _uploadAndScanImage() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) {
        final base64Image = reader.result as String;
        final callbackId = 'ocr_callback_${DateTime.now().millisecondsSinceEpoch}';
        final eventKey = "ocrResult-$callbackId";

        print('📡 Écoute du callback : $eventKey');

        html.EventListener? listener;
        listener = allowInterop((e) {
          print('✅ Callback reçu : $eventKey');

          final customEvent = e as html.CustomEvent;
          final text = customEvent.detail as String;
          print('🧾 Texte OCR détecté :\n$text');

          updateFormFieldsFromOCR(text);

          html.window.removeEventListener(eventKey, listener);
        });

        html.window.addEventListener(eventKey, listener);

        if (!js.context.hasProperty('extractTextFromImage')) {
          print("❌ Fonction extractTextFromImage non disponible !");
          return;
        }

        js.context.callMethod('extractTextFromImage', [base64Image, callbackId]);
      });
    });
  }

       void updateFormFieldsFromOCR(String recognizedText) {
          print("🧠 updateFormFieldsFromOCR appelé");
          print("📝 Texte OCR reçu : $recognizedText");

          // 1. Extraction du montant (ex: 23,45 € ou 12.90 EUR)
          final montantRegExp = RegExp(r'(\d{1,3}(?:[.,]\d{2}))\s*(€|eur)', caseSensitive: false);
          final montantMatch = montantRegExp.firstMatch(recognizedText);
          final montant = montantMatch?.group(1)?.replaceAll(',', '.');

          if (montant != null) {
            print("💰 Montant détecté : $montant");
            _amountController.text = montant;
          } else {
            print("❌ Aucun montant détecté");
          }

          // 2. Extraction de la date (formats possibles : 12/07/2025, 12-07-2025, etc.)
          final dateRegExp = RegExp(r'(\d{2}[\/\-.]\d{2}[\/\-.]\d{4})');
          final dateMatch = dateRegExp.firstMatch(recognizedText);
          final dateString = dateMatch?.group(1);

          if (dateString != null) {
            try {
              final parts = dateString.split(RegExp(r'[\/\-.]'));
              final parsedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
              _selectedDate = parsedDate;
              print("📅 Date détectée : $_selectedDate");
            } catch (e) {
              print("⚠️ Erreur lors du parsing de la date : $e");
            }
          } else {
            print("❌ Aucune date détectée");
          }

          // 3. Détection intelligente de la catégorie par mots-clés
          final Map<String, String> keywordToCategory = {
            'super u': 'Alimentation',
            'carrefour': 'Alimentation',
            'intermarché': 'Alimentation',
            'monoprix': 'Alimentation',
            'leclerc': 'Alimentation',
            'picard': 'Alimentation',
            'pharmacie': 'Santé',
            'docteur': 'Santé',
            'hopital': 'Santé',
            'train': 'Transport',
            'sncf': 'Transport',
            'uber': 'Transport',
            'essence': 'Transport',
            'carburant': 'Transport',
            'cinema': 'Loisir',
            'netflix': 'Loisir',
            'spotify': 'Loisir',
            'fnac': 'Loisir',
            'restaurant': 'Alimentation',
            'mcdo': 'Alimentation',
            'burger king': 'Alimentation',
            'kfc': 'Alimentation',
          };

          String matchedCategory = 'Autre';
          final textLower = recognizedText.toLowerCase();
          for (final entry in keywordToCategory.entries) {
            if (textLower.contains(entry.key)) {
              matchedCategory = entry.value;
              break;
            }
          }

          _selectedCategory = matchedCategory;
          print("🏷️ Catégorie détectée : $matchedCategory");

          // Rafraîchir les champs avec setState
          setState(() {});
        }




  void _saveExpense() {
    final amount = _amountController.text;
    if (amount.isEmpty) return;

    final expense = {
      'amount': amount,
      'category': _selectedCategory,
      'date': _selectedDate.toIso8601String(),
    };

    final List<String> expenses =
        (html.window.localStorage['expenses'] != null)
            ? List<String>.from(json.decode(html.window.localStorage['expenses']!))
            : [];

    expenses.add(json.encode(expense));
    html.window.localStorage['expenses'] = json.encode(expenses);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('💾 Dépense ajoutée')),
    );

    _amountController.clear();
    _dateController.clear();
    setState(() {
      _selectedCategory = 'Alimentaire';
      _selectedDate = DateTime.now();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une dépense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ElevatedButton.icon(
              onPressed: _uploadAndScanImage,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Scanner un ticket'),
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
                DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                DropdownMenuItem(value: 'Hygiène', child: Text('Hygiène')),
                DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
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
