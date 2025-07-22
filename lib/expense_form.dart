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
  final _categoryController = TextEditingController();
  String _selectedCategory = 'Alimentaire';
  DateTime _selectedDate = DateTime.now();
  String? _ocrSummary;

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

    final cleanedText = recognizedText.replaceAll(RegExp(r'[^\x00-\x7F]+'), ' ').replaceAll('\n', ' ');

    final montantRegExp = RegExp(
      r'(\d+[.,]\d{2})\s*(€|eur|e)?',
      caseSensitive: false,
    );
    final montantMatch = montantRegExp.firstMatch(cleanedText);
    final montant = montantMatch?.group(1)?.replaceAll(',', '.').replaceAll(' ', '');

    final List<RegExp> dateRegExps = [
      RegExp(r'(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{4})'),
      RegExp(r'(\d{4}[\/\-\.]\d{2}[\/\-\.]\d{2})'),
      RegExp(r'(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{2})'),
    ];

    DateTime? parsedDate;
    String? dateString;

    for (final regex in dateRegExps) {
      final match = regex.firstMatch(cleanedText);
      if (match != null) {
        dateString = match.group(1);
        break;
      }
    }

    if (dateString != null) {
      try {
        final parts = dateString.split(RegExp(r'[\/\-\.]'));
        if (parts[0].length == 4) {
          parsedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          final year = parts[2].length == 2
              ? 2000 + int.parse(parts[2])
              : int.parse(parts[2]);
          parsedDate = DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (e) {
        print("⚠️ Erreur lors du parsing de la date : $e");
      }
    }

    final Map<String, String> keywordToCategory = {
      'super u': 'Alimentaire',
      'carrefour': 'Alimentaire',
      'intermarché': 'Alimentaire',
      'monoprix': 'Alimentaire',
      'leclerc': 'Alimentaire',
      'picard': 'Alimentaire',
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
      'restaurant': 'Alimentaire',
      'mcdo': 'Alimentaire',
      'burger king': 'Alimentaire',
      'kfc': 'Alimentaire',
    };

    String matchedCategory = 'Autre';
    final textLower = cleanedText.toLowerCase();
    for (final entry in keywordToCategory.entries) {
      if (textLower.contains(entry.key)) {
        matchedCategory = entry.value;
        break;
      }
    }

    setState(() {
      if (montant != null) {
        _amountController.text = montant;
        print("💰 Montant détecté : $montant");
      } else {
        print("❌ Aucun montant détecté");
      }

      if (parsedDate != null) {
        _selectedDate = parsedDate;
        _dateController.text = '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
        print("📅 Date détectée : $_selectedDate");
      } else {
        print("❌ Aucune date détectée");
      }

      _selectedCategory = matchedCategory;
      print("🏷️ Catégorie détectée : $matchedCategory");

      _ocrSummary = "💡 Dépense détectée : "
          "${montant != null ? '$montant €' : 'montant inconnu'}, "
          "${matchedCategory != 'Autre' ? matchedCategory : 'catégorie inconnue'}, "
          "${parsedDate != null ? 'le ${parsedDate.day}/${parsedDate.month}/${parsedDate.year}' : 'date inconnue'}.";
    });
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
