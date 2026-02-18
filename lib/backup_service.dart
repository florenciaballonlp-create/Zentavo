import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Servicio de Backup y Restauración de datos
class BackupService {
  /// Crea un backup completo de todos los datos
  static Future<File> crearBackupCompleto() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Recopilar todos los datos
    final backupData = {
      'version': '1.0',
      'fecha_backup': DateTime.now().toIso8601String(),
      'transacciones': prefs.getString('transacciones'),
      'ahorros': prefs.getString('registros_ahorros'),
      'gastos_fijos': prefs.getString('gastos_fijos'),
      'categorias_personalizadas': prefs.getString('categorias_personalizadas'),
      'monedas_disponibles': prefs.getString('monedas_disponibles'),
      'recurrencias': prefs.getString('transacciones_recurrentes'),
      'perfil': {
        'nombre': prefs.getString('user_name'),
        'email': prefs.getString('user_email'),
        'telefono': prefs.getString('user_phone'),
        'avatar_path': prefs.getString('user_avatar_path'),
      },
      'configuracion': {
        'idioma': prefs.getString('idioma'),
        'moneda_principal': prefs.getString('moneda_principal'),
        'presupuesto_mensual': prefs.getDouble('presupuesto_mensual'),
        'theme_mode': prefs.getString('themeMode'),
        'is_premium': prefs.getBool('is_premium'),
        'premium_end_date': prefs.getString('premium_end_date'),
        'biometria_activada': prefs.getBool('biometria_activada'),
      },
      'estadisticas': {
        'transacciones_creadas': prefs.getInt('transacciones_creadas'),
        'eventos_creados': prefs.getInt('eventos_creados'),
        'total_ahorrado': prefs.getDouble('total_ahorrado'),
      },
    };
    
    // Convertir a JSON
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    
    // Guardar en archivo
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'zentavo_backup_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(jsonString);
    
    return file;
  }

  /// Restaura datos desde un archivo de backup
  static Future<bool> restaurarBackup(File backupFile) async {
    try {
      // Leer archivo
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Verificar versión (para futuras migraciones)
      final version = backupData['version'] as String?;
      if (version == null) {
        throw Exception('Archivo de backup inválido');
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // Restaurar transacciones
      if (backupData['transacciones'] != null) {
        await prefs.setString('transacciones', backupData['transacciones'] as String);
      }
      
      // Restaurar ahorros
      if (backupData['ahorros'] != null) {
        await prefs.setString('registros_ahorros', backupData['ahorros'] as String);
      }
      
      // Restaurar gastos fijos
      if (backupData['gastos_fijos'] != null) {
        await prefs.setString('gastos_fijos', backupData['gastos_fijos'] as String);
      }
      
      // Restaurar categorías personalizadas
      if (backupData['categorias_personalizadas'] != null) {
        await prefs.setString('categorias_personalizadas', backupData['categorias_personalizadas'] as String);
      }
      
      // Restaurar monedas
      if (backupData['monedas_disponibles'] != null) {
        await prefs.setString('monedas_disponibles', backupData['monedas_disponibles'] as String);
      }
      
      // Restaurar recurrencias
      if (backupData['recurrencias'] != null) {
        await prefs.setString('transacciones_recurrentes', backupData['recurrencias'] as String);
      }
      
      // Restaurar perfil
      final perfil = backupData['perfil'] as Map<String, dynamic>?;
      if (perfil != null) {
        if (perfil['nombre'] != null) await prefs.setString('user_name', perfil['nombre'] as String);
        if (perfil['email'] != null) await prefs.setString('user_email', perfil['email'] as String);
        if (perfil['telefono'] != null) await prefs.setString('user_phone', perfil['telefono'] as String);
        if (perfil['avatar_path'] != null) await prefs.setString('user_avatar_path', perfil['avatar_path'] as String);
      }
      
      // Restaurar configuración
      final config = backupData['configuracion'] as Map<String, dynamic>?;
      if (config != null) {
        if (config['idioma'] != null) await prefs.setString('idioma', config['idioma'] as String);
        if (config['moneda_principal'] != null) await prefs.setString('moneda_principal', config['moneda_principal'] as String);
        if (config['presupuesto_mensual'] != null) await prefs.setDouble('presupuesto_mensual', config['presupuesto_mensual'] as double);
        if (config['theme_mode'] != null) await prefs.setString('themeMode', config['theme_mode'] as String);
        if (config['is_premium'] != null) await prefs.setBool('is_premium', config['is_premium'] as bool);
        if (config['premium_end_date'] != null) await prefs.setString('premium_end_date', config['premium_end_date'] as String);
        if (config['biometria_activada'] != null) await prefs.setBool('biometria_activada', config['biometria_activada'] as bool);
      }
      
      // Restaurar estadísticas
      final estadisticas = backupData['estadisticas'] as Map<String, dynamic>?;
      if (estadisticas != null) {
        if (estadisticas['transacciones_creadas'] != null) await prefs.setInt('transacciones_creadas', estadisticas['transacciones_creadas'] as int);
        if (estadisticas['eventos_creados'] != null) await prefs.setInt('eventos_creados', estadisticas['eventos_creados'] as int);
        if (estadisticas['total_ahorrado'] != null) await prefs.setDouble('total_ahorrado', estadisticas['total_ahorrado'] as double);
      }
      
      return true;
    } catch (e) {
      print('Error al restaurar backup: $e');
      return false;
    }
  }

  /// Crea un backup automático si han pasado más de X días
  static Future<void> verificarBackupAutomatico() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimoBackup = prefs.getString('ultimo_backup_automatico');
    
    DateTime? fechaUltimoBackup;
    if (ultimoBackup != null) {
      fechaUltimoBackup = DateTime.tryParse(ultimoBackup);
    }
    
    // Crear backup automático cada 7 días
    final ahora = DateTime.now();
    if (fechaUltimoBackup == null || ahora.difference(fechaUltimoBackup).inDays >= 7) {
      try {
        await crearBackupCompleto();
        await prefs.setString('ultimo_backup_automatico', ahora.toIso8601String());
        print('[BACKUP] Backup automático creado exitosamente');
      } catch (e) {
        print('[BACKUP] Error al crear backup automático: $e');
      }
    }
  }

  /// Lista todos los archivos de backup disponibles
  static Future<List<File>> listarBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      final backupFiles = files
          .whereType<File>()
          .where((file) => file.path.contains('zentavo_backup_') && file.path.endsWith('.json'))
          .toList();
      
      // Ordenar por fecha (más reciente primero)
      backupFiles.sort((a, b) => b.path.compareTo(a.path));
      
      return backupFiles;
    } catch (e) {
      print('Error al listar backups: $e');
      return [];
    }
  }

  /// Elimina backups antiguos, dejando solo los últimos N
  static Future<void> limpiarBackupsAntiguos({int mantener = 5}) async {
    try {
      final backups = await listarBackups();
      
      if (backups.length <= mantener) return;
      
      // Eliminar los más antiguos
      final aEliminar = backups.sublist(mantener);
      for (final file in aEliminar) {
        await file.delete();
        print('[BACKUP] Eliminado backup antiguo: ${file.path}');
      }
    } catch (e) {
      print('Error al limpiar backups antiguos: $e');
    }
  }

  /// Obtiene información de un backup sin restaurarlo
  static Future<Map<String, dynamic>?> obtenerInfoBackup(File backupFile) async {
    try {
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Contar registros
      int transacciones = 0;
      if (backupData['transacciones'] != null) {
        final trans = jsonDecode(backupData['transacciones'] as String) as List;
        transacciones = trans.length;
      }
      
      int ahorros = 0;
      if (backupData['ahorros'] != null) {
        final ahorro = jsonDecode(backupData['ahorros'] as String) as List;
        ahorros = ahorro.length;
      }
      
      return {
        'fecha': backupData['fecha_backup'],
        'transacciones': transacciones,
        'ahorros': ahorros,
        'version': backupData['version'],
      };
    } catch (e) {
      print('Error al obtener info de backup: $e');
      return null;
    }
  }
}
