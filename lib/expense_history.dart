import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';

class ExpenseHistoryPage extends StatelessWidget {
  const ExpenseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> rawExpenses =
        (html.window.localStorage['expenses'] != null)
            ? List<String>.from(json.decode(html.window.localStorage['expenses']!))
            : [];

    final List<Map<String, dynamic>> expenses = rawExpenses
        .map((e) => json.decode(e) as Map<String, dynamic>)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des dépenses')),
      body: expenses.isEmpty
          ? const Center(child: Text('Aucune dépense enregistrée'))
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final date = DateTime.parse(expense['date']);
                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('${expense['amount']} € - ${expense['category']}'),
                  subtitle: Text('${date.day}/${date.month}/${date.year}'),
                );
              },
            ),
    );
  }
}
