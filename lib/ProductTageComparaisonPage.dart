import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductTagComparisonPage extends StatefulWidget {
  @override
  _ProductTagComparisonPageState createState() =>
      _ProductTagComparisonPageState();
}

class _ProductTagComparisonPageState extends State<ProductTagComparisonPage> {
  List<String> matchingProducts = [];
  bool isLoading = false;

  List<String> tagScannerTags = [];
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    fetchData(); // Appel initial pour récupérer les données une seule fois
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    tagScannerTags = await getTagScannerTags();
    products = await getProducts();

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('En stock :'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: isLoading ? null : () => compareTags(),
            style: ElevatedButton.styleFrom(
              primary: Colors.blue, // Couleur de fond du bouton
              onPrimary: Colors.white, // Couleur du texte sur le bouton
              elevation: 3, // Élévation du bouton
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Espacement interne du bouton
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Bordure arrondie du bouton
              ),
            ),
            child: Text(
              'charger',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              // Récupérez la liste des produits actuellement affichés
              List<Product> displayedProducts = getDisplayedProducts();

              // Mettez à jour le stock pour tous les produits affichés en utilisant la mise à jour par lot
              await updateProductsStock(context, displayedProducts);

              // Mettez à jour l'interface utilisateur si nécessaire
              setState(() {
                // ... (effectuez des mises à jour d'interface utilisateur si nécessaire)
              });
            },
            style: ElevatedButton.styleFrom(
              // ... (votre style de bouton actuel)
            ),
            child: Text(
              'Modifier le stock pour tous les produits affichés',
              style: TextStyle(
                // ... (votre style de texte actuel)
              ),
            ),
          ),
          SizedBox(height: 20),

          isLoading
              ? CircularProgressIndicator() // Afficher un indicateur de chargement
              : Expanded(
            child: matchingProducts.isEmpty
                ? Center(
              child: Text('Aucun produit correspondant trouvé.'),
            )
                : ListView.builder(
              itemCount: matchingProducts.length,
              itemBuilder: (context, index) {
                // Obtenez le produit correspondant
                Product product = getProductByName(matchingProducts[index]);

                // Affichez le nom du produit et le nombre de tags RFID
                return ListTile(
                  title: Text('${product.name}, en stock: ${getCorrespondingTagsCount(product.rfid)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Product getProductByName(String productName) {
    // Recherchez le produit dans la liste des produits
    return products.firstWhere((product) => product.name == productName);
  }
  Future<List<String>> getTagScannerTags() async {
    QuerySnapshot tagScannerSnapshot =
    await FirebaseFirestore.instance.collection('tagScanner').get();
    List<String> tags = [];
    for (QueryDocumentSnapshot doc in tagScannerSnapshot.docs) {
      List<dynamic>? rfidArray = doc['rfid'];
      if (rfidArray != null) {
        tags.addAll(rfidArray.map((rfid) => rfid.toString()));
      }
    }
    return tags;
  }

  List<Product> getDisplayedProducts() {
    List<Product> displayedProducts = [];
    for (String productName in matchingProducts) {
      Product product = getProductByName(productName);
      displayedProducts.add(product);
    }
    return displayedProducts;
  }
  Future<void> updateProductsStock(BuildContext context, List<Product> products) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (Product product in products) {
      // Find the document corresponding to the product name
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('produits').where('nom', isEqualTo: product.name).get();

      // If a corresponding document is found, update its stock
      if (querySnapshot.docs.isNotEmpty) {
        String documentId = querySnapshot.docs.first.id;

        batch.update(FirebaseFirestore.instance.collection('produits').doc(documentId), {'stock': getCorrespondingTagsCount(product.rfid)});
      } else {
        print('No corresponding document found for the product ${product.name}');
        // Handle the case where no corresponding document is found; perhaps create a new document with necessary data
      }
    }

    // Commit the batch update
    await batch.commit();

    // Display an alert indicating the successful update
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mise à jour réussie'),
          content: Text('Le stock des produits a été mis à jour avec succès.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }



  Future<List<Product>> getProducts() async {
    QuerySnapshot productsSnapshot =
    await FirebaseFirestore.instance.collection('produits').get();
    return productsSnapshot.docs.map((doc) {
      List<dynamic> rfidData = doc['rfid'] ?? [];
      List<String> rfidList = rfidData.map((item) => item.toString()).toList();

      Product product = Product(
        name: doc['nom'] ?? 'Produit sans nom',
        rfid: rfidList,
      );

      // Ajoutez cette ligne pour afficher le nombre de tags RFID pour chaque produit
      print('RFID count of ${product.name}: ${product.rfid.length}');

      return product;
    }).toList();
  }

  void compareTags() {
    matchingProducts = findMatchingProducts(tagScannerTags, products);
    setState(() {});
  }

  List<String> findMatchingProducts(
      List<String> tagScannerTags, List<Product> products) {
    List<String> matchingProducts = [];
    for (Product product in products) {
      if (product.hasMatchingRfid(tagScannerTags)) {
        matchingProducts.add(product.name);
      }
    }
    return matchingProducts;
  }
  int getCorrespondingTagsCount(List<String> productTags) {
    // Comptez le nombre de tags RFID dans tagScanner correspondant à ceux du produit
    return productTags.where((productTag) => tagScannerTags.contains(productTag)).length;
  }
}

class Product {
  final String name;
  final dynamic rfid; // Peut être List<String> ou String

  Product({required this.name, required this.rfid});

  factory Product.fromSnapshot(QueryDocumentSnapshot snapshot) {
    return Product(
      name: snapshot['nom'] ?? 'Produit sans nom',
      rfid: snapshot['rfid'] ?? [], // Utilisez une liste vide par défaut
    );
  }
  bool hasMatchingRfid(List<String> tagScannerTags) {
    if (rfid is List<String>) {
      return (rfid as List<String>).any((rfid) =>
          tagScannerTags.any((tag) => tag.toLowerCase() == rfid.toLowerCase()));
    } else if (rfid is String) {
      return tagScannerTags.any((tag) => tag.toLowerCase() == rfid.toLowerCase());
    } else if (rfid is List<dynamic>) {
      List<String> rfidList =
      rfid.map((item) => item.toString().toLowerCase()).toList();
      return rfidList.any((rfid) =>
          tagScannerTags.any((tag) => tag.toLowerCase() == rfid.toLowerCase()));
    }
    return false;
  }
}