import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/registro_page.dart';
import 'pages/agenda_page.dart';
import 'pages/notas_page.dart';
import 'pages/recordatorios_page.dart';
import 'pages/perfil_page.dart';
import 'pages/estadisticas_page.dart';

void main() {
  runApp(const DocaveApp());
}

class DocaveApp extends StatelessWidget {
  const DocaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOCAVE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/login',
      routes: {
        '/login':          (_) => LoginPage(),
        '/register':       (_) => RegistroPage(),
        '/home':           (_) => AgendaPage(),
        '/notas':          (_) => NotasPage(),
        '/recordatorios':  (_) => RecordatoriosPage(),
        '/perfil':         (_) => PerfilPage(),
        '/estadisticas':   (_) => EstadisticasPage(),
      },
    );
  }
}