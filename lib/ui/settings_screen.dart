import 'package:flutter/material.dart';
import 'package:pixel_defender/managers/audio_manager.dart';
import 'package:pixel_defender/services/storage_service.dart';

/// Pantalla de configuración accesible desde el menú principal.
///
/// Controla preferencias de audio (música/efectos, volumen) persistidas
/// vía [StorageService], y ofrece la opción de reiniciar todo el progreso
/// guardado (monedas, logros, mejoras permanentes).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _musicEnabled;
  late bool _sfxEnabled;
  late double _musicVolume;
  late double _sfxVolume;

  @override
  void initState() {
    super.initState();
    _musicEnabled = StorageService.instance.musicEnabled;
    _sfxEnabled = StorageService.instance.sfxEnabled;
    _musicVolume = StorageService.instance.musicVolume;
    _sfxVolume = StorageService.instance.sfxVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: const Text('Ajustes', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Audio'),
          SwitchListTile(
            value: _musicEnabled,
            onChanged: (value) {
              setState(() => _musicEnabled = value);
              AudioManager.instance.toggleMusic(value);
            },
            title: const Text('Música', style: TextStyle(color: Colors.white)),
            activeColor: Colors.deepPurpleAccent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _musicVolume,
              onChanged: _musicEnabled
                  ? (value) {
                      setState(() => _musicVolume = value);
                      AudioManager.instance.setMusicVolume(value);
                    }
                  : null,
              activeColor: Colors.deepPurpleAccent,
            ),
          ),
          SwitchListTile(
            value: _sfxEnabled,
            onChanged: (value) {
              setState(() => _sfxEnabled = value);
              AudioManager.instance.toggleSfx(value);
            },
            title: const Text('Efectos de sonido', style: TextStyle(color: Colors.white)),
            activeColor: Colors.deepPurpleAccent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _sfxVolume,
              onChanged: _sfxEnabled
                  ? (value) {
                      setState(() => _sfxVolume = value);
                      AudioManager.instance.setSfxVolumePersisted(value);
                    }
                  : null,
              activeColor: Colors.deepPurpleAccent,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Progreso'),
          ListTile(
            title: const Text('Reiniciar progreso', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text(
              'Borra monedas, récord, logros y mejoras permanentes',
              style: TextStyle(color: Colors.white38),
            ),
            trailing: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onTap: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        title: const Text('¿Reiniciar progreso?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.instance.clearAll();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
