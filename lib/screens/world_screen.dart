import 'package:flutter/material.dart';

class WorldScreen extends StatelessWidget {
  const WorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Por ahora plantilla; luego conectamos a una API de noticias/eventos mundiales
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.public, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'World - Eventos Mundiales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Aquí aparecerán los eventos importantes del mundo. Conecta una API de noticias para llenarlo automáticamente.',
            ),
          ],
        ),
      ),
    );
  }
}
