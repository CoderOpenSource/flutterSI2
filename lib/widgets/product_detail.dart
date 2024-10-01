import 'package:mapas_api/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert'; // Para decodificar el JSON
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/favoritos_page.dart';
import 'package:mapas_api/widgets/reserva_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para hacer peticiones HTTP

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map? product;
  List? imageUrls;
  bool isLoading = true; // Añade esta variable para rastrear el estado de carga
  List? productDetails;
  Color? selectedColor;
  int cantidad = 1;
  bool isFavorited = false;
  TextStyle headerStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  TextStyle regularStyle = const TextStyle(
    fontSize: 18,
    color: Colors.black87,
  );

  TextStyle descriptionStyle = const TextStyle(
    fontSize: 16,
    color: Colors.black54,
  );

  TextStyle discountStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  );
  int? selectedVariantId;
  double getDiscountedPrice(dynamic originalPrice, dynamic discount) {
    double price =
        (originalPrice is String) ? double.parse(originalPrice) : originalPrice;
    double discountPercentage =
        (discount is String) ? double.parse(discount) : discount;
    return price * (1 - discountPercentage / 100);
  }

  // Mapa de colores
  Map<String, String> colorMap = {
    "Rojo": "#FF0000",
    "Verde": "#00FF00",
    "Celeste": "#0000FF",
    "Amarillo": "#FFFF00",
    "Naranja": "#FFA500",
    "Púrpura": "#800080",
    "Multicolor": "#00FFFF",
    "Magenta": "#FF00FF",
    "Lima": "#00FF7F",
    "Rosado": "#FFC0CB",
    "Beige": "#F5F5DC",
    "Marrón": "#8B4513",
    "Violeta": "#9400D3",
    "Turquesa": "#40E0D0",
    "Salmon": "#FA8072",
    "Oro": "#FFD700",
    "AZUL": "#1414b8",
    "Gris": "#808080",
    "Negro": "#000000",
    "Blanco": "#FFFFFF",
    // ... Puedes agregar más colores si lo deseas
  };

  Color getColorFromName(String name) {
    // Utiliza el nombre del color para buscar en el mapa. Si no se encuentra, devuelve blanco por defecto.
    String hex = colorMap[name] ?? colorMap['Blanco']!;
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }
  bool isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    fetchProduct();
     fetchProductDetails();
    checkIfFavorited();
  }

 fetchProduct() async {
  // Obtener el token almacenado en SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  
  if (token == null || token.isEmpty) {
    print('Error: Token no disponible.');
    return;
  }

  final response = await http.get(
    Uri.parse('http://157.230.227.216/api/productos/${widget.productId}'), // Nueva IP
    headers: {
      'Authorization': 'Bearer $token', // Añadimos el token en los encabezados
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    var decodedData = json.decode(response.body);
    setState(() {
      product = decodedData;
      isLoading = false; // Desactiva el estado de carga
    });
    print('Producto cargado: $product'); // Imprimir datos del producto
  } else {
    print('Error al obtener datos: ${response.statusCode}');
  }
 
}

fetchProductDetails() async {
  // Obtener el token almacenado en SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    print('Error: Token no disponible.');
    return;
  }

  print('Token obtenido: $token'); // Imprimir el token para asegurarnos de que está disponible

  final response = await http.get(
    Uri.parse('http://157.230.227.216/api/productos-detalles'), // Nueva IP
    headers: {
      'Authorization': 'Bearer $token', // Añadimos el token en los encabezados
      'Content-Type': 'application/json',
    },
  );

  print('Response status code: ${response.statusCode}'); // Imprimir el código de estado de la respuesta

  if (response.statusCode == 200) {
    var decodedData = json.decode(response.body);
    print('Detalles de producto obtenidos: $decodedData'); // Imprimir todos los detalles del producto

    setState(() {
      // Filtramos solo los detalles del producto actual
      productDetails = decodedData.where((detail) {
        print('Procesando detalle: $detail'); // Imprimir cada detalle procesado
        if (detail['producto'] != null) {
          print('Producto dentro del detalle: ${detail['producto']}');
          return detail['producto']['id'] == widget.productId;
        } else {
          print('Producto es null en este detalle'); // En caso de que no haya un producto asociado al detalle
          return false;
        }
      }).toList();
      
      // Verificar si se encontraron detalles que coinciden
      if (productDetails!.isNotEmpty) {
        print('Detalles filtrados que coinciden con el productId ${widget.productId}: $productDetails');
      } else {
        print('No se encontraron detalles que coincidan con el productId ${widget.productId}');
      }

      if (productDetails!.isNotEmpty) {
        // Asignamos las imagenes2D al carrusel
        imageUrls = productDetails!
            .map((detail) => detail['imagen2D'] ?? 'https://via.placeholder.com/100') // Placeholder si no hay imagen
            .toList();
        selectedVariantId = productDetails![0]['id']; // Selecciona el primer detalle por defecto
        print('Imagenes asignadas al carrusel: $imageUrls');
        isLoadingDetails = false;
      } else {
        print('No hay detalles disponibles para mostrar imágenes.');
        isLoadingDetails = false;
      }
    });
  } else {
    print('Error al obtener detalles: ${response.statusCode}');
    print('Response body: ${response.body}'); // Imprimir el cuerpo de la respuesta para más contexto en caso de error
  }
}



 checkIfFavorited() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = int.parse(prefs.getString('userId') ?? '0');
  final String token = prefs.getString('token') ?? ''; // Obtener el token
  final response = await http.get(
    Uri.parse('http://157.230.227.216/api/productos-favoritos/usuario/$userId'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    var decodedData = json.decode(response.body);
    // Adaptar esta línea si la estructura de tu respuesta es diferente
    var found = decodedData.where((item) => item['producto']['id'] == widget.productId).toList();
    if (found.isNotEmpty) {
      setState(() {
        isFavorited = true;
      });
    }
  }
}


 Future<void> gestionarProductoFavorito(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final int usuarioLogueado = int.parse(prefs.getString('userId') ?? '0');
  final String token = prefs.getString('token') ?? ''; // Agregar el token si es necesario
  const url = 'http://157.230.227.216/api/productos-favoritos';

  if (isFavorited) {
    // Eliminar producto de favoritos

    // Paso 1: Obtener el ID del producto favorito
    final responseGet = await http.get(
      Uri.parse(url + '/usuario/$usuarioLogueado'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    // Verificar la respuesta
    if (responseGet.statusCode != 200) {
      print('Error al obtener la lista de productos favoritos: ${responseGet.body}');
      throw Exception('Error al obtener la lista de productos favoritos');
    }

    List<dynamic> productosFavoritos = json.decode(responseGet.body);
    int? idProductoFavorito;
    for (var producto in productosFavoritos) {
      if (producto['producto']['id'] == widget.productId) {
        idProductoFavorito = producto['id'];
        break;
      }
    }

    if (idProductoFavorito == null) {
      print('Producto favorito no encontrado');
      throw Exception('Producto favorito no encontrado');
    }

    // Paso 2: Eliminar el producto favorito
final responseDelete = await http.delete(
  Uri.parse('$url/eliminar?usuarioId=$usuarioLogueado&productoId=${widget.productId}'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);

print('Response status code (DELETE): ${responseDelete.statusCode}');
print('Response body (DELETE): ${responseDelete.body}');

if (responseDelete.statusCode == 200 || responseDelete.statusCode == 204) {
  const snackBar = SnackBar(
    content: Text('Producto eliminado de favoritos'),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
  setState(() {
    isFavorited = false;
  });
} else {
  const snackBar = SnackBar(
    content: Text('Error al eliminar el producto de favoritos'),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
}else {
    try {
      const url = 'http://157.230.227.216/api/productos-favoritos/agregar';
      // Crear una solicitud multipart para enviar los datos como 'multipart/form-data'
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar los campos de formulario (como en React con formData)
      request.fields['usuarioId'] = usuarioLogueado.toString();
      request.fields['productoId'] = widget.productId.toString();

      // Enviar la solicitud
      var response = await request.send();

      // Leer la respuesta
      var responseBody = await http.Response.fromStream(response);

      print('Response status code (POST): ${response.statusCode}');
      print('Response body (POST): ${responseBody.body}');

      if (response.statusCode == 200) {
        const snackBar = SnackBar(
          content: Text('Producto agregado a favoritos'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          isFavorited = true;
        });
      } else {
        const snackBar = SnackBar(
          content: Text('Error al agregar el producto a favoritos'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (error) {
      print('Error al hacer la solicitud: $error');
      const snackBar = SnackBar(
        content: Text('Error al agregar el producto a favoritos'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}



 
 Future<void> handleAddToCart(
    int variantId, int cantidad, BuildContext context) async {
  const String baseUrl = "http://157.230.227.216/api";

  final prefs = await SharedPreferences.getInstance();
  final int userId = int.parse(prefs.getString('userId') ?? '0');
  final String token = prefs.getString('token') ?? ''; // Obtiene el token almacenado

  int? carritoId;

  // Paso 1: Obtener todos los carritos del usuario
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/carritos'),
      headers: {
        'Authorization': 'Bearer $token', // Incluye el token en las cabeceras
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener los carritos');
    }

    final List<dynamic> carritosData = json.decode(response.body);

    // Buscar un carrito disponible que pertenezca al usuario
    final carritoUsuario = carritosData.firstWhere(
      (carrito) => carrito['usuarioId'] == userId && carrito['disponible'] == true,
      orElse: () => null,
    );

    if (carritoUsuario != null) {
      print('Carrito disponible encontrado');
      carritoId = carritoUsuario['id'] as int;
    } else {
      print('No se encontró un carrito disponible.');
    }
  } catch (error) {
    print('Error al obtener los carritos: $error');
    return;
  }

  // Paso 2: Crear un nuevo carrito si no se encontró uno disponible
  if (carritoId == null) {
    try {
      final newCarritoResponse = await http.post(
        Uri.parse('$baseUrl/carritos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'usuario': {'id': userId},
          'disponible': true,
          'productoDetalle': {'id': variantId}, // Agregamos el detalle del producto
        }),
      );

      if (newCarritoResponse.statusCode != 200) {
        throw Exception('Error al crear el nuevo carrito');
      }

      final Map<String, dynamic> newCarritoData = json.decode(newCarritoResponse.body);
      carritoId = newCarritoData['id'] as int;

      print('Nuevo carrito creado con ID: $carritoId');
    } catch (error) {
      print('Error al crear el nuevo carrito: $error');
      return;
    }
  }

  // Paso 3: Obtener los detalles del carrito
  List<dynamic> todosLosDetalles;
  try {
    final detallesResponse = await http.get(
      Uri.parse('$baseUrl/carrito-producto-detalles'),
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
    (detalle) => detalle['carritoId'] == carritoId && detalle['productoDetalleId'] == variantId,
    orElse: () => null,
  );

  // Paso 5: Si el producto ya está en el carrito, actualizar la cantidad
  if (detalleExistente != null) {
    try {
      final int cantidadExistente = detalleExistente['cantidad'];
      final int nuevaCantidad = cantidadExistente + cantidad;

      final responseActualizar = await http.put(
        Uri.parse('$baseUrl/carrito-producto-detalles/${detalleExistente['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'carritoId': carritoId,
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
      return;
    }
  } else {
    // Paso 6: Si el producto no está en el carrito, agregarlo
    try {
      final responseAgregar = await http.post(
        Uri.parse('$baseUrl/carrito-producto-detalles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'carritoId': carritoId,
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
  if (isLoading) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E272E),
      body: Center(child: CircularProgressIndicator()),
    );
  }
  
  // Detalles del producto principal
  final productData = product;
  // Realiza el casting explícito a List<Map<String, dynamic>>
final List<Map<String, dynamic>> variants = (productDetails ?? []).cast<Map<String, dynamic>>();

 return Scaffold(
  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
  appBar: AppBar(
  leading: const BackButton(color: Colors.white),
  title: const Text(
    "Detalles del Producto",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontSize: 20,
    ),
  ),
  backgroundColor: const Color(0xFF1E272E),
  centerTitle: true,
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.shopping_cart),
      color: Colors.white, // Establecer el color blanco para el ícono
      onPressed: () {
        // Navegar a la pantalla CartScreen cuando se presione el ícono
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CartScreen()),
        );
      },
    ),
  ],
),

  body: ListView(
    children: [
      // Carrusel de imágenes del producto basado en las variantes
      if (imageUrls != null && imageUrls!.isNotEmpty)
        CarouselSlider(
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * 0.6,
            autoPlay: true,
            viewportFraction: 1.0,
            enableInfiniteScroll: true,
            enlargeCenterPage: true,
          ),
          items: imageUrls!.map((url) {
            return Container(
              margin: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0.0, 4.0),
                    blurRadius: 5.0,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                child: Image.network(
                  url,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Error al cargar la imagen.'));
                  },
                ),
              ),
            );
          }).toList(),
        )
      else
        const Center(child: Text('No hay imágenes disponibles')),

      // Detalles del producto como nombre, precio y descripción
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productData!['nombre'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (productData['descuentoPorcentaje'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precio original: ${productData!['precio']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Precio con descuento: ${(productData!['precio'] - (productData['precio'] * productData['descuentoPorcentaje'] / 100)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Precio: ${productData!['precio']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 10),
            Text(
              'Descripción: ${productData['descripcion']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Categoría: ${productData['categoria']['nombre']} > ${productData['subcategoria']['nombre']}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),

      // Colores disponibles (con selección)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'Colores disponibles:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      Wrap(
        spacing: 12.0,
        children: variants.map((variant) {
          // Usar getColorFromName para obtener el color basado en el nombre del color
          Color currentColor = getColorFromName(variant['color']['nombre']);
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedColor = currentColor;
                selectedVariantId = variant['id'] as int;
              });
            },
            child: Column(
              children: [
                Material(
                  elevation: 2.0,
                  shape: const CircleBorder(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: currentColor, // Aplicar el color basado en el nombre
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == currentColor
                            ? Colors.black
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: [
                        if (selectedColor == currentColor)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tamaño: ${variant['tamaÃ±o']['nombre']}', // Mostrar el tamaño debajo del color
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }).toList(),
      ),

      // Sección de Cantidad, Botones de "Más" y "Menos"
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  if (cantidad > 1) {
                    cantidad--; // Reducir la cantidad
                  }
                });
              },
            ),
            Text(
              '$cantidad', // Mostrar la cantidad actual
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  cantidad++; // Aumentar la cantidad
                });
              },
            ),
          ],
        ),
      ),

      // Botones de Reservar, Añadir al Carrito y Favorito
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón de favorito
            IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.red : Colors.black, // Cambiar color si es favorito
              ),
              onPressed: () async {
                await gestionarProductoFavorito(context); // Llama a la función para gestionar favoritos
              },
            ),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E272E),
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
              onPressed: () async {
                if (selectedVariantId != null) {
                  await handleAddToCart(selectedVariantId!, cantidad, context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor selecciona un color.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text(
                'AÑADIR AL CARRO',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
}}