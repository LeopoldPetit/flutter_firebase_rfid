import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'ProductsPage.dart';

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<dynamic> productsData = [];
  Set<String> uniqueCategories = {
    'tous les produits',
    'autres',
    'piece detachees',
    'nettoyage',
    'tonte',
    'debroussaillage',
    'coupe',
    'taille',
    'valorisation dechets',
    'bois',
    'outils a batterie',
    'manutention',
    'porte outils',
    'travail du sol',
    'consommables',
    'accessoires',
    'desherbage mecanique',
  };
  List<dynamic> allProducts = [];
  List<dynamic> pieceProducts = [];
  List<dynamic> nettoyageProducts = [];
  List<dynamic> tonteProducts = [];
  List<dynamic> debroussaillageProducts = [];
  List<dynamic> coupeProducts = [];
  List<dynamic> tailleProducts = [];
  List<dynamic> valoDechetsProducts = [];
  List<dynamic> boisProducts = [];
  List<dynamic> outilsAbatterieProducts = [];
  List<dynamic> manutentionProducts = [];
  List<dynamic> porteOutilsProducts = [];
  List<dynamic> travailDuSolProducts = [];
  List<dynamic> consommablesProducts = [];
  List<dynamic> accessoiresProducts = [];
  List<dynamic> deserbageMecaProducts = [];
  List<dynamic> autreProducts = [];

  @override
  void initState() {
    super.initState();
    loadFirestoreData();
  }

  Future<void> loadFirestoreData() async {
    try {
      // Check if Firebase is initialized before using Firestore
      if (Firebase.apps.length == 0) {
        await Firebase.initializeApp();
      }

      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('produits').get();
      List<dynamic> products = querySnapshot.docs.map((doc) => doc.data()).toList();

      // Separate products into carton and other categories
      pieceProducts = products.where((product) => product['categorie'] == 'piece detachees').toList();
      nettoyageProducts = products.where((product) => product['categorie'] == 'nettoyage').toList();
      tonteProducts = products.where((product) => product['categorie'] == 'tonte').toList();
      debroussaillageProducts = products.where((product) => product['categorie'] == 'debroussaillage').toList();
      coupeProducts = products.where((product) => product['categorie'] == 'coupe').toList();
      tailleProducts = products.where((product) => product['categorie'] == 'taille').toList();
      valoDechetsProducts = products.where((product) => product['categorie'] == 'valorisation dechets').toList();
      boisProducts = products.where((product) => product['categorie'] == 'bois').toList();
      outilsAbatterieProducts = products.where((product) => product['categorie'] == 'outils a batterie').toList();
      manutentionProducts = products.where((product) => product['categorie'] == 'manutention').toList();
      porteOutilsProducts = products.where((product) => product['categorie'] == 'porte outils').toList();
      travailDuSolProducts = products.where((product) => product['categorie'] == 'travail du sol').toList();
      consommablesProducts = products.where((product) => product['categorie'] == 'consommables').toList();
      accessoiresProducts = products.where((product) => product['categorie'] == 'accessoires').toList();
      deserbageMecaProducts = products.where((product) => product['categorie'] == 'desherbage mecanique').toList();
      autreProducts = products.where((product) {
        return ![
          'piece detachees',
          'nettoyage',
          'tonte',
          'debroussaillage',
          'coupe',
          'taille',
          'valorisation dechets',
          'bois',
          'outils a batterie',
          'manutention',
          'porte outils',
          'travail du sol',
          'consommables',
          'accessoires',
          'desherbage mecanique',
        ].contains(product['categorie']);
      }).toList();


      setState(() {
        productsData = products;
        allProducts = products;
      });
    } catch (e) {
      print('Error loading Firestore data: $e');
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
          itemCount: uniqueCategories.length,
          itemBuilder: (context, index) {
            String category = uniqueCategories.elementAt(index);
            return _buildCategoryItem(category);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category) {
    String routeName = category.replaceAll(' ', '');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductsPage(
                  category: category,
                  allProducts: getCategoryProducts(category),
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
              category,
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

  List<dynamic> getCategoryProducts(String category) {
    if (category == 'tous les produits') {
      return allProducts;
    } else if (category == 'autres') {
      return autreProducts;
    } else if (category == 'piece detachees') {
      return pieceProducts;
    } else if (category == 'nettoyage') {
      return nettoyageProducts;
    } else if (category == 'tonte') {
      return tonteProducts;
    } else if (category == 'debroussaillage') {
      return debroussaillageProducts;
    } else if (category == 'coupe') {
      return coupeProducts;
    } else if (category == 'taille') {
      return tailleProducts;
    }
    else if (category == 'valorisation dechets') {
      return valoDechetsProducts;
    }
    else if (category == 'bois') {
      return boisProducts;
    }
    else if (category == 'outils a batterie') {
      return outilsAbatterieProducts;
    }
    else if (category == 'manutention') {
      return manutentionProducts;
    }
    else if (category == 'porte outils') {
      return porteOutilsProducts;
    }
    else if (category == 'travail du sol') {
      return travailDuSolProducts;
    }
    else if (category == 'consommables') {
      return consommablesProducts;
    }
    else if (category == 'accessoires') {
      return accessoiresProducts;
    }
    else if (category == 'desherbage mecanique') {
      return deserbageMecaProducts;
    }
    // Add more conditions for the remaining categories...

    return [];
  }
}

