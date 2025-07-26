import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await _supabaseService.getExpenses();
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur de chargement des dépenses : $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(date);
  }


  // Méthode pour afficher l'image en grand
void _showImageDialog(BuildContext context, String imageBase64) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Image en grand avec Hero animation
            Center(
              child: Hero(
                tag: 'expense_image_$imageBase64',
                child: InteractiveViewer(
                  child: Image.memory(
                    UriData.parse(imageBase64).contentAsBytes(),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Bouton fermer
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des dépenses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text('Aucune dépense enregistrée.'))
              : ListView.builder(
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    final amount = expense['amount'] ?? '?';
                    final category = expense['category'] ?? '?';
                    final date = expense['date'] ?? '';
                    final imageBase64 = expense['image_base64'] ?? '';
                        return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                                leading: imageBase64.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () => _showImageDialog(context, imageBase64),
                                        child: Hero(
                                        tag: 'expense_image_$imageBase64', // Tag unique pour l'animation
                                        child: Image.memory(
                                            UriData.parse(imageBase64).contentAsBytes(),
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                        ),
                                        ),
                                    )
                                    : const Icon(Icons.receipt_long),
                                title: Text('$amount € - $category'),
                                subtitle: Text(_formatDate(date)),
                            ),
                            );
                  },
                ),
    );
  }
}
