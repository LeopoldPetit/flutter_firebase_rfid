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
class ProductsPage extends StatelessWidget {
  final String category;
  final List<dynamic> allProducts;

  ProductsPage({required this.category, required this.allProducts});

  void navigateToProductDetail(BuildContext context, dynamic product) {
    // Navigate to the product detail page using the current context
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set filteredProducts directly to allProducts, displaying all products
    List<dynamic> filteredProducts = allProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Produits - $category'),
      ),
      body: ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          var product = filteredProducts[index];
          return ListTile(
            onTap: () {
              navigateToProductDetail(context, product);
            },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(product['image']),
            ),
            title: Text(product['nom']),
            subtitle: Text('Prix: ${product['prix']} \€'),
          );
        },
      ),
    );
  }
}