import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:js/js.dart';
import 'js_interop.dart';


class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'Alimentaire';
  DateTime _selectedDate = DateTime.now();

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
            final base64Image = (reader.result as String).split(',').last;

            final callbackId = 'ocr_callback_${DateTime.now().millisecondsSinceEpoch}';

            html.window.addEventListener(callbackId, allowInterop((e) {
              final customEvent = e as html.CustomEvent;
              final text = customEvent.detail as String;

              print('Texte OCR détecté : $text');

              // Exemple : recherche du montant dans le texte
              final regex = RegExp(r'(\d+[\.,]?\d{0,2}) ?€');
              final match = regex.firstMatch(text);
              if (match != null) {
                final montant = match.group(1)?.replaceAll(',', '.');
                setState(() {
                  _amountController.text = montant ?? '';
                });
              }

              // Nettoyage de l'écouteur
              html.window.removeEventListener(callbackId, null);
            }));

            // Appel JS
            extractTextFromImage(base64Image, callbackId);
          });
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
              icon: Icon(Icons.photo_camera),
              label: Text('Scanner un ticket'),
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
            const Spacer(),
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
