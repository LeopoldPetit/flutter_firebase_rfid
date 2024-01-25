import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ProductDetailPage.dart';

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
          String productReference = product['référence'].toLowerCase(); // Reference du produit en minuscules
          return productName.contains(query) || productReference.contains(query); // Vérifie si le nom ou la référence du produit contient la recherche
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

