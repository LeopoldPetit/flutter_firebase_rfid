import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nordic_id/nordic_id.dart';
import 'package:nordic_id/tag_epc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    initializeNordicId(); // Initialise la connexion Nordic ID
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
      await NordicId.initialize; // Initialise Nordic ID pour la lecture RFID
    } catch (e) {
      print("Erreur lors de l'initialisation de Nordic ID : $e"); // Affiche les erreurs d'initialisation
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
    loadJsonData(); // Charge les données du fichier JSON au démarrage
  }

  Future<void> loadJsonData() async {
    String data = await DefaultAssetBundle.of(context).loadString('assets/data.json'); // Charge le fichier JSON
    Map<String, dynamic> jsonData = json.decode(data); // Décode le JSON en une structure de données
    List<dynamic> products = jsonData['produits']; // Récupère la liste de produits
    setState(() {
      productsData = products; // Met à jour les données des produits dans l'état du widget
    });
  }

  @override
  Widget build(BuildContext context) {
    if (productsData.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Affiche un indicateur de chargement si les données ne sont pas encore chargées
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
                Navigator.pushNamed(context, '/categories'); // Navigue vers la page des catégories
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
                      builder: (context) => RFIDReaderPage(productsData: productsData), // Navigue vers la page de lecture RFID en passant les données des produits
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
                child: SearchPage(allProducts: productsData), // Affiche la page de recherche avec les produits chargés
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
    // Affiche les détails du produit dans une page Scaffold
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du produit'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Affiche l'image du produit
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                product['image'],
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            // Affiche les détails du produit tels que le nom, le prix, le stock, la catégorie et la description
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

  // Construit un élément de détail du produit avec un titre et une valeur
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
    loadJsonData(); // Charge les données JSON au démarrage de la page
  }

  Future<void> loadJsonData() async {
    String data = await DefaultAssetBundle.of(context).loadString('assets/data.json'); // Charge le fichier JSON
    Map<String, dynamic> jsonData = json.decode(data); // Décode le JSON en une structure de données
    List<dynamic> products = jsonData['produits']; // Récupère la liste de produits
    setState(() {
      productsData = products; // Met à jour les données des produits dans l'état du widget
      uniqueCategories = Set.from(products.map((product) => product['categorie'])); // Récupère les catégories uniques
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
              return _buildCategoryItem('Tous les produits', 'AllProducts'); // Affiche l'élément "Tous les produits"
            } else if (index == 1) {
              return _buildCategoryItem('Autre', 'Other'); // Affiche l'élément "Autre"
            }
            String category = uniqueCategories.elementAt(index - 2); // Récupère la catégorie à l'index
            return _buildCategoryItem(category, category.replaceAll(' ', '')); // Affiche les catégories
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
            ), // Passe la catégorie et les données des produits à la page des produits
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

// Widget de la page de recherche des produits
class SearchPage extends StatefulWidget {
  final List<dynamic> allProducts;

  SearchPage({required this.allProducts});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late List<dynamic> filteredProducts; // Liste des produits filtrés
  TextEditingController searchController = TextEditingController(); // Contrôleur du champ de recherche

  @override
  void initState() {
    super.initState();
    filteredProducts = widget.allProducts; // Initialise les produits filtrés avec tous les produits
    searchController.addListener(searchProducts); // Ajoute un écouteur pour détecter les changements dans le champ de recherche
  }

  // Fonction pour filtrer les produits en fonction de la recherche
  void searchProducts() {
    String query = searchController.text.toLowerCase(); // Convertit la recherche en minuscules
    setState(() {
      if (query.isEmpty) {
        filteredProducts = widget.allProducts; // Si la recherche est vide, affiche tous les produits
      } else {
        filteredProducts = widget.allProducts.where((product) {
          String productName = product['nom'].toLowerCase(); // Nom du produit en minuscules
          return productName.contains(query); // Vérifie si le nom du produit contient la recherche
        }).toList(); // Convertit les produits filtrés en liste
      }
    });
  }

  // Fonction pour naviguer vers la page de détails du produit sélectionné
  void navigateToProductDetail(dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product), // Navigue vers la page de détails du produit
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController, // Champ de recherche
          decoration: InputDecoration(
            hintText: 'Rechercher...', // Texte d'indication dans le champ de recherche
            border: InputBorder.none, // Pas de bordure autour du champ de recherche
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          var product = filteredProducts[index]; // Produit actuel dans la liste des produits filtrés
          return ListTile(
            onTap: () {
              navigateToProductDetail(product); // Lorsque l'utilisateur appuie sur un produit, navigue vers la page de détails de ce produit
            },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(product['image']), // Affiche l'image du produit dans un cercle
            ),
            title: Text(product['nom']), // Affiche le nom du produit
            subtitle: Text('Prix: ${product['prix']} \€'), // Affiche le prix du produit
            // Autres détails du produit à afficher...
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    searchController.removeListener(searchProducts); // Supprime l'écouteur de changement dans le champ de recherche
    searchController.dispose(); // Libère les ressources utilisées par le contrôleur du champ de recherche
    super.dispose();
  }
}




class ProductsPage extends StatelessWidget {
  final String category;
  final List<dynamic> allProducts;

  ProductsPage({required this.category, required this.allProducts});

  void navigateToProductDetail(BuildContext context, dynamic product) {
    // Navigue vers la page de détails du produit en utilisant le contexte actuel
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product), // Affiche la page de détails du produit
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredProducts;

    // Filtre les produits en fonction de la catégorie sélectionnée
    if (category == 'Tous les produits') {
      filteredProducts = allProducts;
    } else if (category == 'Autre') {
      // Filtrer les produits où la catégorie est nulle
      filteredProducts = allProducts.where((product) => product['categorie'] == null).toList();
    } else {
      // Filtrer les produits par la catégorie sélectionnée
      filteredProducts = allProducts.where((product) => product['categorie'] == category).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Produits - $category'), // Affiche le titre de la catégorie sélectionnée
      ),
      body: ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          var product = filteredProducts[index];
          return ListTile(
            onTap: () {
              navigateToProductDetail(context, product); // Ouvre la page de détails du produit lorsqu'il est sélectionné
            },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(product['image']), // Affiche l'image du produit
            ),
            title: Text(product['nom']), // Affiche le nom du produit
            subtitle: Text('Prix: ${product['prix']} \€'), // Affiche le prix du produit
          );
        },
      ),
    );
  }
}
class RFIDReaderPage extends StatefulWidget {
  final List<dynamic> productsData;

  RFIDReaderPage({required this.productsData}); // Constructeur prenant les données des produits

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
    initPlatformState(); // Initialisation de la plateforme pour la lecture RFID
    initializeNordicId(); // Initialisation de Nordic ID
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await NordicId.getPlatformVersion() ?? 'Plateforme non reconnue';
    } on PlatformException {
      platformVersion = 'Impossible de récupérer la plateforme';
    }

    NordicId.connectionStatusStream.receiveBroadcastStream().listen(updateConnection);
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
            (product) => product['tag'] == tag.epc, // Vérifie si la propriété 'tag' correspond au tag EPC scanné
        orElse: () => null,
      );

      if (foundProduct != null) {
        print('Produit trouvé: ${foundProduct['nom']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: foundProduct), // Ouvre la page de détails pour le produit trouvé
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
                await NordicId.connect; // Connecte le lecteur RFID
              },
              child: Text('Appairer le lecteur RFID'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NordicId.refreshTracing; // Rafraîchit le suivi RFID
              },
              child: Text('Scanner la puce RFID'),
            ),
            SizedBox(height: 16),
            Text(
              'Appareil connecté: $isConnectedStatus', // Affiche le statut de la connexion
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

