import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import 'RFIDReaderWriterPage.dart';
import 'SearchPageWrapper.dart';

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
  late TextEditingController refController;
  late TextEditingController condiController;
  late TextEditingController quantiCondiController;
  File? _image;
  final picker = ImagePicker();
  late String productId;


  @override
  void initState() {
    super.initState();
    nomController = TextEditingController(text: widget.product['nom']);
    prixController = TextEditingController(text: widget.product['prix'].toString());
    stockController = TextEditingController(text: widget.product['stock'].toString());
    categorieController = TextEditingController(text: widget.product['categorie']);
    refController = TextEditingController(text: widget.product['référence']);
    condiController = TextEditingController(text: widget.product['conditionnement']);
    quantiCondiController = TextEditingController(text: widget.product['quantité par conditionnement']);
    getProductId();
  }

  Future<void> getProductId() async {
    try {
      // Obtenez le document à partir de Firestore pour récupérer l'ID
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('produits')
          .where('nom', isEqualTo: widget.product['nom']) // Utilisez un champ unique pour obtenir le document
          .get();

      productId = querySnapshot.docs.first.id; // Récupère l'ID du premier document correspondant

    } catch (e) {
      print('Erreur lors du chargement des Id Firestore : $e'); // Affiche les erreurs de chargement des données
    }
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
          'référence': refController.text,
          'conditionnement': condiController.text,
          'quantité par conditionnement': quantiCondiController.text,
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
          'référence': refController.text,
          'conditionnement': condiController.text,
          'quantité par conditionnement': quantiCondiController.text,
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
            _buildEditableDetailItem('référence', refController),
            _buildEditableDetailItem('conditionnement', condiController),
            _buildEditableDetailItem('quantité par conditionnement', quantiCondiController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                updateProductData();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                primary: Colors.blue, // Background color
                onPrimary: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
              ),
              child: Text('Modifier'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteProduct();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                primary: Colors.red, // Background color
                onPrimary: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
              ),
              child: Text('Supprimer'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RFIDReaderWriterPage(productId: productId),
            ),
          );
        },
        child: Icon(Icons.add_box),
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
