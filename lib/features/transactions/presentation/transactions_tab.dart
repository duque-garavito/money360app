import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/transaction_model.dart';
import '../../shared/providers/data_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class TransactionsTab extends ConsumerWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Column(
              children: [
                const Spacer(),
                const Text('Aún no tienes movimientos', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                _buildAddTransactionButton(context, isDark),
                const Spacer(),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 120, top: 16),
            itemCount: transactions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildAddTransactionButton(context, isDark),
                );
              }
              final transaction = transactions[index - 1]; // Offset por el botón
              return _buildTransactionCard(context, ref, transaction, isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, TransactionModel transaction, bool isDark) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    
    IconData typeIcon;
    Color typeColor;

    if (isTransfer) {
      typeIcon = Icons.swap_horiz_rounded;
      typeColor = Colors.blueAccent;
    } else if (isIncome) {
      typeIcon = Icons.arrow_downward_rounded;
      typeColor = Colors.greenAccent[400]!;
    } else {
      typeIcon = Icons.arrow_upward_rounded;
      typeColor = Colors.redAccent[400]!;
    }

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirmar Eliminación"),
              content: const Text("¿Estás seguro de que quieres eliminar esta transacción? Esto revertirá el saldo de la(s) cuenta(s) involucrada(s)."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        final userId = ref.read(userIdProvider);
        if (userId != null) {
          try {
            await ref.read(firestoreRepositoryProvider).deleteTransaction(userId, transaction);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transacción eliminada y saldos revertidos')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
          }
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 30),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: GestureDetector(
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _AddTransactionForm(initialData: transaction),
            );
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            title: Text(
              transaction.description.isNotEmpty ? transaction.description : (isTransfer ? 'Transferencia' : 'Transacción'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              transaction.date.toString().split(' ')[0], // Simple YYYY-MM-DD
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
            ),
            trailing: Text(
              '${isIncome ? '+' : (isTransfer ? '' : '-')}${CurrencyFormatter.format(transaction.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTransactionButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showAddTransactionSheet(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.withOpacity(0.8), Colors.purpleAccent.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Registrar Nuevo Movimiento',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            )
          ],
        ),
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddTransactionForm(),
    );
  }
}

class _AddTransactionForm extends ConsumerStatefulWidget {
  final TransactionModel? initialData;
  const _AddTransactionForm({super.key, this.initialData});
  @override
  ConsumerState<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends ConsumerState<_AddTransactionForm> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late String _type; 
  String? _accountId;      
  String? _categoryId;      

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _amountCtrl.text = widget.initialData!.amount.toString();
      _descCtrl.text = widget.initialData!.description;
      _type = widget.initialData!.type;
      _accountId = widget.initialData!.accountId;
      _categoryId = widget.initialData!.categoryId;
    } else {
      _type = 'expense';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Al leer .value() obtenemos el último estado sincrónicamente del Stream
    final _accounts = ref.watch(accountsStreamProvider).value ?? [];
    final _categories = ref.watch(categoriesStreamProvider).value ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filtrar categorias aplicables
    final applicableCategories = _type == 'transfer' 
        ? [] 
        : _categories.where((c) => c.type == _type).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16213E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.initialData == null ? 'Nuevo Movimiento' : 'Editar Movimiento', 
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (widget.initialData != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
            const SizedBox(height: 24),
          
              // Segmented Button para Tipo
              Row(
                children: [
                  Expanded(child: _buildTypeButton('Gasto', 'expense', Icons.arrow_upward_rounded, Colors.redAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTypeButton('Ingreso', 'income', Icons.arrow_downward_rounded, Colors.greenAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTypeButton('Traspaso', 'transfer', Icons.swap_horiz_rounded, Colors.blueAccent)),
                ],
              ),
              const SizedBox(height: 24),
          
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Monto (\$)', prefixIcon: Icon(Icons.attach_money_rounded)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción corta'),
              ),
              const SizedBox(height: 16),
          
              // Selector de Cuenta Origen
              DropdownButtonFormField<String>(
                value: _accountId,
                hint: Text(_type == 'transfer' ? 'Cuenta de Origen' : 'Cuenta afectada'),
                items: _accounts.map<DropdownMenuItem<String>>((acc) => DropdownMenuItem<String>(value: acc.id, child: Text(acc.name))).toList(),
                onChanged: (v) => setState(() => _accountId = v),
              ),
              const SizedBox(height: 16),
          
              // Selector de Destino o Categoría
              if (_type != 'transfer') ...[
                DropdownButtonFormField<String>(
                  value: _categoryId != null && applicableCategories.any((c) => c.id == _categoryId) ? _categoryId : null,
                  hint: const Text('Etiqueta / Categoría'),
                  items: applicableCategories.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  hint: const Text('Cuenta de Destino'),
                  items: _accounts
                          .where((acc) => acc.id != _accountId) 
                          .map<DropdownMenuItem<String>>((acc) => DropdownMenuItem<String>(value: acc.id, child: Text(acc.name))).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(widget.initialData == null ? 'Confirmar Trámite' : 'Guardar Cambios', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, String typeVal, IconData icon, Color color) {
    final isSelected = _type == typeVal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _type = typeVal;
          _categoryId = null; // Reset category/target on switch
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : (isDark ? Colors.grey[400] : Colors.grey)),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : (isDark ? Colors.grey[400] : Colors.grey),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    final userId = ref.read(userIdProvider);
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;

    if (userId == null || amount <= 0 || _accountId == null || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa los datos e intenta de nuevo')));
      return;
    }

    final transaction = TransactionModel(
      id: widget.initialData?.id ?? '',
      type: _type,
      amount: amount,
      description: _descCtrl.text.trim(),
      accountId: _accountId!,
      categoryId: _categoryId!, 
      date: widget.initialData?.date ?? DateTime.now().toIso8601String(),
      createdAt: widget.initialData?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.initialData != null) {
        await ref.read(firestoreRepositoryProvider).updateTransaction(userId, widget.initialData!, transaction);
      } else {
        await ref.read(firestoreRepositoryProvider).createTransaction(userId, transaction);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Deseas eliminar este movimiento? Se revertirán los saldos automáticamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Cerrar Alert
              final userId = ref.read(userIdProvider);
              if (userId != null && widget.initialData != null) {
                await ref.read(firestoreRepositoryProvider).deleteTransaction(userId, widget.initialData!);
                if (mounted) Navigator.pop(context); // Cerrar BottomSheet
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
