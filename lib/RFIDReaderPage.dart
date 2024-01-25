import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nordic_id/nordic_id.dart';
import 'package:nordic_id/tag_epc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'AddProductPage.dart';
import 'ProductDetailPage.dart';
import 'SearchPage.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import 'main.dart';
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
  final NordicIdManager nordicIdManager = NordicIdManager();

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
    List<TagEpc> tags = TagEpc.parseTags(result);
    for (TagEpc tag in tags) {
      print('Tag EPC: ${tag.epc}, RSSI: ${tag.rssi}');

      // Recherche du produit correspondant au tag EPC scanné dans widget.productsData
      dynamic foundProduct = widget.productsData.firstWhere(
            (product) {
          final rfidList = product['rfid'];
          return rfidList is List && rfidList.contains(tag.epc);
        },
        orElse: () => null,
      );

      if (foundProduct != null) {
        print('Produit trouvé: ${foundProduct['nom']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: foundProduct),
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
        title: Text('Scanner un article'),
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
                await nordicIdManager.refreshTracing();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                primary: Colors.blue, // Background color
                onPrimary: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
              ),
              child: Text('Scanner article'),
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