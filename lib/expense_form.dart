import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:js' as js;
import 'js_interop.dart';
import 'package:js/js_util.dart' show allowInterop;


class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'Alimentaire';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();

      @override
        void dispose() {
          _amountController.dispose();
          _dateController.dispose();
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

            final base64Image = reader.result as String; // garde toute la chaîne avec le header

            final callbackId = 'ocr_callback_${DateTime.now().millisecondsSinceEpoch}';

            print('Écoute du callback : ocrResult-$callbackId');
              html.window.addEventListener(callbackId, allowInterop((e) {
              final customEvent = e as html.CustomEvent;
              final text = customEvent.detail as String;
              print('🧾 Texte OCR détecté : $text');

              updateFormFieldsFromOCR(text); // Appel de la fonction de traitement

              html.window.removeEventListener(callbackId, null); // Nettoyage
            }));
            js.context.callMethod('extractTextFromImage', [base64Image, callbackId]);

          });
        });
      }

  DateTime? _parseDate(String input) {
    try {
      final cleaned = input.replaceAll(RegExp(r'[^0-9\/\-\.]'), '');
      final parts = cleaned.split(RegExp(r'[\/\-\.]'));
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
          return DateTime(y, m, d);
        }
      }
    } catch (_) {}
    return null;
  }


          void updateFormFieldsFromOCR(String recognizedText) {
            print("updateFormFieldsFromOCR appelé");
            print("Texte OCR brut : $recognizedText");

            // Extraction du montant total
            final montantRegExp = RegExp(r'(\d+[.,]?\d*)\s*(€|EUR)');
            final montantMatch = montantRegExp.firstMatch(recognizedText);
            final montant = montantMatch?.group(1)?.replaceAll(',', '.');

            // Extraction de la date (format dd/MM/yyyy)
            final dateRegExp = RegExp(r'(\d{2}/\d{2}/\d{4})');
            final dateMatch = dateRegExp.firstMatch(recognizedText);
            final dateString = dateMatch?.group(1);

            // Détection simple de la catégorie
            String? category;
            final lowerText = recognizedText.toLowerCase();
            if (lowerText.contains('carrefour') || lowerText.contains('super u') || lowerText.contains('intermarché')) {
              category = 'Alimentaire';
            } else if (lowerText.contains('bus') || lowerText.contains('taxi')) {
              category = 'Transport';
            } else if (lowerText.contains('shampooing') || lowerText.contains('gel douche')) {
              category = 'Hygiène';
            } else {
              category = 'Autre';
            }

            // Mise à jour des champs du formulaire
            setState(() {
              if (montant != null) {
                print("Montant détecté : $montant");
                _amountController.text = montant;
              }
              if (category != null) {
                print("Catégorie détectée : $category");
                _selectedCategory = category;
              }
              if (dateString != null) {
                final parsedDate = DateTime.tryParse(
                  '${dateString.substring(6)}-${dateString.substring(3, 5)}-${dateString.substring(0, 2)}',
                );
                if (parsedDate != null) {
                  print("Date détectée : $parsedDate");
                  _selectedDate = parsedDate;
                }
              }
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
      const SnackBar(content: Text('Dépense ajoutée')),
    );

    _amountController.clear();
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
            Row(
              children: [
                Text('Date : ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Choisir une date'),
                ),
              ],
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
