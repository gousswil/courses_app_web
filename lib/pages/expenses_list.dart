import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:typed_data';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  Map<String, Map<String, Map<String, double>>> _groupedExpenses = {};
  String _selectedYear = '';
  String _selectedMonth = '';
  bool _showGraphics = false;
  bool _showExpenseList = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    // _groupExpensesByDate();
  }

void _groupExpensesByDate() {
    _groupedExpenses.clear();
    
    for (var expense in _expenses) {
      final dateStr = expense['date'] ?? '';
      final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
      final category = expense['category'] ?? 'Autre';
      
      if (dateStr.isNotEmpty) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final year = date.year.toString();
          final month = date.month.toString().padLeft(2, '0');
          
          _groupedExpenses[year] ??= {};
          _groupedExpenses[year]![month] ??= {};
          _groupedExpenses[year]![month]![category] = 
              (_groupedExpenses[year]![month]![category] ?? 0) + amount;
        }
      }
    }
    // Sélectionner la première année par défaut
      if (_groupedExpenses.isNotEmpty) {
        _selectedYear = _groupedExpenses.keys.first;
        if (_groupedExpenses[_selectedYear]!.isNotEmpty) {
          _selectedMonth = _groupedExpenses[_selectedYear]!.keys.first;
        }
      }
  }

  String _getMonthName(String monthNumber) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final monthInt = int.tryParse(monthNumber) ?? 0;
    return monthInt > 0 && monthInt <= 12 ? months[monthInt] : monthNumber;
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Date inconnue';
    final date = DateTime.tryParse(dateString);
    if (date == null) return dateString;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  //   String _formatDate(String isoDate) {
  //   final date = DateTime.parse(isoDate);
  //   return DateFormat('dd/MM/yyyy').format(date);
  // }

  // void _showImageDialog(BuildContext context, String imageBase64) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => Dialog(
  //       child: Container(
  //         constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
  //         child: Hero(
  //           tag: 'expense_image_$imageBase64',
  //           child: Image.memory(
  //             UriData.parse(imageBase64).contentAsBytes(),
  //             fit: BoxFit.contain,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Future<void> _loadExpenses() async {
    try {
      final data = await _supabaseService.getExpenses();
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
      _groupExpensesByDate();
    } catch (e) {
      print('❌ Erreur de chargement des dépenses : $e');
      setState(() {
        _isLoading = false;
      });
    }
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

Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Année:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _groupedExpenses.keys.map((year) => 
              ChoiceChip(
                label: Text(year),
                selected: _selectedYear == year,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedYear = year;
                      _selectedMonth = _groupedExpenses[year]!.keys.first;
                    });
                  }
                },
              )
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    if (_selectedYear.isEmpty || _groupedExpenses[_selectedYear] == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mois:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _groupedExpenses[_selectedYear]!.keys.map((month) => 
              ChoiceChip(
                label: Text(_getMonthName(month)),
                selected: _selectedMonth == month,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMonth = month;
                    });
                  }
                },
              )
            ).toList(),
          ),
        ],
      ),
    );
  }


    Widget _buildCategoryChart() {
    if (_selectedYear.isEmpty || _selectedMonth.isEmpty ||
        _groupedExpenses[_selectedYear]?[_selectedMonth] == null) {
      return const Center(child: Text('Aucune donnée à afficher'));
    }

    final monthData = _groupedExpenses[_selectedYear]![_selectedMonth]!;
    final total = monthData.values.fold(0.0, (sum, amount) => sum + amount);
    
    if (total == 0) {
      return const Center(child: Text('Aucune dépense ce mois-ci'));
    }

    final sections = monthData.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        Text(
          'Répartition par catégorie - ${_getMonthName(_selectedMonth)} $_selectedYear',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: monthData.entries.map((entry) => 
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: _getCategoryColor(entry.key),
                ),
                const SizedBox(width: 4),
                Text('${entry.key}: ${entry.value.toStringAsFixed(2)}€'),
              ],
            )
          ).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: ${total.toStringAsFixed(2)}€',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }


  Widget _buildMonthlyChart() {
    if (_selectedYear.isEmpty || _groupedExpenses[_selectedYear] == null) {
      return const Center(child: Text('Aucune donnée à afficher'));
    }

    final yearData = _groupedExpenses[_selectedYear]!;
    final monthlyTotals = <String, double>{};
    
    for (var month in yearData.keys) {
      monthlyTotals[month] = yearData[month]!.values.fold(0.0, (sum, amount) => sum + amount);
    }

    final sortedMonths = monthlyTotals.keys.toList()..sort();
    final barGroups = sortedMonths.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: monthlyTotals[entry.value]!,
            color: Colors.blue,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        Text(
          'Total mensuel - $_selectedYear',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < sortedMonths.length) {
                        return Text(_getMonthName(sortedMonths[value.toInt()]));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}€'),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true),
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[category.hashCode % colors.length];
  }

  Widget _buildExpenseCards() {
    final filteredExpenses = _expenses.where((expense) {
      final dateStr = expense['date'] ?? '';
      if (dateStr.isEmpty) return false;
      
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      
      final year = date.year.toString();
      final month = date.month.toString().padLeft(2, '0');
      
      return year == _selectedYear && month == _selectedMonth;
    }).toList();

    if (filteredExpenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucune dépense pour cette période'),
        ),
      );
    }

    // En mode graphique, limiter l'affichage à 5 éléments avec un bouton "Voir plus"
    final displayCount = _showGraphics && !_showExpenseList ? 5 : filteredExpenses.length;
    final limitedExpenses = filteredExpenses.take(displayCount).toList();
    final hasMore = filteredExpenses.length > displayCount;

    return Column(
      children: [
        if (_showGraphics && filteredExpenses.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.receipt, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${filteredExpenses.length} dépense${filteredExpenses.length > 1 ? 's' : ''} - ${_getMonthName(_selectedMonth)} $_selectedYear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: limitedExpenses.length,
          itemBuilder: (context, index) {
            final expense = limitedExpenses[index];
            final amount = expense['amount'] ?? '?';
            final category = expense['category'] ?? '?';
            final date = expense['date'] ?? '';
            final imageBase64 = expense['image_base64'] ?? '';
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: _showGraphics ? 1 : 2, // Moins d'élévation en mode graphique
              child: ListTile(
                dense: _showGraphics, // Plus compact en mode graphique
                leading: imageBase64.isNotEmpty
                    ? MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showImageDialog(context, imageBase64),
                          child: Hero(
                            tag: 'expense_image_$imageBase64',
                            child: Image.memory(
                              UriData.parse(imageBase64).contentAsBytes(),
                              width: _showGraphics ? 40 : 48,
                              height: _showGraphics ? 40 : 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : Icon(Icons.receipt_long, 
                           size: _showGraphics ? 20 : 24),
                title: Text(
                  '$amount € - $category',
                  style: TextStyle(
                    fontSize: _showGraphics ? 14 : 16,
                  ),
                ),
                subtitle: Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: _showGraphics ? 12 : 14,
                  ),
                ),
              ),
            );
          },
        ),
        
        if (hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showExpenseList = true;
                });
              },
              icon: const Icon(Icons.expand_more),
              label: Text('Voir les ${filteredExpenses.length - displayCount} autres dépenses'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des dépenses'),
        actions: [
          if (_showGraphics)
            IconButton(
              icon: Icon(_showExpenseList ? Icons.visibility_off : Icons.visibility),
              tooltip: _showExpenseList ? 'Masquer la liste' : 'Afficher la liste',
              onPressed: () {
                setState(() {
                  _showExpenseList = !_showExpenseList;
                });
              },
            ),
          IconButton(
            icon: Icon(_showGraphics ? Icons.list : Icons.bar_chart),
            tooltip: _showGraphics ? 'Mode liste' : 'Mode graphiques',
            onPressed: () {
              setState(() {
                _showGraphics = !_showGraphics;
                if (_showGraphics) _showExpenseList = false; // Masquer par défaut en mode graphique
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text('Aucune dépense enregistrée.'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildYearSelector(),
                      _buildMonthSelector(),
                      const SizedBox(height: 16),
                      if (_showGraphics) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildCategoryChart(),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildMonthlyChart(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_showGraphics || _showExpenseList)
                        _buildExpenseCards(),
                    ],
                  ),
                ),
    );
  }

}