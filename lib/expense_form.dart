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
            print("Texte OCR détecté : $recognizedText");

            // Date au format dd/mm/yyyy ou dd/mm/yy
            final dateRegex = RegExp(r'(\d{2}/\d{2}/\d{2,4})');
            final dateMatch = dateRegex.firstMatch(recognizedText);
            if (dateMatch != null) {
              final rawDate = dateMatch.group(0)!;
              final parts = rawDate.split('/');
              if (parts[2].length == 2) {
                parts[2] = '20${parts[2]}';
              }
              final formattedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
              _dateController.text = formattedDate;
              print("✅ Date détectée : $formattedDate");
            } else {
              print("❌ Aucune date détectée");
            }

            // Montant avec symbole €
            final montantRegex = RegExp(r'(\d+[.,]\d{2})\s?€');
            final montantMatch = montantRegex.firstMatch(recognizedText);
            if (montantMatch != null) {
              final montantStr = montantMatch.group(1)!.replaceAll(',', '.');
              _amountController.text = montantStr;
              print("✅ Montant détecté : $montantStr");
            } else {
              // Fallback : plus grand chiffre avec virgule
              final montantFallback = RegExp(r'\d+[.,]\d{2}').allMatches(recognizedText).map((m) {
                final val = m.group(0)!.replaceAll(',', '.');
                return double.tryParse(val) ?? 0.0;
              }).fold<double>(0.0, (max, val) => val > max ? val : max);

              if (montantFallback > 0) {
                _amountController.text = montantFallback.toStringAsFixed(2);
                print("✅ Montant fallback détecté : ${montantFallback.toStringAsFixed(2)}");
              } else {
                print("❌ Aucun montant détecté");
              }
            }

            // Catégorie simple
            final categories = ["alimentation", "loisir", "transport", "santé", "maison", "autre"];
            final lowerText = recognizedText.toLowerCase();
            final matchedCategory = categories.firstWhere(
              (cat) => lowerText.contains(cat),
              orElse: () => "Autre",
            );
            _categoryController.text = matchedCategory;
            print("Catégorie détectée : $matchedCategory");
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
