import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/account_model.dart';
import '../../shared/providers/data_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class AccountsTab extends ConsumerWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Deja ver el fondo del Dashboard
      body: accountsAsync.when(
        data: (accounts) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 120, top: 16),
            itemCount: accounts.length + 1, // +1 para el botón de agregar
            itemBuilder: (context, index) {
              if (index == accounts.length) {
                return _buildAddAccountButton(context, isDark);
              }
              final account = accounts[index];
              return _buildAccountCard(context, account, isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account, bool isDark) {
    Color accColor;
    try {
      accColor = Color(int.parse(account.color.replaceFirst('#', '0xff')));
    } catch (_) {
      accColor = Colors.grey;
    }

    IconData typeIcon;
    switch (account.type) {
      case 'cash':
        typeIcon = Icons.payments_rounded;
        break;
      case 'bank':
        typeIcon = Icons.account_balance_rounded;
        break;
      case 'credit':
        typeIcon = Icons.credit_card_rounded;
        break;
      case 'saving':
        typeIcon = Icons.savings_rounded;
        break;
      case 'digital':
        typeIcon = Icons.qr_code_scanner_rounded;
        break;
      default:
        typeIcon = Icons.wallet_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            builder: (context) => _AddAccountForm(initialData: account),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(typeIcon, color: accColor, size: 28),
        ),
        title: Text(
          account.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Balance actual'),
        trailing: Text(
          CurrencyFormatter.format(account.balance),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: account.balance >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildAddAccountButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showAddAccountSheet(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Añadir Nueva Cuenta',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddAccountForm(),
    );
  }
}

class _AddAccountForm extends ConsumerStatefulWidget {
  final Account? initialData;
  const _AddAccountForm({super.key, this.initialData});
  @override
  ConsumerState<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends ConsumerState<_AddAccountForm> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  late String _type;
  late String _color;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameCtrl.text = widget.initialData!.name;
      _balanceCtrl.text = widget.initialData!.balance.toString();
      _type = widget.initialData!.type;
      _color = widget.initialData!.color;
    } else {
      _type = 'bank';
      _color = '#2196f3';
    }
  }

  final Map<String, String> _types = {
    'cash': 'Efectivo',
    'bank': 'Banco',
    'credit': 'Tarjeta de Crédito',
    'saving': 'Ahorros',
    'digital': 'Billetera Digital (Yape, Plin...)',
  };

  final List<String> _colors = [
    '#f44336', // Rojo
    '#e91e63', // Rosa
    '#9c27b0', // Morado
    '#3f51b5', // Índigo
    '#2196f3', // Azul
    '#00bcd4', // Cian
    '#4caf50', // Verde
    '#ff9800', // Naranja
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16213E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.initialData == null ? 'Nueva Cuenta' : 'Editar Cuenta', 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (widget.initialData != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de cuenta (Ej: BCP)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Saldo Inicial'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              items: _types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((c) {
                final isSelected = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(c.replaceFirst('#', '0xff'))),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text('Crear Cuenta'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _save() async {
    final userId = ref.read(userIdProvider);
    if (userId == null || _nameCtrl.text.isEmpty) return;

    final account = Account(
      id: widget.initialData?.id ?? '', // Firestore auto-generates si esta vacio
      name: _nameCtrl.text.trim(),
      type: _type,
      balance: double.tryParse(_balanceCtrl.text) ?? 0.0,
      color: _color,
      createdAt: widget.initialData?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.initialData != null) {
        await ref.read(firestoreRepositoryProvider).updateAccount(userId, account);
      } else {
        await ref.read(firestoreRepositoryProvider).createAccount(userId, account);
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
        content: const Text('¿Deseas eliminar esta cuenta? Asegúrate de que no tenga movimientos o podría causar inconsistencias.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = ref.read(userIdProvider);
              if (userId != null && widget.initialData != null) {
                await ref.read(firestoreRepositoryProvider).deleteAccount(userId, widget.initialData!.id);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
