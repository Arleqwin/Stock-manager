import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AddProducts extends StatefulWidget {
  const AddProducts({Key? key}) : super(key: key);

  @override
  _AddProductsState createState() => _AddProductsState();
}

class _AddProductsState extends State<AddProducts> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _statusController =
      TextEditingController(text: 'Available');
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _managerUidController = TextEditingController();
  final Uuid uuid = Uuid();
  final CollectionReference productsCollection = FirebaseFirestore.instance
      .collection('stockApp')
      .doc('Products')
      .collection('pid');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Products',
          style: TextStyle(
            color: Color.fromARGB(255, 68, 68, 68),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 254, 255, 219),
        // centerTitle: true,
        toolbarHeight: 100,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _productNameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _statusController,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _categoryController.text.isNotEmpty
                  ? _categoryController.text
                  : null,
              items: [
                'Lab items',
                'Classroom items',
                'Research items',
                'General'
              ].map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _categoryController.text = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _departmentController,
              decoration: InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Upload data to Firestore
                String? uid;
                try {
                  var box = await Hive.openBox('myBox');
                  uid = box.get('uid');
                } catch (e) {
                  print('Hive error: $e');
                  if (!kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.android) {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    uid = prefs.getString('uid');
                  } else {
                    print('Unsupported platform or web');
                  }
                }

                try {
                  await productsCollection.add({
                    'productName': _productNameController.text,
                    'description': _descriptionController.text,
                    'quantity': int.parse(_quantityController.text),
                    'status': _statusController.text,
                    'category': _categoryController.text,
                    'department': _departmentController.text,
                    'managerUid': uid,
                  });

                  // Clear text fields
                  _productNameController.clear();
                  _descriptionController.clear();
                  _quantityController.clear();
                  _statusController.text = 'Available';
                  _categoryController.clear();
                  _departmentController.clear();
                  _managerUidController.clear();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product added successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  print('Firestore error: $e');
                  // Handle the error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding product. Please try again.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
