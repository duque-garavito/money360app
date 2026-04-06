import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/account_model.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/transaction_model.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- STREAMS (READ) ---
  
  Future<void> logDebugEvent(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).collection('debug_events').add({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch(e) {}
  }


  Stream<List<Account>> watchAccounts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<CategoryModel>> watchCategories(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // --- ACCOUNTS (CRUD) ---

  Future<void> createAccount(String userId, Account account) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc();
    
    // Convert to JSON and remove ID, since ID is the document ID
    final data = account.toJson()..remove('id');
    await docRef.set(data);
  }

  Future<void> updateAccount(String userId, Account account) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(account.id)
        .update(account.toJson()..remove('id'));
  }

  // --- CATEGORIES (CRUD) ---

  Future<void> createCategory(String userId, CategoryModel category) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc();
    
    await docRef.set(category.toJson()..remove('id'));
  }

  // --- TRANSACTIONS (CORE MOTOR LOGIC) ---

  Future<void> createTransaction(String userId, TransactionModel transaction) async {
    final batch = _firestore.batch();

    final txRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc();

    final txData = transaction.toJson()..remove('id');
    batch.set(txRef, txData);

    if (transaction.type == 'income' || transaction.type == 'expense') {
      final accountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(transaction.accountId);

      final balanceChange = transaction.type == 'income' 
          ? transaction.amount 
          : -transaction.amount;

      batch.update(accountRef, {
        'balance': FieldValue.increment(balanceChange),
      });

    } else if (transaction.type == 'transfer') {
      final originRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(transaction.accountId);
          
      final destRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(transaction.categoryId);

      batch.update(originRef, {
        'balance': FieldValue.increment(-transaction.amount),
      });
      batch.update(destRef, {
        'balance': FieldValue.increment(transaction.amount),
      });
    }

    await batch.commit();
  }

  Future<void> deleteTransaction(String userId, TransactionModel transaction) async {
    final batch = _firestore.batch();

    final txRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id);

    batch.delete(txRef);

    if (transaction.type == 'income' || transaction.type == 'expense') {
      final accountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(transaction.accountId);

      // Revert the balance
      final balanceChange = transaction.type == 'income' 
          ? -transaction.amount 
          : transaction.amount;

      batch.update(accountRef, {
        'balance': FieldValue.increment(balanceChange),
      });

    } else if (transaction.type == 'transfer') {
      final originRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(transaction.accountId);
          
      final destRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(transaction.categoryId);

      // Revert the transfer
      batch.update(originRef, {
        'balance': FieldValue.increment(transaction.amount),
      });
      batch.update(destRef, {
        'balance': FieldValue.increment(-transaction.amount),
      });
    }

    await batch.commit();
  }

  Future<void> updateTransaction(String userId, TransactionModel oldTx, TransactionModel newTx) async {
    final batch = _firestore.batch();
    
    // Reverse old
    if (oldTx.type == 'income' || oldTx.type == 'expense') {
      final accRef = _firestore.collection('users').doc(userId).collection('accounts').doc(oldTx.accountId);
      final change = oldTx.type == 'income' ? -oldTx.amount : oldTx.amount;
      batch.update(accRef, {'balance': FieldValue.increment(change)});
    } else if (oldTx.type == 'transfer') {
      final oRef = _firestore.collection('users').doc(userId).collection('accounts').doc(oldTx.accountId);
      final dRef = _firestore.collection('users').doc(userId).collection('accounts').doc(oldTx.categoryId);
      batch.update(oRef, {'balance': FieldValue.increment(oldTx.amount)});
      batch.update(dRef, {'balance': FieldValue.increment(-oldTx.amount)});
    }

    // Apply new
    final txRef = _firestore.collection('users').doc(userId).collection('transactions').doc(oldTx.id);
    batch.set(txRef, newTx.toJson()..remove('id'));

    if (newTx.type == 'income' || newTx.type == 'expense') {
      final accRef = _firestore.collection('users').doc(userId).collection('accounts').doc(newTx.accountId);
      final change = newTx.type == 'income' ? newTx.amount : -newTx.amount;
      batch.update(accRef, {'balance': FieldValue.increment(change)});
    } else if (newTx.type == 'transfer') {
      final oRef = _firestore.collection('users').doc(userId).collection('accounts').doc(newTx.accountId);
      final dRef = _firestore.collection('users').doc(userId).collection('accounts').doc(newTx.categoryId);
      batch.update(oRef, {'balance': FieldValue.increment(-newTx.amount)});
      batch.update(dRef, {'balance': FieldValue.increment(newTx.amount)});
    }

    await batch.commit();
  }

  Future<void> updateCategory(String userId, CategoryModel category) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .update(category.toJson()..remove('id'));
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  Future<void> deleteAccount(String userId, String accountId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  // PELIGRO: Borrar datos de usuario selectivamente
  Future<void> clearData(String userId, {bool clearTransactions = false, bool clearAccounts = false, bool clearCategories = false}) async {
    final batch = _firestore.batch();
    
    if (clearTransactions) {
      final txs = await _firestore.collection('users').doc(userId).collection('transactions').get();
      for (var doc in txs.docs) batch.delete(doc.reference);
    }
    
    if (clearAccounts) {
      final accs = await _firestore.collection('users').doc(userId).collection('accounts').get();
      for (var doc in accs.docs) batch.delete(doc.reference);
    }

    if (clearCategories) {
      final cats = await _firestore.collection('users').doc(userId).collection('categories').get();
      for (var doc in cats.docs) batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
