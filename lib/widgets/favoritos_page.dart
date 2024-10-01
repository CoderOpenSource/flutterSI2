import 'package:mapas_api/services/productos_services.dart';
import 'package:mapas_api/widgets/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  _FavoritosPageState createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  List<dynamic> displayedProducts = [];
  final FavoritosService favoritosService = FavoritosService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductosFavoritos();
  }

  _cargarProductosFavoritos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.parse(prefs.getString('userId') ?? '0');
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        print('Error: Token no disponible.');
        return;
      }

      // Obtener favoritos del usuario
      final favoritosResponse = await http.get(
        Uri.parse('http://157.230.227.216/api/productos-favoritos/usuario/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (favoritosResponse.statusCode == 200) {
        List<dynamic> favoritos = json.decode(favoritosResponse.body);
        
        // Obtener detalles de los productos
        final productosResponse = await http.get(
          Uri.parse('http://157.230.227.216/api/productos-detalles'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (productosResponse.statusCode == 200) {
          List<dynamic> allProductDetails = json.decode(productosResponse.body);
          
          // Filtrar los productos por los favoritos del usuario
          var favoritosProductos = allProductDetails.where((productDetail) {
            return favoritos.any((favorito) =>
                favorito['producto']['id'] == productDetail['producto']['id']);
          }).toList();

          setState(() {
            displayedProducts = favoritosProductos;
            isLoading = false;
          });
        } else {
          print('Error al obtener detalles de productos.');
        }
      } else {
        print('Error al obtener productos favoritos.');
      }
    } catch (error) {
      print('Error al cargar productos favoritos: $error');
    }
  }

  _eliminarProducto(int productId) {
    // Aquí puedes agregar la lógica para eliminar el producto de los favoritos.
    // Por ejemplo, haciendo una llamada a la API para eliminar el favorito.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: const Text("Productos Favoritos",
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1 / 1.5,
              ),
              itemCount: displayedProducts.length,
              itemBuilder: (context, index) {
                final productDetail = displayedProducts[index];
                final producto = productDetail['producto'];

                double precio = double.parse(producto['precio'].toString());
                double descuento = double.parse(
                    producto['descuentoPorcentaje'].toString());
                final discountedPrice = precio - (precio * (descuento / 100));

                return Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Stack(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                  productId: producto['id']),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              productDetail['imagen2D'] ?? 'https://via.placeholder.com/100',
                              fit: BoxFit.cover,
                              height: 100,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              producto['nombre'].replaceAll('Ã±', 'ñ'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Antes: Bs${producto['precio']}',
                                style: const TextStyle(fontSize: 12)),
                            Text('Ahora: Bs$discountedPrice',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: PopupMenuButton(
                          onSelected: (value) {
                            if (value == "eliminar") {
                              _eliminarProducto(producto['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "eliminar",
                              child: Text("Eliminar"),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
