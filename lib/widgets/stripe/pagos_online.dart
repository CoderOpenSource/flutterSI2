import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/blocs/pagar/pagar_bloc.dart';
import 'package:mapas_api/helpers/helpers.dart';
import 'package:mapas_api/main.dart';
import 'package:mapas_api/services/stripe_service.dart';
import 'package:mapas_api/helpers/tarjeta.dart';
import 'package:mapas_api/widgets/stripe/tarjeta_pago.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
class HomePage extends StatefulWidget {
  final int total;
  final int usuario;
  final int carritoId;
  final int tipoPagoId;

  const HomePage({
    super.key,
    required this.total,
    required this.usuario,
    required this.carritoId,
    required this.tipoPagoId,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StripeService stripeService = StripeService();
  bool done = false;
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = true;
  int? cartId;
 
  @override
  void initState() {
    super.initState();
    Stripe.publishableKey =
        'pk_test_51OM6g0A7qrAo0IhR3dbWDmmwmpyZ6fu5WcwDQ9kSNglvbcqlPKy4xXSlwltVkGOkQgWh12T7bFJgjCQq3B7cGaFV007JonVDPp';
    _fetchUserData().then((data) {
      setState(() {
        // userData could be used here if needed
      });
    }).catchError((error) {
      print('Error fetching user data: $error');
    });
    fetchCartItems();
  }
  Future<void> enviarFacturaAlBackend(int transaccionId, File pdfFile) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('http://157.230.227.216/api/facturas');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['transaccionId'] = transaccionId.toString();

    // Adjuntar el archivo PDF al request
    request.files.add(
      await http.MultipartFile.fromPath('file', pdfFile.path),
    );

    // Enviar la solicitud
    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Factura creada y enviada con éxito');
    } else {
      print('Error al enviar la factura: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al enviar la factura: $e');
  }
}


Future<File> generatePdfFile(int transaccionId) async {
  final pdf = pw.Document();

  // Crear una lista de widgets para agregar al PDF
  List<pw.Widget> productWidgets = [];

  // Iteramos por cada producto y obtenemos la imagen
  for (var product in displayedProducts) {
    final imageUrl = product['imagen2D']; // URL de la imagen
    pw.ImageProvider? productImage;

    // Intentamos descargar la imagen
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;
        productImage = pw.MemoryImage(imageData); // Convertimos la imagen a un formato compatible
      }
    } catch (e) {
      print('Error al descargar la imagen del producto: $e');
    }

    // Creamos el widget para este producto
    productWidgets.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Si tenemos una imagen válida, la agregamos
          if (productImage != null)
            pw.Container(
              width: 50,
              height: 50,
              child: pw.Image(productImage),
            ),
          pw.SizedBox(width: 10), // Espacio entre la imagen y el texto
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  product['producto']['nombre'],
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Cantidad: ${product['cantidad']}'),
              ],
            ),
          ),
        ],
      ),
    );

    // Añadimos un divisor entre productos
    productWidgets.add(pw.Divider());
  }

  // Creamos la página PDF con los detalles
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Factura de Compra', style: pw.TextStyle(fontSize: 24)),
            pw.Divider(),
            pw.Text('Transacción ID: $transaccionId'),
            pw.Text('Total a Pagar: Bs${widget.total.toStringAsFixed(2)}'),
            pw.Text('Detalles de productos:'),
            pw.Divider(),
            ...productWidgets, // Agregamos los productos con sus imágenes
            pw.Text('Gracias por tu compra!'),
          ],
        );
      },
    ),
  );

  // Guardar el PDF en un archivo temporal
  final output = await getTemporaryDirectory();
  final file = File("${output.path}/factura_${transaccionId}.pdf");
  await file.writeAsBytes(await pdf.save());

  return file;
}


  Map<String, dynamic>? paymentIntent;
  Future<void> fetchCartItems() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = int.parse(prefs.getString('userId') ?? '0');
    final token = prefs.getString('token') ?? ''; // Obtener el token
    print('Usuario logeado: $userId');

    // Obtener carritos del usuario
    final response = await http.get(
      Uri.parse('http://157.230.227.216/api/carritos'),
      headers: {
        'Authorization': 'Bearer $token',  // Añadir el token en los headers
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

      // Obtener el detalle de productos con sus cantidades
      final List<Map<String, dynamic>> productosDetalleConCantidades = userCart['productosDetalle']
          .map<Map<String, dynamic>>((detalle) => {
                'productoDetalleId': detalle['productoDetalleId'],
                'cantidad': detalle['cantidad']
              })
          .toList();

      // Obtener detalles de los productos
      final productDetailsResponse = await http.get(
        Uri.parse('http://157.230.227.216/api/productos-detalles'),
        headers: {
          'Authorization': 'Bearer $token',  // Añadir el token en los headers
          'Content-Type': 'application/json',
        },
      );

      if (productDetailsResponse.statusCode != 200) {
        throw Exception('Error al obtener los productos detalles');
      }

      final List<Map<String, dynamic>> allProductDetails = List<Map<String, dynamic>>.from(json.decode(productDetailsResponse.body));

      // Filtrar los productos que están en el carrito
      final List<Map<String, dynamic>> cartProductDetails = allProductDetails.where((productoDetalle) {
        return productosDetalleConCantidades.any((detalle) => detalle['productoDetalleId'] == productoDetalle['id']);
      }).toList();

      // Asignar los productos filtrados con sus cantidades
      displayedProducts = cartProductDetails.map<Map<String, dynamic>>((productoDetalle) {
        final detalleConCantidad = productosDetalleConCantidades.firstWhere(
            (detalle) => detalle['productoDetalleId'] == productoDetalle['id']);
        return {
          ...productoDetalle,
          'cantidad': detalleConCantidad['cantidad'],
        };
      }).toList();

      // Actualizamos el estado para dejar de cargar
      setState(() {
        isLoading = false;
      });
    } else {
      // Si no hay carrito disponible
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

  Future<Map<String, dynamic>> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('token') ?? '';  // Obtener el token almacenado

    if (userId == null) {
      throw Exception("User ID not found");
    }

    final response = await http.get(
      Uri.parse('http://157.230.227.216/api/usuarios/id/$userId'),
      headers: {
        'Authorization': 'Bearer $token',  // Añadir el token aquí
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> makePayment(int total) async {
    try {
      paymentIntent = await createPaymentIntent(total);

      var gpay = const PaymentSheetGooglePay(
        merchantCountryCode: "US",
        currencyCode: "USD",
        testEnv: true,
      );
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent!["client_secret"],
        style: ThemeMode.dark,
        merchantDisplayName: "Prueba",
        googlePay: gpay,
      ));

      await displayPaymentSheet();
    } catch (e) {
      print('Error en makePayment: $e');
    }
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      print("DONE");
      setState(() {
        done = true;
      });
      realizarTransaccion();
      actualizarCarrito();
    } catch (e) {
      setState(() {
        done = false;
      });
      print('FAILED');
    }
  }

  createPaymentIntent(int total) async {
    try {
      String monto = (total * 100).toString();
      Map<String, dynamic> body = {
        "amount": monto,
        "currency": "USD", 
      };
      http.Response response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        body: body,
        headers: {
          "Authorization":
              "Bearer sk_test_51OM6g0A7qrAo0IhR79BHknFXkoeVL7M3yF9UYYnRlTEbGLQhc90La5scbYs2LAkHbh6dYQCw8CbqsTgNAgYvLBNn00I1QqzLDj",
        },
      );
      print(response.body);
      return json.decode(response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> realizarTransaccion() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('http://157.230.227.216/api/transacciones');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final body = json.encode({
      'usuario_id': widget.usuario.toString(),
      'carrito_id': widget.carritoId.toString(),
      'tipo_pago_id': widget.tipoPagoId.toString(),
    });

    final response = await http.post(uri, headers: headers, body: body);

    // Si la transacción fue creada con éxito
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Transacción creada con éxito.');

      // Opcional: Imprimir el cuerpo de la respuesta para depuración
      print('Respuesta del servidor: ${response.body}');

      // Obtener todas las transacciones para el usuario y generar la factura
      await obtenerUltimaTransaccionYGenerarFactura();
    } else {
      // Si hubo un error, mostrar el código de estado y el mensaje de error
      print('Error al realizar la transacción: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
    }
  } catch (e) {
    // Capturar cualquier otro error
    print('Error al realizar la transacción: $e');
  }
}

Future<void> obtenerUltimaTransaccionYGenerarFactura() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = widget.usuario;

    // URL para obtener las transacciones del usuario
    final uri = Uri.parse('http://157.230.227.216/api/transacciones?usuario_id=$userId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final response = await http.get(uri, headers: headers);

    // Si la solicitud fue exitosa
    if (response.statusCode == 200) {
      final transacciones = json.decode(response.body) as List<dynamic>;

      if (transacciones.isNotEmpty) {
        final ultimaTransaccion = transacciones.last;
        final transaccionId = ultimaTransaccion['id'];

        print('Última transacción ID: $transaccionId');

        final pdfFile = await generatePdfFile(transaccionId);
        await enviarFacturaAlBackend(transaccionId, pdfFile);

        // Verificar si el widget sigue montado antes de usar `context`
        if (mounted) {
          mostrarOpcionDescargarPDF(context, pdfFile);
        }
      } else {
        print('No se encontraron transacciones para el usuario.');
      }
    } else {
      print('Error al obtener las transacciones: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');
    }
  } catch (e) {
    print('Error al obtener las transacciones: $e');
  }
}





  Future<void> actualizarCarrito() async {
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
    (detalle) => detalle['carritoId'] == cartId,
    orElse: () => null,
  );

  if (detalleExistente != null) {
    // Si el detalle existe, procedemos a actualizar el carrito
    final carritoRequest = {
      'usuario': {'id': widget.usuario},
      'disponible': false,  // Establecemos disponible en false
      'productoDetalle': {'id': detalleExistente['id']}, // Obtenemos el id del productoDetalle existente
    };

    try {
      // Hacer la solicitud PUT para actualizar el carrito
      final response = await http.put(
        Uri.parse('http://157.230.227.216/api/carritos/$cartId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(carritoRequest),
      );

      if (response.statusCode == 200) {
        print('Carrito actualizado con éxito');
      } else {
        print('Error al actualizar el carrito: ${response.statusCode}');
        print('Respuesta: ${response.body}');
      }
    } catch (e) {
      print('Excepción al actualizar el carrito: $e');
    }
  } else {
    print('El producto no está en el carrito');
  }
}


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E272E),
          title: const Text('Paga con Stripe '),
        ),
        body: Stack(
          children: [
            Positioned(
              width: size.width,
              height: size.height,
              top: 200,
              child: PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tarjetas.length,
                  itemBuilder: (_, i) {
                    final tarjeta = tarjetas[i];

                    return GestureDetector(
                      onTap: () {
                        BlocProvider.of<PagarBloc>(context)
                            .add(OnSeleccionarTarjeta(tarjeta));
                        Navigator.push(context,
                            navegarFadeIn(context, const TarjetaPage()));
                      },
                      child: Hero(
                        tag: tarjeta.cardNumber,
                        child: CreditCardWidget(
                          cardNumber: tarjeta.cardNumberHidden,
                          expiryDate: tarjeta.expiracyDate,
                          cardHolderName: tarjeta.cardHolderName,
                          cvvCode: tarjeta.cvv,
                          showBackView: false,
                          onCreditCardWidgetChange: (CreditCardBrand) {},
                        ),
                      ),
                    );
                  }),
            ),
            Positioned(
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Monto a Pagar: ${widget.total}',
                    style: TextStyle(
                      color: Color(0xFF1E272E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  MaterialButton(
                    onPressed: () async {
                      await makePayment(widget.total);

                      if (done)
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Compra realizada con éxito"),
                              content: Text(
                                  "Tu compra ha sido realizada exitosamente."),
                              actions: <Widget>[
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                     Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                    },
                    height: 45,
                    minWidth: 150,
                    shape: const StadiumBorder(),
                    elevation: 0,
                    color: Colors.black,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Platform.isAndroid
                              ? FontAwesomeIcons.google
                              : FontAwesomeIcons.apple,
                          color: Colors.white,
                        ),
                        const Text(' Pagar',
                            style:
                                TextStyle(color: Colors.white, fontSize: 22)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
void mostrarOpcionDescargarPDF(BuildContext context, File pdfFile) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Compra realizada con éxito"),
        content: Text("Tu factura ha sido generada. ¿Deseas descargarla?"),
        actions: <Widget>[
          // Opción para ver el PDF
          TextButton(
            child: Text("Ver PDF"),
            onPressed: () async {
              // Cerrar el diálogo
              Navigator.of(context).pop();

              // Leer el PDF y mostrarlo
              final pdfBytes = await pdfFile.readAsBytes();
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdfBytes,
              );
            },
          ),
          // Opción para cancelar y redirigir al home
          TextButton(
            child: Text("Cancelar"),
            onPressed: () {
              Navigator.of(context).pop();
              // Redirigir al home
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => MyApp()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      );
    },
  );
}
