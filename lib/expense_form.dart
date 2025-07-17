import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:js' as js;
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

      void _scanTicketAndFillForm() async {
      try {
        final jsPromise = recognizeFromFile(); // <-- Appel JS
        final String? ocrText = await jsPromiseToFuture<String?>(jsPromise);

        if (ocrText == null || ocrText.trim().isEmpty) {
          throw 'Aucun texte détecté';
        }

        // 🧾 Extraction du montant (plus grand montant détecté)
        final montantRegex = RegExp(r'(\d{1,4}[.,]\d{2})');
        final allMatches = montantRegex.allMatches(ocrText);
        final montants = allMatches
            .map((m) => m.group(0)?.replaceAll(',', '.'))
            .where((s) => s != null)
            .map((s) => double.tryParse(s!) ?? 0)
            .where((n) => n > 0)
            .toList();
        montants.sort();
        final montant = montants.isNotEmpty ? montants.last.toStringAsFixed(2) : '';

        // 📅 Extraction de la date
        final dateRegex = RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})');
        final dateMatch = dateRegex.firstMatch(ocrText);
        DateTime? parsedDate;
        if (dateMatch != null) {
          final dateStr = dateMatch.group(0)!;
          parsedDate = _parseDate(dateStr);
        }

        // 🧠 Détection de la catégorie
        final lower = ocrText.toLowerCase();
        String cat = 'Autre';
        if (lower.contains('carrefour') ||
            lower.contains('intermarché') ||
            lower.contains('boulangerie') ||
            lower.contains('super u') ||
            lower.contains('aliment')) {
          cat = 'Alimentaire';
        } else if (lower.contains('bus') ||
            lower.contains('sncf') ||
            lower.contains('uber') ||
            lower.contains('transport')) {
          cat = 'Transport';
        } else if (lower.contains('pharmacie') ||
            lower.contains('shampoo') ||
            lower.contains('gel douche') ||
            lower.contains('hygiène')) {
          cat = 'Hygiène';
        }

        setState(() {
          if (montant.isNotEmpty) _amountController.text = montant;
          _selectedCategory = cat;
          if (parsedDate != null) _selectedDate = parsedDate;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations extraites avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur OCR : $e')),
        );
      }
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
              onPressed: _scanTicketAndFillForm,
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
