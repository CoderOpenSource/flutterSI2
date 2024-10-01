import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SettingsView2 extends StatefulWidget {
  const SettingsView2({Key? key}) : super(key: key);

  @override
  _SettingsView2State createState() => _SettingsView2State();
}

class _SettingsView2State extends State<SettingsView2> {
  late String userName;
  List<dynamic> displayedTransacciones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserAndTransactions();
  }

  Future<void> fetchUserAndTransactions() async {
    try {
      // Obtener el token y userId de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '0';

      // Obtener los detalles del usuario
      final userResponse = await http.get(
        Uri.parse('http://157.230.227.216/api/usuarios/id/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Error al obtener los detalles del usuario');
      }

      final userData = json.decode(userResponse.body);
      userName = userData['nombre'];

      // Obtener todas las transacciones
      final transaccionesResponse = await http.get(
        Uri.parse('http://157.230.227.216/api/transacciones'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (transaccionesResponse.statusCode != 200) {
        throw Exception('Error al obtener las transacciones');
      }

      final List<dynamic> allTransacciones = json.decode(transaccionesResponse.body);

      // Filtrar las transacciones por nombre del usuario
      displayedTransacciones = allTransacciones
          .where((transaccion) => transaccion['usuarioNombre'] == userName)
          .toList();

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      print('Error al obtener transacciones: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatReservaDate(String isoDate) {
    tz.initializeTimeZones();
    try {
      DateTime dateTime = DateTime.parse(isoDate);
      final location = tz.getLocation('America/La_Paz');
      final localDateTime = tz.TZDateTime.from(dateTime, location);
      String formattedDate =
          "${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')} ${localDateTime.day}/${localDateTime.month}/${localDateTime.year}";
      return formattedDate;
    } catch (e) {
      print('Error al formatear la fecha: $e');
      return 'Fecha inválida';
    }
  }

  Future<double> calcularTotal(int carritoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Obtener el carrito por ID
      final carritoResponse = await http.get(
        Uri.parse('http://157.230.227.216/api/carritos/$carritoId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (carritoResponse.statusCode != 200) {
        throw Exception('Error al obtener los datos del carrito');
      }

      final carritoData = json.decode(carritoResponse.body);
      final List<dynamic> productosDetalle = carritoData['productosDetalle'];

      // Obtener detalles de los productos desde productoDetalleId
      final productDetailsResponse = await http.get(
        Uri.parse('http://157.230.227.216/api/productos-detalles'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (productDetailsResponse.statusCode != 200) {
        throw Exception('Error al obtener los detalles de los productos');
      }

      final List<Map<String, dynamic>> allProductDetails = List<Map<String, dynamic>>.from(json.decode(productDetailsResponse.body));

      // Calcular el total combinando productosDetalle y detalles de productos
      double total = 0.0;
      for (var detalle in productosDetalle) {
        final productoDetalle = allProductDetails.firstWhere(
          (prodDetalle) => prodDetalle['id'] == detalle['productoDetalleId'],
          orElse: () => {},
        );

        if (productoDetalle != null) {
          double precio = double.tryParse(productoDetalle['producto']['precio'].toString()) ?? 0.0;
          double descuento = double.tryParse(productoDetalle['producto']['descuentoPorcentaje']?.toString() ?? '0') ?? 0.0;
          int cantidad = detalle['cantidad'] ?? 1;
          final discountedPrice = precio - (precio * (descuento / 100));
          total += discountedPrice * cantidad;
        }
      }

      return double.parse(total.toStringAsFixed(2));
    } catch (error) {
      print('Error al calcular el total del carrito: $error');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: const Text("Compras realizadas",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: displayedTransacciones.length,
              itemBuilder: (context, index) {
                final transaccion = displayedTransacciones[index];
                return FutureBuilder<double>(
                  future: calcularTotal(transaccion['carritoId']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    double total = snapshot.data ?? 0.0;

                    return Column(
                      children: [
                        ListTile(
                          title: Text('Transacción No. ${transaccion['id']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Fecha de compra: ${formatReservaDate(transaccion['fecha'])}'),
                              Text('Tipo de pago: ${transaccion['tipoPagoNombre']}'),
                              Text('Total: Bs$total'),
                            ],
                          ),
                          trailing: Image.network(
                            transaccion['tipoPagoImagenQr'],
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          onTap: () {
                            // Acción al tocar la transacción, si es necesario
                          },
                        ),
                        const Divider(),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
