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
    // Para simplificar, buscaremos la palabra "Plin" en el título o cuerpo
    final title = event.title?.toLowerCase() ?? '';
    final text = event.content?.toLowerCase() ?? '';

    if (title.contains('plin') || text.contains('plin')) {
      final regex = RegExp(r's/ ?([0-9]+(\.[0-9]{1,2})?)');
      final match = regex.firstMatch(text);
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
