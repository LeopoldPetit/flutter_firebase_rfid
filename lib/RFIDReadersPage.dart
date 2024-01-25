import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nordic_id/nordic_id.dart';
import 'package:nordic_id/tag_epc.dart';
import 'main.dart';
class RFIDReadersPage extends StatefulWidget {
  final List<dynamic> productsData;

  RFIDReadersPage({required this.productsData}); // Constructeur prenant les données des produits

  @override
  _RFIDReadersPageState createState() => _RFIDReadersPageState();
}

class _RFIDReadersPageState extends State<RFIDReadersPage> {
  String _platformVersion = 'Unknown';
  List<TagEpc> _data = [];
  List<TagEpc> _allScannedTags = [];
  bool isConnectedStatus = false;
  final NordicIdManager nordicIdManager = NordicIdManager();
  bool onPressed = false;

  @override
  void initState() {
    super.initState();
    initPlatformState(); // Initialisation de la plateforme pour la lecture RFID
    nordicIdManager.initializeNordicId();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await NordicId.getPlatformVersion() ?? 'Plateforme non reconnue';
    } on PlatformException {
      platformVersion = 'Impossible de récupérer la plateforme';
    }

    NordicId.connectionStatusStream.receiveBroadcastStream().listen(
        updateConnection);
    NordicId.tagsStatusStream.receiveBroadcastStream().listen(updateTags);

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }


  void updateConnection(dynamic result) {
    setState(() {
      isConnectedStatus = result;
    });
  }

  void updateTags(dynamic result) {
    List<TagEpc> newTags = TagEpc.parseTags(result);

    for (TagEpc tag in newTags) {
      if (!_data.any((existingTag) => existingTag.epc == tag.epc)) {
        _data.add(tag);
      }
    }

    setState(() {});
  }

  Future<void> updateTagsInFirestore() async {
    try {
      // Get the document reference for the specific document in the 'tagScanner' collection
      DocumentReference tagScannerDocRef = FirebaseFirestore.instance
          .collection('tagScanner').doc('tagScanner');

      // Extract the EPC values from _data
      List<String> scannedEpcs = _data.map((tag) => tag.epc).toList();

      // Update the 'rfid' field in the document using FieldValue.arrayUnion
      await tagScannerDocRef.update(
          {'rfid': FieldValue.arrayUnion(scannedEpcs)});

      // Show a success toast message
      Fluttertoast.showToast(
        msg: 'produit enregistré avec succés',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      // Show an error toast message
      Fluttertoast.showToast(
        msg: 'Error updating RFID array in Firestore: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
  Future<void> clearTagsInFirestore() async {
    try {
      // Obtenez la référence du document pour la collection 'tagScanner'
      DocumentReference tagScannerDocRef =
      FirebaseFirestore.instance.collection('tagScanner').doc('tagScanner');

      // Supprimez le champ 'rfid' du document
      await tagScannerDocRef.update({'rfid': FieldValue.delete()});

      // Affichez un message de succès
      Fluttertoast.showToast(
        msg: 'Tags supprimés avec succès',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      // Affichez un message d'erreur en cas d'échec
      Fluttertoast.showToast(
        msg: 'Erreur lors de la suppression des tags: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner les articles'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                await nordicIdManager.connect();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                primary: Colors.blue, // Background color
                onPrimary: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
              ),
              child: Text('Appairer le lecteur RFID'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                onPressed = false;
                await nordicIdManager.refreshTracing();
              },
              onLongPress: () async {
                onPressed = true;
                while (onPressed) {
                  await nordicIdManager.refreshTracing();
                  await Future.delayed(Duration(milliseconds: 100));
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                primary: Colors.blue, // Background color
                onPrimary: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
              ),
              child: Text('Scanner'),
            ),
            ElevatedButton(
              onPressed: () async {
                updateTagsInFirestore();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                primary: Colors.green, // Background color
                onPrimary: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
              ),
              child: Text('Enregistrer le stock'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await clearTagsInFirestore();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                primary: Colors.red, // Couleur de fond
                onPrimary: Colors.white, // Couleur du texte
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Coins arrondis
                ),
              ),
              child: Text('Vider le stock'),
            ),
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
