import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapas_api/auth/register_page.dart';
import 'package:mapas_api/auth/home_chofer.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapas_api/screens/home_pasajero.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isSigningIn = false;
  bool _obscureText = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 134, 234, 138),
                Color.fromARGB(255, 41, 76, 1)
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Driver Express',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(150),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://firebasestorage.googleapis.com/v0/b/driverexpress-ff785.appspot.com/o/carrousel_slider%2Fdriverexpress%20.png?alt=media&token=22843c75-40ec-49a0-beda-22c2c933fb21'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  color: const Color.fromARGB(255, 16, 132, 3).withOpacity(0.7),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Iniciar sesión:",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            labelStyle: const TextStyle(color: Colors.white),
                            hintText: 'Correo electrónico',
                            hintStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(
                              // Icono de correo
                              Icons.mail_outline,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscureText,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: const TextStyle(color: Colors.white),
                            hintText: 'Contraseña',
                            hintStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _handleSignIn();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 41, 76, 1),
                              padding: const EdgeInsets.all(12),
                            ),
                            child: const Text(
                              "Iniciar sesión",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              FontAwesomeIcons.google,
                              color: Colors.red,
                              size: 18,
                            ),
                            label: const Text(
                              "Inicia sesión con Google",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.red[600],
                              backgroundColor:
                                  const Color.fromARGB(255, 41, 76, 1),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              "¿Has olvidado la contraseña?",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RegisterView()),
                              );
                            },
                            child: const Text(
                              "¿No tienes una cuenta? Regístrate",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isSigningIn) _loadingOverlay(),
      ]),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5), // Fondo semi-transparente
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Espere por favor...", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _handleSignIn() async {
    setState(() {
      _isSigningIn = true; // Actualizamos el estado a 'iniciando sesión'
    });

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (userCredential.user != null) {
        final String userId = userCredential.user!.uid;

        // Aquí, obtén el modo del usuario (chofer o pasajero) de la base de datos
        final String userMode = await getUserMode(userId);

        if (mounted) {
          // Comprueba si el widget todavía está montado
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario logeado con éxito'),
              backgroundColor: Colors.green,
            ),
          );

          await Future.delayed(const Duration(seconds: 2));

          // Esperar un momento antes de redirigir para que el usuario pueda leer el mensaje
          await Future.delayed(const Duration(seconds: 2));

          // Redirigir al usuario a la página de inicio correspondiente basándote en su modo
          if (userMode == 'Conductor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeChofer()),
            );
          } else if (userMode == 'Pasajero') {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapScreen(),
                ));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Ha ocurrido un error desconocido';

      if (e.code == 'user-not-found') {
        message =
            'No hay registro de usuario correspondiente a ese identificador. El usuario puede haber sido eliminado.';
      } else if (e.code == 'wrong-password') {
        message = 'La contraseña proporcionada es incorrecta.';
      }

      // Mostrar el mensaje en un SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Asegurémonos de que, sin importar el resultado, el indicador se detenga al final
      setState(() {
        _isSigningIn = false; // Actualizamos el estado a 'no iniciando sesión'
      });
    }
  }

  Future<String> getUserMode(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Obtiene el documento del usuario por su ID
    DocumentSnapshot userDoc =
        await firestore.collection('Usuarios').doc(userId).get();

    // Verifica si el documento existe
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Si el mapa contiene el campo 'modo', retorna ese campo
      if (userData.containsKey('modo')) {
        return userData['modo'] as String;
      }
    }

    // Retorna un valor predeterminado o lanza un error si no se encontró el campo 'modo'
    throw Exception('Modo de usuario no encontrado');
  }
}
