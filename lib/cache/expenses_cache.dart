class ExpensesCache {
  static List<Map<String, dynamic>>? _cachedExpenses;
  
  static bool get isLoaded {
    // debugPrint("🧪 Cache chargé ? ${_cachedExpenses != null}");
    return _cachedExpenses != null;
  }

  static List<Map<String, dynamic>>? get expenses => _cachedExpenses;

  static Future<void> load(List<Map<String, dynamic>> expenses) async {
    // debugPrint("📥 Chargement du cache avec ${expenses.length} éléments");
    _cachedExpenses = expenses;
  }

  static void clear() {
    // debugPrint("🧹 Cache vidé");
    _cachedExpenses = null;
  }
}


// class ExpensesCache {
//   static final ExpensesCache _instance = ExpensesCache._internal();

//   factory ExpensesCache() => _instance;

//   ExpensesCache._internal();

//   List<Map<String, dynamic>>? _cachedExpenses;

//   List<Map<String, dynamic>>? get expenses => _cachedExpenses;

//   bool get isLoaded => _cachedExpenses != null;

//   void setExpenses(List<Map<String, dynamic>> expenses) {
//     _cachedExpenses = expenses;
//   }

 
//   void clear() {
//     _cachedExpenses = null;
//   }
// }
