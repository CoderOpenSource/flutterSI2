import 'dart:convert';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/widgets/mis_compras.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: const Text("Perfil de Usuario",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final userData = snapshot.data!;

            return Column(
              children: <Widget>[
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (userData['fotoPerfil'] != null) {
                        _showImagePreview(context, userData['fotoPerfil']);
                      }
                    },
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: userData['fotoPerfil'] != null
                          ? NetworkImage(userData['fotoPerfil'])
                          : null, // Si no hay foto de perfil, se usa 'null' para el backgroundImage
                      backgroundColor: const Color(0xFF1E272E),
                      child: userData['fotoPerfil'] == null
                          ? Icon(
                              Icons.person, // Ícono clásico de perfil
                              size: 80,
                              color: Colors.white,
                            )
                          : null, // Si hay foto de perfil, no se muestra ningún ícono
                    ),
                  ),
                ),
                ListTile(
                  title: const Text(
                    "Nombre:",
                    style: TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    userData['nombre']?? 'Nombre no disponible',
                    style: const TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  leading: const Icon(
                    Icons.person,
                    color: const Color(0xFF1E272E),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6,
                      color: const Color(0xFF1E272E)),
                  title: const Text(
                    "Tema",
                    style: TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    // Acción para cambiar tema
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.mail,
                      color: const Color(0xFF1E272E)),
                  title: const Text(
                    "Email",
                    style: TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    userData['email'] ?? 'Email no encontrado',
                    style: const TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  
                  
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_food_beverage_sharp,
                      color: const Color(0xFF1E272E)),
                  title: const Text(
                    "Mis Compras",
                    style: TextStyle(
                        color: const Color(0xFF1E272E),
                        fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsView2(),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color(0xFF1E272E)),
                    ),
                    onPressed: () {
                      _showLogoutConfirmation(context);
                    },
                    child: const Text(
                      "Cerrar sesión",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Algo salió mal.'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

 Future<Map<String, dynamic>> _fetchUserData(BuildContext context) async {
  // Obtener el token almacenado en SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Obtener el token almacenado
  final String? token = prefs.getString('token');
  if (token == null || token.isEmpty) {
    print('Token no disponible en SharedPreferences');
    throw Exception("Token no encontrado");
  }
  print('Token: $token');  // Imprimir el token para verificar que se obtiene correctamente

  // Obtener el userId almacenado como String
  final String? userIdString = prefs.getString('userId');
  if (userIdString == null) {
    print('User ID no encontrado en SharedPreferences');
    throw Exception("User ID not found");
  }

  // Convertimos el userId a int
  final int userId = int.parse(userIdString);
  print('User ID: $userId');  // Imprimir el User ID para verificar que se obtiene correctamente

  // URL de la API
  final String url = 'http://157.230.227.216/api/usuarios/id/$userId';
  print('URL de la solicitud: $url');  // Imprimir la URL completa para verificar si está correcta

  try {
    // Realizamos la solicitud GET con el token en el encabezado
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',  // Añadir el token en los encabezados
      },
    );

    // Manejo de error de token expirado (401)
    if (response.statusCode == 401) {
      // Mostrar el diálogo de token expirado
      _mostrarDialogoTokenExpirado(context);
      return {};  // Detenemos la ejecución y retornamos un mapa vacío
    }

    // Verificamos el código de estado de la respuesta
    else if (response.statusCode == 200) {
      print('Respuesta recibida correctamente');  // Imprimir si la solicitud fue exitosa
      return jsonDecode(response.body);
    } else {
      // Imprimir el código de estado y el cuerpo de la respuesta para entender mejor el error
      print('Error al obtener datos: Código ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
      throw Exception('Failed to load user data. Código: ${response.statusCode}');
    }
  } catch (error) {
    print('Error durante la solicitud HTTP: $error');
    throw Exception('Error al hacer la solicitud HTTP');
  }
}

// Función para mostrar el diálogo de token expirado
void _mostrarDialogoTokenExpirado(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Token expirado"),
        content: Text("Su sesión ha expirado. Por favor, inicie sesión nuevamente."),
        actions: <Widget>[
          TextButton(
            child: Text("OK"),
            onPressed: () async{
              final prefs = await SharedPreferences.getInstance();

    // Remove the stored preferences
    prefs.remove('token');
    prefs.remove('rol');
    prefs.remove('userId');

    // Navigate to the login page and remove all other screens from the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            const LoginView(), // Assuming your login view is named LoginView
      ),
      (Route<dynamic> route) => false, // This will remove all other screens
    );
            },
          ),
        ],
      );
    },
  );
}

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(ctx);
          },
          child: Container(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration:
                  const BoxDecoration(color: const Color(0xFF1E272E)),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _logout(context);
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove the stored preferences
    prefs.remove('token');
    prefs.remove('rol');
    prefs.remove('userId');

    // Navigate to the login page and remove all other screens from the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            const LoginView(), // Assuming your login view is named LoginView
      ),
      (Route<dynamic> route) => false, // This will remove all other screens
    );
  }
}
