import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getaccess/Manager/ManagerHomePage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerLoginPage extends StatelessWidget {
  const ManagerLoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController userIdController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    Future<void> _loginUser() async {
      String userId = userIdController.text;
      String password = passwordController.text;

      print(userId + password);
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection('stockApp')
            .doc('Users')
            .collection('Manager')
            .where('userName', isEqualTo: userId)
            .where('password', isEqualTo: password)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Store UID in secure storage
          String uid = querySnapshot.docs.first['uid'];
          // var box = await Hive.openBox('myBox');
          // box.put('uid', uid);

          try {
            var box = await Hive.openBox('myBox');
            box.put('uid', uid);
          } catch (e) {
            print('Hive error: $e');
            // If Hive fails, use SharedPreferences as a fallback
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('uid', uid);
            } else {
              print('Unsupported platform or web');
            }
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ManagerHomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid credentials')),
          );
        }
      } catch (e) {
        print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging in' + e.toString())),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Login',style: TextStyle(
            color: Color.fromARGB(255, 68, 68, 68),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          ),
          backgroundColor: Color.fromARGB(255, 254, 255, 219),
        //centerTitle: true,
        toolbarHeight: 100,
      ),
      body: Padding(
    padding: EdgeInsets.all(16.0),
    child: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 198, 11),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
        
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: userIdController,
            decoration: InputDecoration(
              labelText: 'User ID',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loginUser,
            style: ElevatedButton.styleFrom(
              // primary: Colors.blue,
              // onPrimary: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Login'),
          ),
        ],
      ),
    ),
  ),
  backgroundColor: Color.fromARGB(255, 254, 255, 219),
);
  }
}