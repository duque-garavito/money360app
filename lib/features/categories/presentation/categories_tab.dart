import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/category_model.dart';
import '../../shared/providers/data_providers.dart';
import '../../auth/providers/auth_provider.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: categoriesAsync.when(
        data: (categories) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 120, top: 16),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return _buildAddCategoryButton(context, isDark);
              }
              final category = categories[index];
              return _buildCategoryCard(context, category, isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category, bool isDark) {
    Color catColor;
    try {
      catColor = Color(int.parse(category.color.replaceFirst('#', '0xff')));
    } catch (_) {
      catColor = Colors.grey;
    }

    final isIncome = category.type == 'income';
    final typeIcon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final typeText = isIncome ? 'Ingreso' : 'Gasto';

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
            builder: (context) => _AddCategoryForm(initialData: category),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: catColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.label_rounded, color: catColor, size: 28),
        ),
        title: Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(typeIcon, size: 14, color: isIncome ? Colors.green : Colors.red),
            const SizedBox(width: 4),
            Text(typeText),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () {
            // Delete logic can go here (future implementation)
          },
        ),
      ),
      ),
    );
  }

  Widget _buildAddCategoryButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showAddCategorySheet(context),
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
              'Crear Nueva Etiqueta',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddCategoryForm(),
    );
  }
}

class _AddCategoryForm extends ConsumerStatefulWidget {
  final CategoryModel? initialData;
  const _AddCategoryForm({this.initialData});
  @override
  ConsumerState<_AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends ConsumerState<_AddCategoryForm> {
  final _nameCtrl = TextEditingController();
  late String _type;
  late String _color; 

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameCtrl.text = widget.initialData!.name;
      _type = widget.initialData!.type;
      _color = widget.initialData!.color;
    } else {
      _type = 'expense';
      _color = '#f44336';
    }
  }

  final Map<String, String> _types = {
    'income': 'Ingreso',
    'expense': 'Gasto',
  };

  final List<String> _colors = [
    '#f44336', '#e91e63', '#9c27b0', '#673ab7', '#3f51b5', '#2196f3',
    '#03a9f4', '#00bcd4', '#009688', '#4caf50', '#8bc34a', '#cddc39',
    '#ffeb3b', '#ffc107', '#ff9800', '#ff5722',
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
                Text(widget.initialData == null ? 'Nueva Etiqueta' : 'Editar Etiqueta', 
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
              decoration: const InputDecoration(labelText: 'Nombre (Ej: Transporte, Salario)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              items: _types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'Naturaleza (Ingreso / Gasto)'),
            ),
            const SizedBox(height: 16),
            Text('Color Representativo', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((c) {
                final isSelected = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(int.parse(c.replaceFirst('#', '0xff'))),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black87, width: 3) : null,
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
                child: const Text('Guardar Etiqueta'),
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

    final category = CategoryModel(
      id: widget.initialData?.id ?? '',
      name: _nameCtrl.text.trim(),
      type: _type,
      color: _color,
    );

    try {
      if (widget.initialData != null) {
        await ref.read(firestoreRepositoryProvider).updateCategory(userId, category);
      } else {
        await ref.read(firestoreRepositoryProvider).createCategory(userId, category);
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
        content: const Text('¿Deseas eliminar esta etiqueta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = ref.read(userIdProvider);
              if (userId != null && widget.initialData != null) {
                await ref.read(firestoreRepositoryProvider).deleteCategory(userId, widget.initialData!.id);
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
