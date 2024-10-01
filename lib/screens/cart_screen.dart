import 'package:mapas_api/main.dart';
import 'package:mapas_api/widgets/pagos_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = true;
  int? cartId;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = int.parse(prefs.getString('userId') ?? '0');
    final token = prefs.getString('token') ?? ''; // Obtener el token almacenado
    print('Usuario logeado: $userId');

    // Paso 1: Obtener el carrito disponible
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

    // Obtener el carrito del usuario que está disponible
    final userCart = carritosData.firstWhere(
      (cart) => cart['usuarioId'] == userId && cart['disponible'] == true,
      orElse: () => null,
    );

    if (userCart != null) {
      cartId = userCart['id'];

      // Extraemos los productosDetalle con sus cantidades
      final List<Map<String, dynamic>> productosDetalleConCantidades = userCart['productosDetalle']
          .map<Map<String, dynamic>>((detalle) => {
                'productoDetalleId': detalle['productoDetalleId'],
                'cantidad': detalle['cantidad']
              })
          .toList();

      // Paso 2: Obtener los detalles de los productos del carrito
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

      // Ajuste al obtener los detalles del producto
final List<Map<String, dynamic>> allProductDetails = 
    List<Map<String, dynamic>>.from(json.decode(productDetailsResponse.body));

// Filtrar los productos que coinciden con los productosDetalle del carrito
final List<Map<String, dynamic>> cartProductDetails = allProductDetails.where((productoDetalle) {
  return productosDetalleConCantidades.any((detalle) => detalle['productoDetalleId'] == productoDetalle['id']);
}).toList();

// Combinar los detalles del producto con las cantidades del carrito
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

double calcularTotal() {
  double total = 0.0;
  for (var product in displayedProducts) {
    // Asegurarse de que el precio es válido y no es nulo
    double precio = double.tryParse(product['producto']['precio'].toString()) ?? 0.0;

    // Asegurarse de que el descuento es válido, si es nulo asumimos 0
    double descuento = double.tryParse(product['producto']['descuentoPorcentaje']?.toString() ?? '0') ?? 0.0;

    // La cantidad viene del carrito, no del detalle del producto
    int cantidad = product['cantidad'] ?? 1;

    // Calcular el precio con descuento
    final discountedPrice = precio - (precio * (descuento / 100));

    // Sumar al total, multiplicando por la cantidad
    total += discountedPrice * cantidad;
  }
  
  // Retornar el total con solo 2 decimales
  return double.parse(total.toStringAsFixed(2));
}




 Future<void> updateCart(int cartId, int variantId, int cantidad) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? ''; // Obtener el token almacenado

  List<dynamic> todosLosDetalles;
  try {
    // Paso 3: Obtener los detalles del carrito
    final detallesResponse = await http.get(
      Uri.parse('http://157.230.227.216/api/carrito-producto-detalles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (detallesResponse.statusCode != 200) {
      throw Exception('Error al obtener los detalles del carrito');
    }

    todosLosDetalles = json.decode(detallesResponse.body);
    print('Detalles obtenidos exitosamente');
  } catch (error) {
    print('Error al obtener los detalles del carrito: $error');
    return;
  }

  // Paso 4: Verificar si el producto ya está en el carrito
  final detalleExistente = todosLosDetalles.firstWhere(
    (detalle) =>
        detalle['carritoId'] == cartId && detalle['productoDetalleId'] == variantId,
    orElse: () => null,
  );

  // Paso 5: Si el producto ya está en el carrito, actualizar la cantidad
  if (detalleExistente != null) {
    try {
      final int cantidadExistente = detalleExistente['cantidad'];
      final int nuevaCantidad = cantidadExistente + cantidad;

      final responseActualizar = await http.put(
        Uri.parse(
            'http://157.230.227.216/api/carrito-producto-detalles/${detalleExistente['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'carritoId': cartId,
          'productoDetalleId': variantId,
          'cantidad': nuevaCantidad,
        }),
      );

      if (responseActualizar.statusCode == 200) {
        print('Cantidad actualizada con éxito');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cantidad actualizada con éxito.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Error al actualizar la cantidad');
      }
    } catch (error) {
      print('Error al actualizar la cantidad: $error');
    }
  } else {
    // Si el producto no está en el carrito, lo agregamos
    try {
      final responseAgregar = await http.post(
        Uri.parse('http://157.230.227.216/api/carrito-producto-detalles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'carritoId': cartId,
          'productoDetalleId': variantId,
          'cantidad': cantidad,
        }),
      );

      if (responseAgregar.statusCode == 200) {
        print('Producto añadido al carrito exitosamente.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto añadido al carrito exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Error al añadir el producto al carrito');
      }
    } catch (error) {
      print('Error al añadir el producto al carrito: $error');
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
     appBar: AppBar(
  backgroundColor: const Color(0xFF1E272E),
  iconTheme: const IconThemeData(color: Colors.white),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back), // Icono de retroceso
    onPressed: () {
      Navigator.of(context).pop(); // Volver a la pantalla anterior
    },
  ),
  title: const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.max,
    children: [
      Text(
        'Mi Carrito',
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold
        ),
      ),
    ],
  ),
),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayedProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.shopping_cart,
                        size: 100,
                        color: Colors.white,
                      ),
                      Text(
                        'Carrito vacío',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: displayedProducts.length,
                  itemBuilder: (context, index) {
                    double precio = double.parse(displayedProducts[index]
                            ['producto']['precio']
                        .toString());
                    double descuento = double.parse(displayedProducts[index]
                                ['producto']['descuentoPorcentaje']
                            ?.toString() ??
                        '0');
                    final discountedPrice =
                        precio - (precio * (descuento / 100));

                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.network(
                                displayedProducts[index]['imagen2D'],
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
                                      displayedProducts[index]['producto']
                                              ['nombre']
                                          .replaceAll('Ã±', 'ñ'),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    if (descuento > 0)
                                      Text(
                                        'Antes: Bs$precio',
                                        style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    Text(
                                      descuento > 0
                                          ? 'Ahora: Bs$discountedPrice'
                                          : 'Precio: Bs$precio',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: descuento > 0
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cantidad: ${displayedProducts[index]['cantidad']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.green),
                                  onPressed: () {
                                    setState(() {
                                      displayedProducts[index]['cantidad']++;
                                    });
                                    if (cartId != null) {
                                      updateCart(cartId!,
                                          displayedProducts[index]['id'],
                                          displayedProducts[index]['cantidad']);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      if (displayedProducts[index]
                                              ['cantidad'] >
                                          1) {
                                        displayedProducts[index]['cantidad']--;
                                      }
                                    });
                                    if (cartId != null) {
                                      updateCart(cartId!,
                                          displayedProducts[index]['id'],
                                          displayedProducts[index]['cantidad']);
                                    }
                                  },
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  displayedProducts.removeAt(index);
                                });
                                if (cartId != null) {
                                  updateCart(cartId!,
                                      displayedProducts[index]['id'], 0);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text("Bs${calcularTotal()}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyApp()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: const Text("Seguir comprando"),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PantallaPago()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E272E),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      child: const Text(
                        "Tramitar Pedido",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  

}
