import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nordic_id/nordic_id.dart';
import 'package:nordic_id/tag_epc.dart';
import 'package:permission_handler/permission_handler.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    initializeNordicId();
    return MaterialApp(
      title: 'Jardinerie',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SearchPageWrapper(),
        '/categories': (context) => CategoriesPage(),
      },
    );
  }
  Future<void> initializeNordicId() async {
    try {
      await NordicId.initialize;
    } catch (e) {
      print("Erreur lors de l'initialisation de Nordic ID : $e");
    }
  }
}

class SearchPageWrapper extends StatefulWidget {
  @override
  _SearchPageWrapperState createState() => _SearchPageWrapperState();
}

class _SearchPageWrapperState extends State<SearchPageWrapper> {
  late List<dynamic> productsData = [];

  @override
  void initState() {
    super.initState();
    loadJsonData();
  }

  Future<void> loadJsonData() async {
    String data = await DefaultAssetBundle.of(context).loadString('assets/data.json');
    Map<String, dynamic> jsonData = json.decode(data);
    List<dynamic> products = jsonData['produits'];
    setState(() {
      productsData = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (productsData.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('My App'),
          actions: [
            IconButton(
              icon: Icon(Icons.category),
              onPressed: () {
                Navigator.pushNamed(context, '/categories');
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RFIDReaderPage(productsData: productsData),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Connecter le lecteur RFID',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: SearchPage(allProducts: productsData),
              ),
            ],
          ),
        ),
      );
    }
  }
}


class ProductDetailPage extends StatelessWidget {
  final dynamic product;

  ProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du produit'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                product['image'],
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            _buildDetailItem('Nom', product['nom']),
            _buildDetailItem('Prix', '${product['prix']} \€'),
            _buildDetailItem('Stock', '${product['stock']}'),
            _buildDetailItem('Catégorie', product['categorie']),
            _buildDetailItem('Description', product['description']),
            // Autres détails du produit à afficher...
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
        Divider(height: 20, thickness: 1, color: Colors.grey),
      ],
    );
  }
}

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<dynamic> productsData = [];
  Set<String> uniqueCategories = Set();

  @override
  void initState() {
    super.initState();
    loadJsonData();
  }

  Future<void> loadJsonData() async {
    String data = await DefaultAssetBundle.of(context).loadString('assets/data.json');
    Map<String, dynamic> jsonData = json.decode(data);
    List<dynamic> products = jsonData['produits'];
    setState(() {
      productsData = products;
      uniqueCategories = Set.from(products.map((product) => product['categorie']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Catégories',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: uniqueCategories.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildCategoryItem('Tous les produits', 'AllProducts');
            } else if (index == 1) {
              return _buildCategoryItem('Autre', 'Other');
            }
            String category = uniqueCategories.elementAt(index - 2);
            return _buildCategoryItem(category, category.replaceAll(' ', ''));
          },
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, String routeName) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductsPage(
              category: title,
              allProducts: productsData,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<dynamic> allProducts;

  SearchPage({required this.allProducts});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late List<dynamic> filteredProducts;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredProducts = widget.allProducts;
    searchController.addListener(searchProducts);
  }

  void searchProducts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredProducts = widget.allProducts;
      } else {
        filteredProducts = widget.allProducts.where((product) {
          String productName = product['nom'].toLowerCase();
          return productName.contains(query);
        }).toList();
      }
    });
  }

  void navigateToProductDetail(dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          var product = filteredProducts[index];
          return ListTile(
            onTap: () {
              navigateToProductDetail(product);
            },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(product['image']),
            ),
            title: Text(product['nom']),
            subtitle: Text('Prix: ${product['prix']} \€'),
            // Autres détails du produit à afficher...
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    searchController.removeListener(searchProducts);
    searchController.dispose();
    super.dispose();
  }
}



class ProductsPage extends StatelessWidget {
  final String category;
  final List<dynamic> allProducts;

  ProductsPage({required this.category, required this.allProducts});

  void navigateToProductDetail(BuildContext context, dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredProducts;
    if (category == 'Tous les produits') {
      filteredProducts = allProducts;
    } else if (category == 'Autre') {
      filteredProducts = allProducts.where((product) => product['categorie'] == null).toList();
    } else {
      filteredProducts = allProducts.where((product) => product['categorie'] == category).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Produits - $category'),
      ),
      body: ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          var product = filteredProducts[index];
          return ListTile(
            onTap: () {
              navigateToProductDetail(context, product); // Passer le context ici
            },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(product['image']),
            ),
            title: Text(product['nom']),
            subtitle: Text('Prix: ${product['prix']} \€'),
            // Autres détails du produit à afficher...
          );
        },
      ),
    );
  }
}
class RFIDReaderPage extends StatefulWidget {
  final List<dynamic> productsData;

  RFIDReaderPage({required this.productsData});
  @override
  _RFIDReaderPageState createState() => _RFIDReaderPageState();
}

class _RFIDReaderPageState extends State<RFIDReaderPage> {
  String _platformVersion = 'Unknown';
  List<TagEpc> _data = [];
  bool isConnectedStatus = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initializeNordicId();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await NordicId.getPlatformVersion() ?? 'Plateforme non reconnue';
    } on PlatformException {
      platformVersion = 'Impossible de récupérer la plateforme';
    }

    NordicId.connectionStatusStream
        .receiveBroadcastStream()
        .listen(updateConnection);
    NordicId.tagsStatusStream.receiveBroadcastStream().listen(updateTags);

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> initializeNordicId() async {
    try {
      await NordicId.initialize;
    } catch (e) {
      print("Erreur lors de l'initialisation de Nordic ID : $e");
    }
  }



  void updateConnection(dynamic result) {
    setState(() {
      isConnectedStatus = result;
    });
  }
  void updateTags(dynamic result) {
    List<TagEpc> tags = TagEpc.parseTags(result);
    for (TagEpc tag in tags) {
      print('Tag EPC: ${tag.epc}, RSSI: ${tag.rssi}');

      // Recherche du produit correspondant au tag EPC scanné dans widget.productsData
      dynamic foundProduct = widget.productsData.firstWhere(
            (product) => product['tag'] == tag.epc, // Assurez-vous d'avoir la propriété 'tag' dans votre JSON
        orElse: () => null,
      );

      if (foundProduct != null) {
        print('Produit trouvé: ${foundProduct['nom']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: foundProduct),
          ),
        );
      }
    }

    setState(() {
      _data = tags;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner les étiquettes RFID'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                await NordicId.connect;
              },
              child: Text('Appairer le lecteur RFID'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NordicId.refreshTracing;
              },
              child: Text('Scanner la puce RFID'),
            ),
            SizedBox(height: 16),
            Text(
              'Appareil connecté: $isConnectedStatus',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 18),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _data.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.blue.shade100,
                    elevation: 2.0,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        'Tag EPC: ${_data[index].epc}',
                        style: TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        'RSSI: ${_data[index].rssi}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
