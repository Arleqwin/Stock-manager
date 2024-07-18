import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUser extends StatefulWidget {
  const CreateUser({Key? key}) : super(key: key);

  @override
  _CreateUserState createState() => _CreateUserState();
}

class _CreateUserState extends State<CreateUser> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _semesterSubjectController =
      TextEditingController();
  final TextEditingController _employmentIDController = TextEditingController();

  String _role = 'Student'; // Default role
  bool _isActive = true;
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _generateUID();
  }

  void _generateUID() {
    final random = Random();
    final uid = List.generate(10, (index) => random.nextInt(9)).join();
    setState(() {
      _uid = uid;
    });
  }

  void _createUser() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    print("hii");
    try {
      await _firestore
          .collection('stockApp')
          .doc('Users')
          .collection(_role)
          .doc(_uid)
          .set({
        'userName': _userNameController.text,
        'password': _passwordController.text,
        'role': _role,
        'status': _isActive ? 'active' : 'inactive',
        'uid': _uid,
        'department': _departmentController.text,
        'semesterSubject': _semesterSubjectController.text,
        'employmentID': _employmentIDController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create User',
          style: TextStyle(
            color: Color.fromARGB(255, 68, 68, 68),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 254, 255, 219),
        // centerTitle: true,
        toolbarHeight: 100,

        actions: [
          ElevatedButton(
            onPressed: _createUser,
            style: ElevatedButton.styleFrom(
              // primary: Colors.blue,
              // onPrimary: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Create'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _userNameController,
              decoration: InputDecoration(labelText: 'UserName'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _departmentController,
              decoration: InputDecoration(labelText: 'Department'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _semesterSubjectController,
              decoration: InputDecoration(labelText: 'Semester/Subject'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _employmentIDController,
              decoration:
                  InputDecoration(labelText: 'Employment ID/Registration No'),
            ),
            SizedBox(height: 16.0),
            Text('Role:'),
            Wrap(
              spacing: 8.0,
              children: ['Manager', 'Student'].map((role) {
                return ChoiceChip(
                  label: Text(role),
                  selected: _role == role,
                  onSelected: (selected) {
                    setState(() {
                      _role = role;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Text('Status:'),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                Text(_isActive ? 'Active' : 'Inactive'),
              ],
            ),
            SizedBox(height: 16.0),
            Text('UID: $_uid'),
          ],
        ),
      ),
    );
  }
}
