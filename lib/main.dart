import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nordic_id/nordic_id.dart';
import 'package:nordic_id/tag_epc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'CategoriesPage.dart';
import 'ProductDetailPage.dart';
import 'SearchPageWrapper.dart';
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

  class NordicIdManager {
  static final NordicIdManager _instance = NordicIdManager._internal();

  factory NordicIdManager() {
    return _instance;
  }

  NordicIdManager._internal();

  bool isConnected = false;

  Future<void> initializeNordicId() async {
    try {
      await NordicId.initialize;
      NordicId.connectionStatusStream.receiveBroadcastStream().listen(updateConnection);
    } catch (e) {
      print("Erreur lors de l'initialisation de Nordic ID : $e");
    }
  }

  void updateConnection(dynamic result) {
    isConnected = result;
  }

  Future<void> connect() async {
    await NordicId.connect;
  }

  Future<void> refreshTracing() async {
    await NordicId.refreshTracing;
  }
}



