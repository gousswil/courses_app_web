import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';

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
      final input = html.FileUploadInputElement();
      input.accept = 'image/*';
      input.click();

      input.onChange.listen((e) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsDataUrl(file);

        reader.onLoadEnd.listen((event) {
          final base64Image = reader.result as String;

          final callbackId = DateTime.now().millisecondsSinceEpoch;
          html.window.addEventListener('ocrResult-$callbackId', (event) {
            final text = (event as html.CustomEvent).detail as String;
            print('Texte OCR : $text');

            // 🔥 Auto-remplissage si on détecte un montant
            final reg = RegExp(r'(\d+[,\.]?\d{0,2}) ?€');
            final match = reg.firstMatch(text);
            if (match != null) {
              setState(() {
                _amountController.text = match.group(1)!.replaceAll(',', '.');
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Montant détecté : ${match.group(0)}')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aucun montant détecté')),
              );
            }
          });

          // Appel à la fonction JS
          html.context.callMethod('extractTextFromImage', [base64Image, callbackId]);
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
