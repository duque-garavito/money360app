import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../../features/transactions/services/notification_parser_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/shared/providers/data_providers.dart'; // Corrección
import '../../data/repositories/firestore_repository.dart'; // Faltaba para firestoreRepositoryProvider
import '../../domain/models/transaction_model.dart';
import 'package:notification_listener_service/notification_event.dart';

class NotificationPermissionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setGranted(bool value) {
    state = value;
  }
}

final isNotificationPermissionGrantedProvider = NotifierProvider<NotificationPermissionNotifier, bool>(() {
  return NotificationPermissionNotifier();
});

class NotificationService {
  final Ref ref;
  bool _isInitialized = false;

  NotificationService(this.ref);

  Future<void> checkAndStartListening() async {
    if (_isInitialized) return;
    
    final isGranted = await NotificationListenerService.isPermissionGranted();
    ref.read(isNotificationPermissionGrantedProvider.notifier).setGranted(isGranted);



    if (isGranted) {
      _isInitialized = true;
      NotificationListenerService.notificationsStream.listen((event) {
        _processEvent(event);
      });
      debugPrint("Money360 NotifListener: Activado y escuchando oculto.");
    }
  }

  void _processEvent(ServiceNotificationEvent event) async {
    // ignorar notificaciones borradas
    if (event.hasRemoved != null && event.hasRemoved!) return;

    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    


    double? amountYape = NotificationParserService.extractAmountFromYape(event);
    double? amountPlin = NotificationParserService.extractAmountFromPlin(event);

    final resolvedAmount = amountYape ?? amountPlin;
    if (resolvedAmount != null && resolvedAmount > 0) {
      debugPrint("¡DETECTADO INGRESO DE BILLETERA DIGITAL! -> \$resolvedAmount");

      // Buscar si el usuario ya tiene una cuenta mapeada a "digital"
      final accounts = ref.read(accountsStreamProvider).value;
      if (accounts == null || accounts.isEmpty) return;

      final digitalAccount = accounts.cast().firstWhere(
        (a) => a.type == 'digital', 
        orElse: () => accounts.first // Fallback a cualquier cuenta
      );

      // Buscar si tiene alguna etiqueta que diga "Ingreso Yape" o "Transferencia" de tipo income
      final categories = ref.read(categoriesStreamProvider).value ?? [];
      final incomeCat = categories.cast().firstWhere(
        (c) => c.type == 'income',
        orElse: () => null
      );

      // Si no existe categoria de ingreso, se complica guardarlo pero intentaremos:
      final String catId = incomeCat != null ? incomeCat.id : 'unknown_category';

      final String providerName = amountYape != null ? 'Yape' : 'Plin';
      final senderInfo = event.title ?? 'Contacto desconocido';

      final tx = TransactionModel(
        id: '', // Repo generates it
        type: 'income',
        amount: resolvedAmount,
        description: 'Recibido por $providerName ($senderInfo)',
        accountId: digitalAccount.id,
        categoryId: catId,
        date: DateTime.now().toIso8601String().split('T')[0], // Exactamente YYYY-MM-DD
        createdAt: DateTime.now(),
      );

      try {
        await ref.read(firestoreRepositoryProvider).createTransaction(userId, tx);
        debugPrint("✓ Movimiento guardado en Firestore correctamente de forma automática.");
      } catch (e) {
        debugPrint("Error guardando Yape: $e");
      }
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});