import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';

class NotificationParserService {
  
  static double? extractAmountFromYape(ServiceNotificationEvent event) {
    if (event.packageName != 'com.bcp.innovacxion.yape') return null;
    final title = event.title ?? '';
    final text = event.content ?? '';
    final fullPayload = '$title $text';
    
    // Yape dice: "Yape! CRISTHIAN DUQUE te envió un pago por S/ 1" o "S/ 10.00"
    final regex = RegExp(r'[sS]/\s?([0-9]+(?:[\.,][0-9]{1,2})?)');
    final match = regex.firstMatch(fullPayload);
    
    if (match != null && match.groupCount >= 1) {
      final amountStr = match.group(1)?.replaceAll(',', '.');
      if (amountStr != null) {
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  static double? extractAmountFromPlin(ServiceNotificationEvent event) {
    // Plin usualmente viene desde Interbank, Scotiabank o BBVA
    // Solo procesar notificaciones de INGRESO, ignorar envíos propios
    // Yape usa palabras como "recibiste", "te enviaron", "te pagaron", "te envió"
    final fullText = '${event.title} ${event.content}'.toLowerCase();
    final isIncoming = fullText.contains('recibiste') ||
        fullText.contains('te enviaron') ||
        fullText.contains('te envi') || // Cubre "te envió" ignorando tildes raras
        fullText.contains('te pagaron') ||
        fullText.contains('te transfirieron') ||
        fullText.contains('recibido');

    if (isIncoming && (fullText.contains('plin'))) {
      final regex = RegExp(r's/ ?([0-9]+(\.[0-9]{1,2})?)');
      final match = regex.firstMatch(fullText);
      if (match != null && match.groupCount >= 1) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          return double.tryParse(amountStr);
        }
      }
    }
    return null;
  }
}