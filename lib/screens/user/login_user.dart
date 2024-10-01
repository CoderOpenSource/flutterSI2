import 'package:mapas_api/main.dart';
import 'package:mapas_api/screens/user/register_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _error;

  Future<void> _handleSignIn() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final response = await http.post(
      Uri.parse('http://157.230.227.216/authenticate/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': emailController.text,
        'password': passwordController.text,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Almacenar el token, rol y id
      final token = data['token'] as String?; // El token JWT
      final rol = data['rol'] as String?;     // El rol del usuario
      final userId = data['id'] as int?;      // El ID del usuario
      
      if (token != null && rol != null && userId != null) {
        // Almacenar el token de acceso, el rol y el userId.
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);
        prefs.setString('rol', rol);
        prefs.setString('userId', userId.toString()); // Guardando userId en SharedPreferences
        print("-----TOKEN--------------$token");
        print("Rol: $rol");
        print("User ID: $userId");

        // Navegar a la siguiente pantalla
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MyApp()));
      } else {
        setState(() {
          _error = 'Error: Datos incompletos (token, rol o id no recibidos).';
        });
      }
    } else {
      setState(() {
        _error = 'Error: ${response.statusCode}. ${response.reasonPhrase}';
      });
    }
  } catch (error) {
    print('Authentication error: $error');
    setState(() {
      _error = 'Error: $error';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Widget _loadingOverlay() {
    return _isLoading
        ? Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Espere por favor...",
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          )
        : const SizedBox
            .shrink(); // Oculta el indicador de carga si no se está cargando
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 43, 29, 45),
              Color.fromARGB(0, 201, 187, 187)
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    height: 220,
                    width: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://res.cloudinary.com/dkpuiyovk/image/upload/v1704308472/389464cf-c995-401e-8e2c-0e5158974c00.__CR0_0_600_180_PT0_SX600_V1____ntek6i.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    color: Colors.black.withOpacity(0.7),
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailController,
                            style: const TextStyle(color: Color(0xFF1E272E)),
                            decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_sharp,
                                    color: Color(0xFF1E272E)),
                                labelText: 'Correo electrónico',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF1E272E)),
                                hintText: 'Correo electrónico',
                                hintStyle:
                                    const TextStyle(color: Color(0xFF1E272E)),
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E272E)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E272E)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                focusColor: Colors.transparent),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: passwordController,
                            obscureText: _obscureText,
                            style: const TextStyle(color: Color(0xFF1E272E)),
                            decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF1E272E)),
                                hintText: 'Contraseña',
                                hintStyle:
                                    const TextStyle(color: Color(0xFF1E272E)),
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E272E)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E272E)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: const Color(0xFF1E272E),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                                prefixIcon: const Icon(
                                  Icons.password,
                                  color: Color(0xFF1E272E),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                focusColor: Colors.transparent),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E272E),
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Text(
                                "Iniciar sesión",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                "¿Has olvidado la contraseña?",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
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
                                      builder: (context) =>
                                          const RegisterView()),
                                );
                              },
                              child: const Text(
                                "¿No tienes una cuenta? Regístrate",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                          if (_error != null)
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          _loadingOverlay(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
