import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'localization.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  
  String? _avatarPath;
  bool _loading = true;
  String _userId = '';
  List<Map<String, dynamic>> _amigos = [];
  bool _isPremium = false;
  String _planPremium = '';
  DateTime? _fechaExpiracionPremium;
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
  
  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    
    final prefs = await SharedPreferences.getInstance();
    
    // Generar o cargar userId único
    String? userId = prefs.getString('user_id');
    if (userId == null) {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', userId);
    }
    
    // Cargar amigos
    final String? amigosJson = prefs.getString('amigos_list');
    List<Map<String, dynamic>> amigos = [];
    if (amigosJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(amigosJson);
        amigos = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        print('Error al cargar amigos: $e');
      }
    }
    
    // Cargar info premium
    final isPremium = prefs.getBool('is_premium') ?? false;
    final planPremium = prefs.getString('premium_plan') ?? '';
    final fechaExpiracionStr = prefs.getString('premium_expiration');
    DateTime? fechaExpiracion;
    if (fechaExpiracionStr != null) {
      try {
        fechaExpiracion = DateTime.parse(fechaExpiracionStr);
      } catch (e) {
        print('Error al parsear fecha: $e');
      }
    }
    
    setState(() {
      _nombreController.text = prefs.getString('profile_nombre') ?? '';
      _emailController.text = prefs.getString('profile_email') ?? '';
      _telefonoController.text = prefs.getString('profile_telefono') ?? '';
      _avatarPath = prefs.getString('profile_avatar');
      _userId = userId!; // Safe porque lo generamos arriba si es null
      _amigos = amigos;
      _isPremium = isPremium;
      _planPremium = planPremium;
      _fechaExpiracionPremium = fechaExpiracion;
      _loading = false;
    });
  }
  
  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_nombre', _nombreController.text);
    await prefs.setString('profile_email', _emailController.text);
    await prefs.setString('profile_telefono', _telefonoController.text);
    
    if (mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.perfilActualizadoExito),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _seleccionarAvatar() async {
    final loc = AppLocalizations.of(context);
    // En Windows, la cámara no está soportada por image_picker
    final bool isWindows = !kIsWeb && Platform.isWindows;
    
    ImageSource? source;
    
    if (isWindows) {
      // Solo mostrar opción de galería en Windows
      source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.seleccionarFoto),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.camaraNoDisponibleWindows,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0EA5A4)),
                title: Text(loc.seleccionarDeGaleria),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    } else {
      // En móvil, mostrar ambas opciones
      source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.seleccionarFoto),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0EA5A4)),
                title: Text(loc.tomarFoto),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0EA5A4)),
                title: Text(loc.galeria),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    }
    
    if (source == null) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
    
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_avatar', image.path);
        setState(() {
          _avatarPath = image.path;
        });
        
        if (mounted) {
          final loc = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.fotoPerfilActualizada),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorSeleccionarImagen(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _eliminarAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_avatar');
    setState(() {
      _avatarPath = null;
    });
    
    if (mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.fotoPerfilEliminada),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _mostrarCodigoQR() async {
    final loc = AppLocalizations.of(context);
    final nombre = _nombreController.text.trim().isEmpty 
        ? loc.usuario 
        : _nombreController.text.trim();
    
    final datosQR = jsonEncode({
      'userId': _userId,
      'nombre': nombre,
    });
    
    print('Generando QR con datos: $datosQR'); // Debug
    print('Longitud de datos: ${datosQR.length}'); // Debug
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Row(
                children: [
                  const Icon(Icons.qr_code_2, color: Color(0xFF0EA5A4), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    loc.miCodigoQR,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                loc.compartirCodigoQR,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Contenedor del QR con tamaño fijo
              Container(
                width: 280,
                height: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0EA5A4), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: datosQR,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 20),
              
              // Info del usuario
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5A4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0EA5A4).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0EA5A4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_userId.length > 12 ? _userId.substring(0, 12) + '...' : _userId}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5A4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(loc.cerrar, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _escanearQR() async {
    final loc = AppLocalizations.of(context);
    // En Windows, el escáner de QR puede no estar disponible
    if (!kIsWeb && Platform.isWindows) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.escanerQRNoDisponibleWindows),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
    
    if (result != null && result is String) {
      try {
        final datos = jsonDecode(result) as Map<String, dynamic>;
        final userId = datos['userId'] as String?;
        final nombre = datos['nombre'] as String? ?? loc.usuario;
        
        if (userId == null || userId == _userId) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.noPuedesAgregarteATiMismo),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Verificar si ya está agregado
        final yaAgregado = _amigos.any((amigo) => amigo['userId'] == userId);
        if (yaAgregado) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.usuarioYaEnListaAmigos),
              ),
            );
          }
          return;
        }
        
        // Agregar amigo
        setState(() {
          _amigos.add({
            'userId': userId,
            'nombre': nombre,
            'fechaAgregado': DateTime.now().toIso8601String(),
          });
        });
        
        // Guardar
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('amigos_list', jsonEncode(_amigos));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.amigoAgregadoExito(nombre)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.codigoQRInvalido),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _eliminarAmigo(int index) async {
    final loc = AppLocalizations.of(context);
    final amigo = _amigos[index];
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.eliminarAmigoTitulo),
        content: Text(loc.eliminarAmigoConfirmacion(amigo['nombre'] ?? loc.usuario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.eliminar),
          ),
        ],
      ),
    );
    
    if (confirmar == true) {
      setState(() {
        _amigos.removeAt(index);
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('amigos_list', jsonEncode(_amigos));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.amigoEliminado),
          ),
        );
      }
    }
  }
  
  String _calcularTiempoRestante(AppStrings loc) {
    if (_fechaExpiracionPremium == null) return 'N/A';
    
    final ahora = DateTime.now();
    final diferencia = _fechaExpiracionPremium!.difference(ahora);
    
    if (diferencia.isNegative) return loc.expirado;
    
    if (diferencia.inDays > 30) {
      final meses = (diferencia.inDays / 30).floor();
      return '$meses ${loc.mes(meses)}';
    } else if (diferencia.inDays > 0) {
      return '${diferencia.inDays} ${loc.dia(diferencia.inDays)}';
    } else {
      return '${diferencia.inHours} ${loc.hora(diferencia.inHours)}';
    }
  }
  
  String _formatearFecha(dynamic fechaStr, AppStrings loc) {
    if (fechaStr == null) return loc.fechaDesconocida;
    
    try {
      final fecha = DateTime.parse(fechaStr.toString());
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fecha);
      
      if (diferencia.inDays == 0) {
        return loc.hoy;
      } else if (diferencia.inDays == 1) {
        return loc.ayer;
      } else if (diferencia.inDays < 7) {
        return loc.haceDias(diferencia.inDays);
      } else if (diferencia.inDays < 30) {
        final semanas = (diferencia.inDays / 7).floor();
        return loc.haceSemanas(semanas);
      } else if (diferencia.inDays < 365) {
        final meses = (diferencia.inDays / 30).floor();
        return loc.haceMeses(meses);
      } else {
        final anios = (diferencia.inDays / 365).floor();
        return loc.haceAnios(anios);
      }
    } catch (e) {
      return loc.fechaDesconocida;
    }
  }
  
  Widget _buildAvatar() {
    if (_avatarPath != null && File(_avatarPath!).existsSync()) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(File(_avatarPath!)),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF0EA5A4).withOpacity(0.2),
        child: Icon(
          Icons.person,
          size: 60,
          color: const Color(0xFF0EA5A4),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.miPerfil),
        backgroundColor: const Color(0xFF0EA5A4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarDatos,
            tooltip: loc.guardarCambios,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      _buildAvatar(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5A4),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: PopupMenuButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            offset: const Offset(0, 40),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'cambiar',
                                child: Row(
                                  children: [
                                    const Icon(Icons.photo_library, size: 20),
                                    const SizedBox(width: 8),
                                    Text(loc.cambiarFoto),
                                  ],
                                ),
                              ),
                              if (_avatarPath != null)
                                PopupMenuItem(
                                  value: 'eliminar',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete, size: 20, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(loc.eliminarFoto, style: const TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                            onSelected: (value) {
                              if (value == 'cambiar') {
                                _seleccionarAvatar();
                              } else if (value == 'eliminar') {
                                _eliminarAvatar();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Información personal
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: Color(0xFF0EA5A4)),
                              const SizedBox(width: 8),
                              Text(
                                loc.informacionPersonal,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _nombreController,
                            decoration: InputDecoration(
                              labelText: loc.nombreCompleto,
                              prefixIcon: const Icon(Icons.person_outline),
                              border: const OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: loc.correoElectronico,
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _telefonoController,
                            decoration: InputDecoration(
                              labelText: loc.telefono,
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Código QR y Amigos
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.qr_code, color: Color(0xFF0EA5A4)),
                              const SizedBox(width: 8),
                              Text(
                                loc.conectarConAmigos,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _mostrarCodigoQR,
                                  icon: const Icon(Icons.qr_code_2),
                                  label: Text(loc.miCodigoQR),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0EA5A4),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _escanearQR,
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: Text(loc.escanear),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.misAmigos,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_amigos.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          if (_amigos.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.noTienesAmigosAgregados,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc.escanearQRParaAgregar,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _amigos.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final amigo = _amigos[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF0EA5A4).withOpacity(0.2),
                                    child: Text(
                                      amigo['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                      style: const TextStyle(
                                        color: Color(0xFF0EA5A4),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    amigo['nombre'] ?? loc.usuario,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${loc.agregado}: ${_formatearFecha(amigo['fechaAgregado'], loc)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _eliminarAmigo(index),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Estado Premium
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isPremium ? Icons.workspace_premium : Icons.star_outline,
                                color: _isPremium ? const Color(0xFFF59E0B) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.estadoSuscripcion,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildStatRow(
                            loc.estado,
                            _isPremium ? loc.premiumEstrella : loc.gratuito,
                            Icons.account_circle,
                          ),
                          if (_isPremium) ...[
                            const Divider(),
                            _buildStatRow(
                              loc.plan,
                              _planPremium.isEmpty ? loc.mensual : _planPremium,
                              Icons.card_membership,
                            ),
                            const Divider(),
                            _buildStatRow(
                              loc.tiempoRestante,
                              _calcularTiempoRestante(loc),
                              Icons.schedule,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Estadísticas
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics, color: Color(0xFF0EA5A4)),
                              const SizedBox(width: 8),
                              Text(
                                loc.estadisticasCuenta,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          FutureBuilder<Map<String, dynamic>>(
                            future: _obtenerEstadisticas(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final stats = snapshot.data!;
                              return Column(
                                children: [
                                  _buildStatRow(
                                    'Miembro desde',
                                    stats['fecha_registro'] ?? 'Hoy',
                                    Icons.calendar_today,
                                  ),
                                  const Divider(),
                                  _buildStatRow(
                                    'Transacciones creadas',
                                    '${stats['transacciones'] ?? 0}',
                                    Icons.receipt_long,
                                  ),
                                  const Divider(),
                                  _buildStatRow(
                                    'Eventos compartidos',
                                    '${stats['eventos'] ?? 0}',
                                    Icons.event,
                                  ),
                                  const Divider(),
                                  _buildStatRow(
                                    'Ahorros totales',
                                    stats['ahorros'] ?? '\$0',
                                    Icons.savings,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarDatos,
                      icon: const Icon(Icons.save),
                      label: Text(loc.guardarCambios),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5A4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<Map<String, dynamic>> _obtenerEstadisticas() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Fecha de registro (primera vez que se abrió la app)
    String? fechaRegistro = prefs.getString('fecha_registro');
    if (fechaRegistro == null) {
      fechaRegistro = DateTime.now().toIso8601String();
      await prefs.setString('fecha_registro', fechaRegistro);
    }
    
    final fecha = DateTime.parse(fechaRegistro);
    final diferencia = DateTime.now().difference(fecha);
    String textoFecha;
    if (diferencia.inDays == 0) {
      textoFecha = 'Hoy';
    } else if (diferencia.inDays == 1) {
      textoFecha = 'Hace 1 día';
    } else if (diferencia.inDays < 30) {
      textoFecha = 'Hace ${diferencia.inDays} días';
    } else if (diferencia.inDays < 365) {
      final meses = (diferencia.inDays / 30).floor();
      textoFecha = 'Hace ${meses} ${meses == 1 ? 'mes' : 'meses'}';
    } else {
      final anios = (diferencia.inDays / 365).floor();
      textoFecha = 'Hace ${anios} ${anios == 1 ? 'año' : 'años'}';
    }
    
    // Obtener estadísticas
    final transacciones = prefs.getInt('transacciones_creadas') ?? 0;
    final eventos = prefs.getInt('eventos_creados') ?? 0;
    
    return {
      'fecha_registro': textoFecha,
      'transacciones': transacciones,
      'eventos': eventos,
      'ahorros': '\$0', // Esto se puede calcular dinámicamente si se desea
    };
  }
}

// Pantalla de escaneo de QR
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _scanCompleted = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanCompleted) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _scanCompleted = true);
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.escanearCodigoQR),
        backgroundColor: const Color(0xFF0EA5A4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Overlay con marco
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Coloca el código QR en el marco',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
