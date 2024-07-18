import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getaccess/Admin/AdminHomePage.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  TextEditingController userIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _loginUser() async {
    setState(() {
      isLoading = true;
    });

    String userId = userIdController.text;
    String password = passwordController.text;

    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('stockApp')
          .doc('Users')
          .collection('Admin')
          .doc('Admin')
          .get();

      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;

      if (data['userName'] == userId && data['password'] == password) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging in')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Login',style: TextStyle(
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