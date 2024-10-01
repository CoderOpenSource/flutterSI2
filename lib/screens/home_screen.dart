import 'package:carousel_slider/carousel_slider.dart';
import 'package:mapas_api/models/global_data.dart';
import 'package:mapas_api/models/user/sucursal_model.dart';
import 'package:mapas_api/screens/taller/loading_taller_screen4.dart';
import 'package:mapas_api/widgets/appbar.dart';
import 'package:mapas_api/widgets/product_detail.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

bool _hasShownDialog = false;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista de imágenes de ejemplo
  List<String> imageUrls = [
    'https://res.cloudinary.com/dkpuiyovk/image/upload/v1727726023/461055366_957660769707144_7231121727055471817_n_z7biab.jpg',
    'https://images6.alphacoders.com/132/1325712.jpeg',
    // Agrega más URLs de imágenes según tus necesidades
  ];
  bool isLoading = true;
  List<dynamic> categories = [];
  String? selectedCategory;
  List<dynamic> products = []; // Esta mantendrá todos los productos
  List<dynamic> displayedProducts =
      []; // Esta mostrará los productos filtrados o todos
  int? selectedSucursalId;
  // Agregamos un dummy de categoría "Todos" al principio de la lista.
  @override
  void initState() {
    super.initState();

    selectedSucursalId = GlobalData().selectedSucursalId;

    if (selectedSucursalId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasShownDialog) {
          _mostrarSucursales(context);
          _hasShownDialog = true;
        }
      });
    } else {
      _filterProductsBySucursal();
    }
    // Agrega "Todos" al inicio de la lista de categorías.
    categories = [
      {
        'nombre': 'Todos',
        'id': -1, // Un ID que no debería existir en tu base de datos
      }
    ];

    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    await fetchCategories();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCategories() async {
  // Obtener el token almacenado en SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    // Maneja el caso en que el token no esté disponible
    print('Error: Token no disponible.');
    return;
  }

  // Hacer la solicitud a la API con la nueva IP y el token en la cabecera
  final response = await http.get(
    Uri.parse('http://157.230.227.216/api/categorias'), // Nueva IP y ruta
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Añadir el token en la cabecera
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      categories.addAll(json.decode(response.body)); // Aquí usamos addAll
      selectedCategory ??= categories[0]['nombre']; // Seleccionar la primera categoría si no hay seleccionada
    });
  } else {
    print('Error al obtener las categorías');
  }
}
String corregirCaracteresEspeciales(String texto) {
  return texto
      .replaceAll('Ã', 'Ñ') // Reemplazar caracteres de codificación errónea
      .replaceAll('Ã¡', 'á')
      .replaceAll('Ã©', 'é')
      .replaceAll('Ã³', 'ó')
      .replaceAll('Ãº', 'ú')
      .replaceAll('Ã­', 'í')
      .replaceAll('Ã', 'A');  // Puedes agregar otros reemplazos según sea necesario
}


  void _filterProductsBySucursal() async {
  print('Sucursal seleccionada: $selectedSucursalId');

  // Obtener el token almacenado en SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    print('Error: Token no disponible.');
    return;
  }

  if (selectedSucursalId != null) {
    // Paso 1: Obtener los inventarios de la sucursal específica
    final inventoryResponse = await http.get(
      Uri.parse('http://157.230.227.216/api/inventarios'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (inventoryResponse.statusCode == 200) {
      var allInventory = json.decode(inventoryResponse.body) as List;

      // Filtramos los inventarios por el ID de la sucursal seleccionada
      var filteredInventory = allInventory.where((inventoryItem) {
        return inventoryItem['sucursal']['id'] == selectedSucursalId;
      }).toList();

      // Filtramos los productos detalle que tengan una imagen y descuento mayor a 0
      var relevantProductDetails = filteredInventory.where((inventoryItem) {
        var productDetail = inventoryItem['productodetalle'];
        var descuento = productDetail['producto']['descuentoPorcentaje'];
        var imagen2D = productDetail['imagen2D'];
        
        // Verificar si el descuento es un número válido y mayor que 0
        double descuentoParsed = 0.0;
        if (descuento != null && descuento is! bool) {
          descuentoParsed = double.tryParse(descuento.toString()) ?? 0.0;
        }

        return descuentoParsed > 0 && imagen2D != null && imagen2D.isNotEmpty;
      }).toList();

      // Actualizamos los productos que se mostrarán
      setState(() {
        products = relevantProductDetails;
        displayedProducts = List.from(relevantProductDetails);
      });

      print('Productos filtrados con descuento y con imagen: $displayedProducts');
    } else {
      print('Error al obtener el inventario');
    }
  } else {
    print('No hay sucursal seleccionada');
  }
}


  Future<void> _mostrarSucursales(BuildContext context) async {
  // Obtener el token almacenado en SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    // Maneja el caso en que el token no esté disponible
    print('Error: Token no disponible.');
    return;
  }

  // Hacer la solicitud a la API con el token en la cabecera
  final response = await http.get(
    Uri.parse('http://157.230.227.216/api/sucursales'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Añadir el token en la cabecera
    },
  );

  print('Respuesta: ${response.body}');

  if (response.statusCode == 200) {
    // Si la llamada a la API es exitosa, parsear el JSON.
    List<Sucursal> sucursales = (json.decode(response.body) as List)
        .map((data) => Sucursal.fromJson(data))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E272E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Bordes redondeados
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // Limitar el tamaño al 60% de la pantalla
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adaptar el tamaño al contenido
              children: [
                const Text(
                  "STYLO STORE",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "🏠 UBICACIONES 🏠",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white), // Línea divisoria blanca
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true, // Adaptar el tamaño al contenido
                    itemCount: sucursales.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: [
                          ListTile(
                            onTap: () {
                              setState(() {
                                selectedSucursalId = sucursales[index].id;
                                GlobalData().selectedSucursalId =
                                    selectedSucursalId; // Aquí actualizamos el valor estático
                                _filterProductsBySucursal();
                              });
                              Navigator.pop(context);
                            },
                            leading: const Icon(
                              Icons.home, // Ícono de casa
                              color: Colors.white,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            title: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white),
                                children: <TextSpan>[
                                  const TextSpan(
                                      text: '🏠 Sucursal: ',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: sucursales[index].nombre),
                                ],
                              ),
                            ),
                            subtitle: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white),
                                children: <TextSpan>[
                                  const TextSpan(
                                      text: '📍 Dirección: ',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: sucursales[index].direccion),
                                ],
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white), // Línea divisoria blanca
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  } else {
    // Si la llamada a la API falla, muestra un error.
    throw Exception('Error al cargar las sucursales');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 250),
      appBar: AppBarActiTone(
        onStoreIconPressed: () => _mostrarSucursales(context),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height:
                        10, // Espacio entre las recomendaciones y el carrusel
                  ),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200, // Cambia esto para modificar la altura
                      autoPlay: true, // Autoplay para el carrusel
                      viewportFraction:
                          1.0, // Esto hará que la imagen ocupe toda la pantalla en ancho
                      // Añadimos estas líneas para los indicadores:
                      enableInfiniteScroll: true,
                      pauseAutoPlayOnTouch: true,
                      enlargeCenterPage: true,
                      onPageChanged: (index, reason) {
                        setState(() {
                          // Aquí puedes actualizar algún estado relacionado con el índice de la imagen actual si es necesario
                        });
                      },
                    ),
                    items: imageUrls.map((url) {
                      return Container(
                        margin: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              10.0), // Añadimos bordes redondeados
                          boxShadow: const [
                            BoxShadow(
                              color: Colors
                                  .black26, // Cambia este color para la sombra
                              offset: Offset(0.0, 4.0),
                              blurRadius: 5.0,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10.0)),
                          child: Image.network(
                            url,
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                  child: Text('Error al cargar la imagen.'));
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(
                    height:
                        20, // Aumenté el espacio entre el carrusel y el título
                  ),
                  const Text(
                    "🎉 Ropa con Descuento 🎉",
                    style: TextStyle(
                      fontSize: 28, // Aumenté el tamaño de la fuente
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E272E),
                    ),
                  ),
                  const SizedBox(
                    height:
                        15, // Aumenté el espacio entre el título y lo que sigue
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(15.0), // Bordes redondeados
                      color: const Color(0xFF1E272E),
                    ),
                    child: SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: categories.map((category) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = corregirCaracteresEspeciales(category['nombre']);
            int selectedCategoryId = category['id'];

            if (selectedCategory == "Todos") {
  displayedProducts = products.where((product) {
    // Verificar que el producto esté anidado dentro de 'productodetalle'
    var productDetail = product['productodetalle'];
    var producto = productDetail != null ? productDetail['producto'] : null;

    // Asegurarse de que 'producto' no sea nulo antes de acceder a sus atributos
    if (producto != null) {
      // Verificar que el descuento sea válido y convertirlo de manera segura
      print('PRODUCT $producto');
      double descuento = 0.0;
      if (producto['descuentoPorcentaje'] != null &&
          producto['descuentoPorcentaje'] is! bool) {
        descuento = double.tryParse(producto['descuentoPorcentaje'].toString()) ?? 0.0;
      }

      // Filtrar productos que tienen algún descuento
      return descuento > 0;
    }
    return false; // Si no hay producto o descuento, no se incluye
  }).toList();
}
 else {
  // Filtrado por categoría específica y también que tengan descuento.
  List<dynamic> filteredProducts = products.where((product) {
    // Accedemos a productodetalle y luego a producto para obtener la categoría
    var productDetail = product['productodetalle'];
    var producto = productDetail != null ? productDetail['producto'] : null;

    if (producto != null) {
      double descuento = 0.0;
      if (producto['descuentoPorcentaje'] != null && producto['descuentoPorcentaje'] is! bool) {
        descuento = double.tryParse(producto['descuentoPorcentaje'].toString()) ?? 0.0;
      }

      // Comprobar que la categoría no sea nula antes de intentar acceder a 'id'
      var categoria = producto['categoria'];
      if (categoria != null) {
        return categoria['id'] == selectedCategoryId && descuento > 0;
      }
    }
    return false;
  }).toList();
  displayedProducts = filteredProducts;
}

          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 10.0), // Ampliado el padding vertical
          child: Row(
            children: [
              // Aquí hacemos una elección del ícono basado en la categoría
              categoryIcon(category['nombre'].replaceAll('Ã±', 'ñ')),
              const SizedBox(width: 5.0),
              Text(
                category['nombre'].replaceAll('Ã±', 'ñ'),
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: selectedCategory == category['nombre']
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  ),
),

                  ),
                                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(10.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: 1 / 1.6, // Ajustado para más espacio vertical
                      ),
                      itemCount: displayedProducts.length,
                      itemBuilder: (context, index) {
                        // Extraer los datos del producto y los detalles desde el inventario
                        final productDetail = displayedProducts[index]['productodetalle'];
                        final producto = productDetail['producto'];

                        double precio = double.parse(producto['precio'].toString());

                        // Verificar y convertir el descuentoPorcentaje si es válido
                        double descuento = 0.0;
                        if (producto['descuentoPorcentaje'] != null &&
                            producto['descuentoPorcentaje'] is! bool) {
                          descuento = double.tryParse(producto['descuentoPorcentaje'].toString()) ?? 0.0;
                        }

                        final discountedPrice = precio - (precio * (descuento / 100));

                        // Verificar si existe una imagen2D en el producto detalle
                        final imageUrl = productDetail['imagen2D'] != null && productDetail['imagen2D'].isNotEmpty
                            ? productDetail['imagen2D']
                            : 'https://via.placeholder.com/100'; // URL de una imagen por defecto si no hay imagen

                        return SizedBox(
                          width: double.infinity,
                          child: Card(
                            color: const Color(0xFF1E272E),
                            elevation: 5.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0), // Reducido a 8.0
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(
                                        productId: producto['id'],
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Mostrar la imagen 2D o la imagen por defecto
                                    Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      height: 90,
                                      width: 100, // Reducido a 100
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image, color: Colors.white); // Mostrar un ícono si hay un error
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Flexible(
                                      child: Text(
                                        producto['nombre'].replaceAll('Ã±', 'ñ'),
                                        style: const TextStyle(
                                          fontSize: 12, // Reducido a 12
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (descuento > 0) ...[
                                      Text(
                                        'Antes: Bs${producto['precio']}',
                                        style: const TextStyle(
                                          fontSize: 10, // Reducido a 10
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Ahora: Bs${discountedPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 10, // Reducido a 10
                                          fontWeight: FontWeight.bold,
                                          color: Colors.yellow,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'Precio: Bs${producto['precio']}',
                                        style: const TextStyle(
                                          fontSize: 10, // Reducido a 10
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                ],
              ),
            ),
    );
  }

  Widget categoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Todos':
        return const Icon(Icons.list, color: Colors.white);
      case 'NIÑO':
        return const Icon(Icons.boy,
            color: Colors
                .white); // Aquí puedes usar cualquier ícono representativo para niños
      case 'NIÑA':
        return const Icon(Icons.girl,
            color: Colors.white); // Y aquí uno para niñas
      case 'Bebes':
        return const Icon(Icons.baby_changing_station,
            color: Colors.white); // Aquí uno para bebés
      default:
        return const SizedBox
            .shrink(); // No muestra ningún ícono si no coincide con las categorías anteriores
    }
  }
}
