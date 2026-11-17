import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter/material.dart';
import 'package:projeto_eletiva/view/cadastro_usuario_view.dart';
import 'package:projeto_eletiva/view/login_view.dart';
import 'package:projeto_eletiva/view/menu_principal_view.dart';
import 'package:projeto_eletiva/view/perfil_view.dart';
import 'package:projeto_eletiva/view/recuperar_senha_view.dart';
import 'package:projeto_eletiva/view/sobre_view.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(DevicePreview(builder: (context) => MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App',

      //
      // Rotas
      //
      
      initialRoute: 'login',
      routes: {
        'login': (context) => LoginView(),
        'menu_principal': (context) => MenuPrincipalView(),
        'cadastrar_usuario': (context) => CadastroUsuarioView(),
        'perfil': (context) => PerfilView(),
        'recuperar_senha': (context) => RecuperarSenhaView(),
        'sobre': (context) => SobreView(),
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => LoginView());
      },
    );
  }
}
