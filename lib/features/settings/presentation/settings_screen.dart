import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/notification_listener_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/providers/data_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = user?.displayName ?? user?.email?.split('@').first ?? '';
  }

  void _updateName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameCtrl.text.isNotEmpty) {
      await user.updateDisplayName(_nameCtrl.text.trim());
      // Force UI refresh by reloading auth state if needed, or simply pop a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
      }
    }
  }

  void _confirmClearData() {
    bool clrTxs = true;
    bool clrAccounts = true;
    bool clrCats = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('⚠️ Peligro: Vaciar registros'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selecciona exactamente qué datos deseas eliminar de forma permanente. Esta acción no se puede deshacer.'),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Movimientos y transacciones'),
                  value: clrTxs,
                  onChanged: (val) => setStateSB(() => clrTxs = val!),
                  activeColor: Colors.redAccent,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Cuentas y billeteras'),
                  value: clrAccounts,
                  onChanged: (val) => setStateSB(() => clrAccounts = val!),
                  activeColor: Colors.redAccent,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Etiquetas y Categorías'),
                  value: clrCats,
                  onChanged: (val) => setStateSB(() => clrCats = val!),
                  activeColor: Colors.redAccent,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                onPressed: (!clrTxs && !clrAccounts && !clrCats) ? null : () async {
                  Navigator.pop(ctx);
                  final userId = ref.read(userIdProvider);
                  if (userId != null) {
                    try {
                      await ref.read(firestoreRepositoryProvider).clearData(
                        userId,
                        clearTransactions: clrTxs,
                        clearAccounts: clrAccounts,
                        clearCategories: clrCats,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bóveda limpiada correctamente')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al limpiar: $e')));
                      }
                    }
                  }
                },
                child: const Text('Borrar Selección'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101418) : const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Cómo quieres que te llame',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _updateName,
                  icon: const Icon(Icons.save),
                  label: const Text('Actualizar Nombre'),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Settings
          const Text('Preferencia Visual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: Colors.amber),
              title: const Text('Tema de la Aplicación'),
              subtitle: Text(themeMode == ThemeMode.system ? 'Sistema' : (isDark ? 'Modo Noche' : 'Modo Claro')),
              trailing: Switch(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Laboratorio
          const Text('Súper Poderes & Automatización', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final isGranted = ref.watch(isNotificationPermissionGrantedProvider);
                // Si el gestor de la vista se inicializa por primera vez:
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(notificationServiceProvider).checkAndStartListening();
                });

                return ListTile(
                  leading: Icon(Icons.bolt_rounded, color: isGranted ? Colors.amber : Colors.grey, size: 30),
                  title: const Text('Autodetectar Yape/Plin'),
                  subtitle: Text(isGranted ? 'Escaneando pagos bancarios en vivo' : 'Presiona aquí para dar permiso al app', style: const TextStyle(fontSize: 12)),
                  trailing: Switch(
                    value: isGranted,
                    activeColor: Colors.amber,
                    onChanged: (val) async {
                      if (val) {
                        await NotificationListenerService.requestPermission();
                        await ref.read(notificationServiceProvider).checkAndStartListening();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para desactivarlo revoca directamente los permisos de Notification Access en Android')));
                      }
                    },
                  ),
                );
              }
            )
          ),
          const SizedBox(height: 24),

          // Danger Zone
          const Text('Zona de Peligro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                  title: const Text('Vaciar registros', style: TextStyle(color: Colors.redAccent)),
                  subtitle: const Text('Borra cuentas, etiquetas y pagos', style: TextStyle(fontSize: 12)),
                  onTap: _confirmClearData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
