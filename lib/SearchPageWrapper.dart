import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nordic_id/nordic_id.dart';
import 'package:nordic_id/tag_epc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'AddProductPage.dart';
import 'RFIDReaderPage.dart';
import 'RFIDReadersPage.dart';
import 'SearchPage.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import 'main.dart';

class SearchPageWrapper extends StatefulWidget {
  @override
  _SearchPageWrapperState createState() => _SearchPageWrapperState();
}

class _SearchPageWrapperState extends State<SearchPageWrapper> {
  late List<dynamic> productsData = []; // Liste pour stocker les données des produits

  @override
  void initState() {
    super.initState();
    loadDataWithRetry();

  }

  // Méthode pour charger les données Firestore
  Future<void> loadFirestoreData() async {
    try {
      // Vérifiez que Firebase a été initialisé avant d'utiliser Firestore
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Récupère les données de la collection 'produits' de Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('produits').get();
      List<dynamic> products = querySnapshot.docs.map((doc) => doc.data()).toList();

      // Assurez-vous que le widget est toujours monté avant de mettre à jour l'état
      if (mounted) {
        setState(() {
          productsData = products; // Met à jour les données des produits
        });
      }
    } catch (e) {
      if (e is PlatformException) {
        print('Erreur de plateforme lors du chargement des données Firestore : ${e.message}');
      } else {
        print('Erreur inattendue lors du chargement des données Firestore : $e');
      }
      throw e;
    }
  }
  Future<void> loadDataWithRetry() async {
    const maxRetryAttempts = 10; // Nombre maximal de tentatives
    var retryAttempt = 0;

    while (retryAttempt < maxRetryAttempts) {
      try {
        await loadFirestoreData();
        // Si le chargement réussit, sortir de la boucle
        break;
      } catch (e) {
        print('Erreur lors du chargement des données Firestore  azdadazd: $e');
        retryAttempt++;

        if (retryAttempt < maxRetryAttempts) {
          print('Tentative de réessai #${retryAttempt + 1}');
          // Attendre avant la prochaine tentative (peut être ajusté en fonction de vos besoins)
          await Future.delayed(Duration(seconds: 2));
        } else {
          print('Échec après $maxRetryAttempts tentatives. Arrêt des réessais.');
          // Gérer l'échec après plusieurs tentatives (peut être ajusté en fonction de vos besoins)
          // Vous pouvez lancer une nouvelle exception, afficher un message à l'utilisateur, etc.
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (productsData.isEmpty) {
      print("Les données ne sont pas encore chargées");
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
                      builder: (context) => RFIDReaderPage(productsData: productsData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  primary: Colors.blue, // Background color
                  onPrimary: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  ),
                ),
                child: Text(
                  'Verifier un article',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              SizedBox(height: 16), // Add some space between buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductTagComparisonPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  primary: Colors.blue, // Background color
                  onPrimary: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  ),
                ),
                child: Text(
                  'Voir le stock',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              SizedBox(height: 16), // Add some space between buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RFIDReadersPage(productsData: productsData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  primary: Colors.green, // Background color
                  onPrimary: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  ),
                ),
                child: Text(
                  'Faire le stock',
                  style: TextStyle(fontSize: 16.0),
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