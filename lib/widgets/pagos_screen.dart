import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapas_api/widgets/stripe/pagos_online.dart';

class PantallaPago extends StatefulWidget {
  const PantallaPago({super.key});

  @override
  _PantallaPagoState createState() => _PantallaPagoState();
}

class _PantallaPagoState extends State<PantallaPago> {
  int? usuario;
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = true;
  int? cartId;
  String? selectedPaymentMethod;
  List<dynamic> tiposPago = [];
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    _fetchUserData();
    _cargarTiposPago();
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.parse(prefs.getString('userId') ?? '0');
      final token = prefs.getString('token') ?? '';
      usuario = userId;
      print('Usuario logeado: $userId');

      final response = await http.get(
        Uri.parse('http://157.230.227.216/api/carritos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al obtener los carritos');
      }

      final List<dynamic> carritosData = json.decode(response.body);
      final userCart = carritosData.firstWhere(
        (cart) => cart['usuarioId'] == userId && cart['disponible'] == true,
        orElse: () => null,
      );

      if (userCart != null) {
        cartId = userCart['id'];

        final List<Map<String, dynamic>> productosDetalleConCantidades = userCart['productosDetalle']
            .map<Map<String, dynamic>>((detalle) => {
                  'productoDetalleId': detalle['productoDetalleId'],
                  'cantidad': detalle['cantidad']
                })
            .toList();

        final productDetailsResponse = await http.get(
          Uri.parse('http://157.230.227.216/api/productos-detalles'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (productDetailsResponse.statusCode != 200) {
          throw Exception('Error al obtener los productos detalles');
        }

        final List<Map<String, dynamic>> allProductDetails = List<Map<String, dynamic>>.from(json.decode(productDetailsResponse.body));

        final List<Map<String, dynamic>> cartProductDetails = allProductDetails.where((productoDetalle) {
          return productosDetalleConCantidades.any((detalle) => detalle['productoDetalleId'] == productoDetalle['id']);
        }).toList();

        displayedProducts = cartProductDetails.map<Map<String, dynamic>>((productoDetalle) {
          final detalleConCantidad = productosDetalleConCantidades.firstWhere(
              (detalle) => detalle['productoDetalleId'] == productoDetalle['id']);
          return {
            ...productoDetalle,
            'cantidad': detalleConCantidad['cantidad']
          };
        }).toList();

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error al obtener los productos del carrito: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('token') ?? '';
    print('$userId--------------------------------------');
    if (userId == null) {
      throw Exception("User ID not found");
    }
    final response = await http.get(
      Uri.parse('http://157.230.227.216/api/usuarios/id/$userId'),
      headers: {
        'Authorization': 'Bearer $token',  // Aquí incluimos el token en el header
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> _cargarTiposPago() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';  // Obtener el token almacenado

  final uri = Uri.parse('http://157.230.227.216/api/tipo-pagos');
  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',  // Aquí incluimos el token en el header
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      tiposPago = json.decode(response.body);
    });
  } else {
    print('Solicitud fallida con estado: ${response.statusCode}.');
  }
}


  double calcularTotal() {
    double total = 0.0;
    for (var product in displayedProducts) {
      double precio = double.tryParse(product['producto']['precio'].toString()) ?? 0.0;
      double descuento = double.tryParse(product['producto']['descuentoPorcentaje']?.toString() ?? '0') ?? 0.0;
      int cantidad = product['cantidad'] ?? 1;
      final discountedPrice = precio - (precio * (descuento / 100));
      total += discountedPrice * cantidad;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    double cartTotal = calcularTotal();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Datos del Pedido',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  if (userData.isNotEmpty) ...[
                    TextFormField(
                      initialValue: userData['nombre'],
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: userData['email'],
                      decoration: InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                  ],

                  // Productos en el carrito
                  displayedProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'Carrito vacío',
                            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                          ),
                        )
                      : Column(
                          children: displayedProducts.map((product) {
                            double precio = double.tryParse(product['producto']['precio'].toString()) ?? 0.0;
                            double descuento = double.tryParse(product['producto']['descuentoPorcentaje']?.toString() ?? '0') ?? 0.0;
                            double discountedPrice = precio - (precio * (descuento / 100));

                            return Card(
                              elevation: 4.0,
                              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Image.network(
                                        product['imagen2D'], // Aquí obtenemos la imagen desde imagen2D
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['producto']['nombre'].replaceAll('Ã±', 'ñ'),
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            if (descuento > 0)
                                              Text(
                                                'Antes: Bs$precio',
                                                style: const TextStyle(
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            Text(
                                              descuento > 0 ? 'Ahora: Bs$discountedPrice' : 'Precio: Bs$precio',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: descuento > 0 ? Colors.red : Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'Cantidad: ${product['cantidad']}',
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 20),

                  // Total a Pagar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Total a Pagar:',
                        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Bs${cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tipos de Pago
const Text(
  'Selecciona un método de pago:',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
DropdownButton<String>(
  value: selectedPaymentMethod,
  hint: const Text('Método de pago'),
  isExpanded: true,
  items: tiposPago.map<DropdownMenuItem<String>>((tipo) {
    return DropdownMenuItem<String>(
      value: tipo['nombre'],
      child: Row(
        children: [
          if (tipo['imagenQr'] != null && tipo['imagenQr'].isNotEmpty) // Verificar si la URL de la imagen existe
            Image.network(
              tipo['imagenQr'],
              width: 40,  // Ancho de la imagen
              height: 40,  // Altura de la imagen
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.error,  // Icono de error si no se puede cargar la imagen
                  color: Colors.red,
                );
              },
            ),
          const SizedBox(width: 16),  // Espacio entre la imagen y el texto
          Text(tipo['nombre']),  // Mostrar el nombre del tipo de pago
        ],
      ),
    );
  }).toList(),
  onChanged: (String? newValue) {
    setState(() {
      selectedPaymentMethod = newValue;
    });
  },
),

                  const SizedBox(height: 20),

                  // Confirmar Pago
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E272E),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      if (selectedPaymentMethod != null) {
                        if (selectedPaymentMethod == 'VISA MASTERCARD') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(
                                total: cartTotal.toInt(),
                                usuario: usuario!,
                                carritoId: cartId!,
                                tipoPagoId: 3,
                              ),
                            ),
                          );
                        } else {
                          // Procesar pago con otro método
                        }
                      }
                    },
                    child: const Text(
                      'Confirmar Pago',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
