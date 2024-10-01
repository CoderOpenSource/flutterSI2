import 'package:mapas_api/models/global_data.dart';
import 'package:mapas_api/models/user/sucursal_model.dart';
import 'package:mapas_api/screens/taller/loading_taller_screen4.dart';
import 'package:mapas_api/widgets/appbar2.dart';
import 'package:mapas_api/widgets/product_detail.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

bool _hasShownDialog = false;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int? selectedSubcategory;
  bool isLoading = true;
  List<dynamic> categories = [];
  List<dynamic> subcategories = [];
  int? selectedCategory;
  List<dynamic> products = [];
  List<dynamic> displayedProducts = [];
  int? selectedSucursalId;

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

    // Iniciar con la categoría "Todos"
    categories = [
      {
        'nombre': 'Todos',
        'id': -1,
      }
    ];

    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    await fetchCategories();
    await fetchSubcategories();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print('Error: Token no disponible.');
      return;
    }

    final response = await http.get(
      Uri.parse('http://157.230.227.216/api/categorias'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        categories.addAll(json.decode(response.body));
        selectedCategory ??= categories[0]['id'];
      });
    } else {
      print('Error al obtener las categorías');
    }
  }

  Future<void> fetchSubcategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print('Error: Token no disponible.');
      return;
    }

    final response = await http.get(
      Uri.parse('http://157.230.227.216/api/subcategorias'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        subcategories = json.decode(response.body);
      });
    } else {
      print('Error al obtener las subcategorías');
    }
  }

  void _filterProductsBySucursal() async {
    print('Sucursal seleccionada: $selectedSucursalId');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print('Error: Token no disponible.');
      return;
    }

    if (selectedSucursalId != null) {
      final inventoryResponse = await http.get(
        Uri.parse('http://157.230.227.216/api/inventarios'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (inventoryResponse.statusCode == 200) {
        var allInventory = json.decode(inventoryResponse.body) as List;

        var filteredInventory = allInventory.where((inventoryItem) {
          return inventoryItem['sucursal']['id'] == selectedSucursalId;
        }).toList();

        var relevantProductDetails = filteredInventory.where((inventoryItem) {
          var productDetail = inventoryItem['productodetalle'];
          var imagen2D = productDetail['imagen2D'];

          

          return  imagen2D != null && imagen2D.isNotEmpty;
        }).toList();

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print('Error: Token no disponible.');
      return;
    }

    final response = await http.get(
      Uri.parse('http://157.230.227.216/api/sucursales'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<Sucursal> sucursales = (json.decode(response.body) as List)
          .map((data) => Sucursal.fromJson(data))
          .toList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: const Color(0xFF1E272E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const Divider(color: Colors.white),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: sucursales.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: [
                            ListTile(
                              onTap: () {
                                setState(() {
                                  selectedSucursalId = sucursales[index].id;
                                  GlobalData().selectedSucursalId = selectedSucursalId;
                                  _filterProductsBySucursal();
                                });
                                Navigator.pop(context);
                              },
                              leading: const Icon(
                                Icons.home,
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
                            const Divider(color: Colors.white),
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
      print('Error al cargar las sucursales');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 249, 249),
      appBar: AppBarActiTone2(
        onStoreIconPressed: () => _mostrarSucursales(context),
      ),
      drawer: Drawer( // Aquí añadimos el Drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1E272E),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 40.0, color: Colors.white), 
                  SizedBox(width: 10.0),
                  Text('STYLO STORE',
                      style: TextStyle(fontSize: 24.0, color: Colors.white)),
                ],
              ),
            ),
            ...categories.map((category) {
              return ExpansionTile(
                leading: const Icon(Icons.category, color: Color(0xFF1E272E)),
                title: Text(category['nombre'].replaceAll('Ã±', 'ñ'),
                    style: const TextStyle(fontSize: 18.0)),
                children: subcategories
                    .where((sub) => category['id'] == -1
                        ? true
                        : sub['categoria']['id'] == category['id'])
                    .map((subcategory) {
                  return ListTile(
                    title: Text(subcategory['nombre'].replaceAll('Ã±', 'ñ')),
                    onTap: () {
                      setState(() {
                        selectedSubcategory = subcategory['id'];
                        displayedProducts = products.where((product) {
                          var productDetail = product['productodetalle'];
                          var producto = productDetail != null
                              ? productDetail['producto']
                              : null;
                          var subcategoria = producto != null
                              ? producto['subcategoria']
                              : null;

                          return subcategoria != null &&
                              subcategoria['id'] == selectedSubcategory;
                        }).toList();
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
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
                                selectedCategory = category['id'];
                                if (selectedCategory == -1) {
                                  displayedProducts = List.from(products);
                                } else {
                                  displayedProducts = products.where((product) {
                                    var productDetail = product['productodetalle'];
                                    var producto = productDetail != null
                                        ? productDetail['producto']
                                        : null;
                                    var categoria = producto != null
                                        ? producto['categoria']
                                        : null;
                                    return categoria != null &&
                                        categoria['id'] == selectedCategory;
                                  }).toList();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                              child: Row(
                                children: [
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
    childAspectRatio: 1 / 1.5,
  ),
  itemCount: displayedProducts.length,
  itemBuilder: (context, index) {
    final productDetail = displayedProducts[index]['productodetalle'];
    final producto = productDetail['producto'];

    double precio = double.parse(producto['precio'].toString());
    double descuento = producto['descuentoPorcentaje'] != null
        ? double.parse(producto['descuentoPorcentaje'].toString())
        : 0.0; // Si es null, asigna 0
    final discountedPrice = precio - (precio * (descuento / 100));

    final imageUrl = productDetail['imagen2D'] != null &&
            productDetail['imagen2D'].isNotEmpty
        ? productDetail['imagen2D']
        : 'https://via.placeholder.com/100';

    return SizedBox(
      width: double.infinity,
      child: Card(
        color: const Color(0xFF1E272E),
        elevation: 5.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  height: 90,
                  width: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, color: Colors.white);
                  },
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    producto['nombre'].replaceAll('Ã±', 'ñ'),
                    style: const TextStyle(
                      fontSize: 12,
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
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Ahora: Bs${discountedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Precio: Bs${producto['precio']}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}
