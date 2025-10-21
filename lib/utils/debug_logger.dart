import 'package:flutter/foundation.dart';

class DebugLogger {
  static const String _prefix = 'STORIES_DEBUG';
  
  static void log(String level, String component, String action, [Map<String, dynamic>? data, String? error]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final logData = {
        'timestamp': timestamp,
        'level': level,
        'component': component,
        'action': action,
        if (data != null) 'data': data,
        if (error != null) 'error': error,
      };
      
      print('$_prefix [$level] [$component] $action: $logData');
    }
  }
  
  static void info(String component, String action, [Map<String, dynamic>? data]) {
    log('INFO', component, action, data);
  }
  
  static void debug(String component, String action, [Map<String, dynamic>? data]) {
    log('DEBUG', component, action, data);
  }
  
  static void error(String component, String action, String error, [Map<String, dynamic>? data]) {
    log('ERROR', component, action, data, error);
  }
  
  static void success(String component, String action, [Map<String, dynamic>? data]) {
    log('SUCCESS', component, action, data);
  }
}