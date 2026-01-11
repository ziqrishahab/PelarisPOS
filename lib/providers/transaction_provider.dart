import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  TransactionProvider(this._transactionRepository);

  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _cabangId;

  List<Transaction> get transactions =>
      _filteredTransactions.isNotEmpty || _filterStartDate != null
      ? _filteredTransactions
      : _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setCabangId(String? cabangId) {
    _cabangId = cabangId;
  }

  Future<void> fetchTransactions() async {
    print(
      '[TransactionProvider] fetchTransactions started - cabangId: $_cabangId',
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('[TransactionProvider] Calling API getTransactions...');
      final result = await _transactionRepository.getTransactions(
        cabangId: _cabangId,
        limit: 100,
      );
      _transactions = result['transactions'] as List<Transaction>;
      print('[TransactionProvider] Got ${_transactions.length} transactions');
      _applyFilter();
    } catch (e) {
      print('[TransactionProvider] Error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[TransactionProvider] fetchTransactions finished');
    }
  }

  void filterByDate(DateTime date) {
    _filterStartDate = DateTime(date.year, date.month, date.day);
    _filterEndDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    _applyFilter();
    notifyListeners();
  }

  void filterByDateRange(DateTime start, DateTime end) {
    _filterStartDate = DateTime(start.year, start.month, start.day);
    _filterEndDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    _applyFilter();
    notifyListeners();
  }

  void clearFilter() {
    _filterStartDate = null;
    _filterEndDate = null;
    _filteredTransactions = [];
    notifyListeners();
  }

  void _applyFilter() {
    if (_filterStartDate == null || _filterEndDate == null) {
      _filteredTransactions = [];
      return;
    }

    _filteredTransactions = _transactions.where((t) {
      return t.createdAt.isAfter(_filterStartDate!) &&
          t.createdAt.isBefore(_filterEndDate!.add(const Duration(seconds: 1)));
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
