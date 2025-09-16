import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configuración de Notificaciones')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Notificaciones generales'),
              subtitle: Text('Activar todas las notificaciones'),
              value: true,
              onChanged: (value) {
                // Implementar lógica
              },
            ),
            // Más opciones de configuración...
          ],
        ),
      ),
    );
  }
}
