import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../domain/models/account_model.dart';
import '../../../domain/models/category_model.dart';
import '../../../domain/models/transaction_model.dart';

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository();
});

// Watch the auth state to get the UID safely
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid;
});

// --- STREAMS ---

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return const Stream.empty();
  
  return ref.watch(firestoreRepositoryProvider).watchAccounts(userId);
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return const Stream.empty();
  
  return ref.watch(firestoreRepositoryProvider).watchCategories(userId);
});

final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return const Stream.empty();
  
  return ref.watch(firestoreRepositoryProvider).watchTransactions(userId);
});

// --- SUMMARY PROVIDERS ---
// Using accountsStreamProvider we can calculate totals dynamically without writing to Firestore

final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountsStreamProvider).value ?? [];
  return accounts.fold(0.0, (sum, acc) => sum + acc.balance);
});

// We can also have an income/expense monthly summary by using transactionsStreamProvider
final currentMonthTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final now = DateTime.now();
  
  return transactions.where((tx) {
    // Basic current month filter
    return tx.createdAt.month == now.month && tx.createdAt.year == now.year;
  }).toList();
});

// This returns [IngresosTotales, GastosTotales]
final monthlySummaryProvider = Provider<Map<String, double>>((ref) {
  final txs = ref.watch(currentMonthTransactionsProvider);
  double inSum = 0;
  double exSum = 0;

  for (final tx in txs) {
    if (tx.type == 'income') {
      inSum += tx.amount;
    } else if (tx.type == 'expense') {
      exSum += tx.amount;
    }
  }

  return {'income': inSum, 'expense': exSum};
});
