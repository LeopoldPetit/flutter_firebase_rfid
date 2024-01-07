import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nordic_id/nordic_id.dart';
import 'package:nordic_id/tag_epc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

// Classe pour initialiser Firebase
class FirebaseInitializer {
  // Méthode statique pour initialiser Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

// Point d'entrée de l'application
Future<void> main() async {
  runApp(MyApp());
  await FirebaseInitializer.initialize(); // Initialisation de Firebase
}

// Classe principale de l'application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    initializeNordicId(); // Initialise la connexion Nordic ID
    return MaterialApp(
      title: 'Jardinerie', // Titre de l'application
      theme: ThemeData(
        primarySwatch: Colors.green, // Couleur principale de l'application
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/', // Route initiale de l'application
      routes: {
        '/': (context) => SearchPageWrapper(), // Page de recherche
        '/categories': (context) => CategoriesPage(), // Page de catégories
      },
    );
  }

  // Méthode pour initialiser Nordic ID
  Future<void> initializeNordicId() async {
    try {
      await NordicId.initialize; // Initialise Nordic ID pour la lecture RFID
    } catch (e) {
      print("Erreur lors de l'initialisation de Nordic ID : $e"); // Affiche les erreurs d'initialisation
    }
  }
}

// Classe pour la page de recherche
class SearchPageWrapper extends StatefulWidget {
  @override
  _SearchPageWrapperState createState() => _SearchPageWrapperState();
}

class _SearchPageWrapperState extends State<SearchPageWrapper> {
  late List<dynamic> productsData = []; // Liste pour stocker les données des produits

  @override
  void initState() {
    super.initState();
    loadFirestoreData(); // Charge les données Firestore au démarrage de la page
  }

  // Méthode pour charger les données Firestore
  Future<void> loadFirestoreData() async {
    try {
      // Vérifiez que Firebase a été initialisé avant d'utiliser Firestore
      if (Firebase.apps.length == 0) {
        await Firebase.initializeApp();
      }

      // Récupère les données de la collection 'produits' de Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('produits').get();
      List<dynamic> products = querySnapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        productsData = products; // Met à jour les données des produits
      });
    } catch (e) {
      print('Erreur lors du chargement des données Firestore : $e'); // Affiche les erreurs de chargement des données
    }
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductPage(), // Navigue vers la page d'ajout de produit
              ),
            );
          },
          child: Icon(Icons.add),
        ),
      );
    }
  }
}
class AddProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un produit'),
      ),
      body: ProductDetailForm(), // Utilisez le même formulaire que ProductDetailPage
    );
  }
}


class ProductDetailForm extends StatefulWidget {
  @override
  _ProductDetailFormState createState() => _ProductDetailFormState();
}

class _ProductDetailFormState extends State<ProductDetailForm> {
  late TextEditingController nomController;
  late TextEditingController prixController;
  late TextEditingController stockController;
  late TextEditingController categorieController;
  late TextEditingController descriptionController;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController();
    prixController = TextEditingController();
    stockController = TextEditingController();
    categorieController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    nomController.dispose();
    prixController.dispose();
    stockController.dispose();
    categorieController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> addProductToFirestore() async {
    try {
      // Vérifiez si une image est sélectionnée
      if (_image != null) {
        // Générez un nom d'image unique
        String imageFileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';

        // Téléchargez l'image dans Firebase Storage avec un nom unique
        Reference ref = FirebaseStorage.instance.ref().child('images').child(imageFileName);
        UploadTask uploadTask = ref.putFile(_image!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

        // Récupérez l'URL de l'image depuis Firebase Storage
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        // Enregistrez les autres données et l'URL de l'image dans Firestore
        Map<String, dynamic> productData = {
          'nom': nomController.text,
          'prix': double.parse(prixController.text),
          'stock': int.parse(stockController.text),
          'categorie': categorieController.text,
          'description': descriptionController.text,
          'image': imageUrl, // Ajoutez l'URL de l'image dans Firestore
        };

        await FirebaseFirestore.instance.collection('produits').add(productData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produit ajouté avec succès!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SearchPageWrapper(),
          ),
        ); // Revenir à la page précédente
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez sélectionner une image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du produit: $e')),
      );
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _image != null
              ? Image.file(_image!) // Affichage de l'image choisie
              : ElevatedButton(
            onPressed: () {
              _getImage(); // Bouton pour sélectionner une image depuis la galerie
            },
            child: Text('Ajouter une image'),
          ),
          _buildEditableDetailItem('Nom', nomController),
          _buildEditableDetailItem('Prix', prixController),
          _buildEditableDetailItem('Stock', stockController),
          _buildEditableDetailItem('Catégorie', categorieController),
          _buildEditableDetailItem('Description', descriptionController),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              addProductToFirestore();
            },
            child: Text('Ajouter le produit'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailItem(String title, TextEditingController controller) {
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
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
class ProductDetailPage extends StatefulWidget {
  final dynamic product;

  ProductDetailPage({required this.product});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late TextEditingController nomController;
  late TextEditingController prixController;
  late TextEditingController stockController;
  late TextEditingController categorieController;
  late TextEditingController descriptionController;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController(text: widget.product['nom']);
    prixController = TextEditingController(text: widget.product['prix'].toString());
    stockController = TextEditingController(text: widget.product['stock'].toString());
    categorieController = TextEditingController(text: widget.product['categorie']);
    descriptionController = TextEditingController(text: widget.product['description']);
  }

  @override
  void dispose() {
    nomController.dispose();
    prixController.dispose();
    stockController.dispose();
    categorieController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> deleteProduct() async {
    try {
      // Obtenez le document à partir de Firestore pour récupérer l'ID
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('produits')
          .where('nom', isEqualTo: widget.product['nom']) // Utilisez un champ unique pour obtenir le document
          .get();

      String productId = querySnapshot.docs.first.id; // Récupère l'ID du premier document correspondant

      // Supprime le document correspondant à l'ID récupéré
      await FirebaseFirestore.instance.collection('produits').doc(productId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produit supprimé avec succès!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SearchPageWrapper(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression du produit: $e')),
      );
    }
  }


  Future<void> updateProductData() async {
    try {
      // Obtenez le document à partir de Firestore pour récupérer l'ID
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('produits')
          .where('nom', isEqualTo: widget.product['nom']) // Utilisez un champ unique pour obtenir le document
          .get();

      String productId = querySnapshot.docs.first.id; // Récupère l'ID du premier document correspondant

      // Vérifiez si une nouvelle image a été sélectionnée
      if (_image != null) {
        Reference ref = FirebaseStorage.instance.ref().child('images').child('product_$productId.jpg');
        UploadTask uploadTask = ref.putFile(_image!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        // Mettre à jour toutes les données, y compris l'URL de la nouvelle image
        Map<String, dynamic> updatedProductData = {
          'nom': nomController.text,
          'prix': double.parse(prixController.text),
          'stock': int.parse(stockController.text),
          'categorie': categorieController.text,
          'description': descriptionController.text,
          'image': imageUrl, // Ajoutez l'URL de la nouvelle image
        };
        await FirebaseFirestore.instance.collection('produits').doc(productId).update(updatedProductData);
      } else {
        // Mettre à jour toutes les données sauf l'image
        Map<String, dynamic> updatedProductData = {
          'nom': nomController.text,
          'prix': double.parse(prixController.text),
          'stock': int.parse(stockController.text),
          'categorie': categorieController.text,
          'description': descriptionController.text,
        };
        await FirebaseFirestore.instance.collection('produits').doc(productId).update(updatedProductData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produit mis à jour avec succès!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SearchPageWrapper(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour du produit: $e')),
      );
    }
  }


  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }


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
            GestureDetector(
              onTap: () {
                _getImage();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: _image != null
                    ? Image.file(
                  _image!,
                  height: 200,
                  fit: BoxFit.cover,
                )
                    : Image.network(
                  widget.product['image'],
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildEditableDetailItem('Nom', nomController),
            _buildEditableDetailItem('Prix', prixController),
            _buildEditableDetailItem('Stock', stockController),
            _buildEditableDetailItem('Catégorie', categorieController),
            _buildEditableDetailItem('Description', descriptionController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                updateProductData();
              },
              child: Text('Modifier'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteProduct();
              },
              child: Text('Supprimer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableDetailItem(String title, TextEditingController controller) {
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
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
        ),
        SizedBox(height: 16),
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
    loadFirestoreData(); // Charge les données JSON au démarrage de la page
  }

  Future<void> loadFirestoreData() async {
    try {
      // Vérifiez que Firebase a été initialisé avant d'utiliser Firestore
      if (Firebase.apps.length == 0) {
        await Firebase.initializeApp();
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('produits').get();
      List<dynamic> products = querySnapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        productsData = products;
        uniqueCategories = Set.from(products.map((product) => product['categorie']));
      });
    } catch (e) {
      print('Erreur lors du chargement des données Firestore : $e');
    }
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

