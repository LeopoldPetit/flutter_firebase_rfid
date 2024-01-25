import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import 'SearchPageWrapper.dart';

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
  late TextEditingController refController;
  late TextEditingController condiController;
  late TextEditingController quantiCondiController;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController();
    prixController = TextEditingController();
    stockController = TextEditingController();
    categorieController = TextEditingController();
    refController = TextEditingController();
    condiController = TextEditingController();
    quantiCondiController = TextEditingController();
  }

  @override
  void dispose() {
    nomController.dispose();
    prixController.dispose();
    stockController.dispose();
    categorieController.dispose();
    refController.dispose();
    condiController.dispose();
    quantiCondiController.dispose();
    super.dispose();
  }

  Future<void> addProductToFirestore() async {
    try {
      String imageUrl; // Cette variable stockera l'URL de l'image

      // Vérifiez si une image est sélectionnée
      if (_image != null) {
        // Générez un nom d'image unique
        String imageFileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';

        // Téléchargez l'image dans Firebase Storage avec un nom unique
        Reference ref = FirebaseStorage.instance.ref().child('images').child(imageFileName);
        UploadTask uploadTask = ref.putFile(_image!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

        // Récupérez l'URL de l'image depuis Firebase Storage
        imageUrl = await taskSnapshot.ref.getDownloadURL();
      } else {
        // Utilisez une image par défaut si aucune image n'est sélectionnée
        imageUrl = 'https://image.spreadshirtmedia.net/image-server/v1/compositions/T993A1PA2181PT1X74Y25D157332725W9268H14775/views/1,width=550,height=550,appearanceId=1,backgroundColor=FFFFFF,noPt=true/point-dinterrogation-point-dinterrogation-tapis-de-souris.jpg'; // Remplacez par l'URL réelle de votre image par défaut
      }

      // Enregistrez les autres données et l'URL de l'image dans Firestore
      Map<String, dynamic> productData = {
        'nom': nomController.text,
        'prix': double.parse(prixController.text),
        'stock': int.parse(stockController.text),
        'categorie': categorieController.text,
        'référence': refController.text,
        'conditionnement': condiController.text,
        'quantité par conditionnement': quantiCondiController.text,
        'image': imageUrl, // Ajoutez l'URL de l'image dans Firestore
        'rfid': []
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
              ? Image.file(_image!) // Display the chosen image
              : ElevatedButton(
            onPressed: () {
              _getImage(); // Button to select an image from the gallery
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              primary: Colors.blue, // Background color
              onPrimary: Colors.white, // Text color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
              ),
            ),
            child: Text('Ajouter une image'),
          ),
          _buildEditableDetailItem('Nom', nomController),
          _buildEditableDetailItem('Prix', prixController),
          _buildEditableDetailItem('Stock', stockController),
          _buildEditableDetailItem('Catégorie', categorieController),
          _buildEditableDetailItem('référence', refController),
          _buildEditableDetailItem('conditionnement', condiController),
          _buildEditableDetailItem('quantité par conditionnement', quantiCondiController),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              addProductToFirestore();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              primary: Colors.green, // Background color
              onPrimary: Colors.white, // Text color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
              ),
            ),
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