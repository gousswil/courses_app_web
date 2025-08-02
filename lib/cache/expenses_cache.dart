class ExpensesCache {
  static final ExpensesCache _instance = ExpensesCache._internal();

  factory ExpensesCache() => _instance;

  ExpensesCache._internal();

  List<Map<String, dynamic>>? _cachedExpenses;

  List<Map<String, dynamic>>? get expenses => _cachedExpenses;

  bool get isLoaded => _cachedExpenses != null;

  void setExpenses(List<Map<String, dynamic>> expenses) {
    _cachedExpenses = expenses;
  }

  void clear() {
    _cachedExpenses = null;
  }
}
