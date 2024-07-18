import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getaccess/Admin/CreateUser.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home',style: TextStyle(
            color: Color.fromARGB(255, 68, 68, 68),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          ),
          backgroundColor: Color.fromARGB(255, 254, 255, 219),
        //centerTitle: true,
        toolbarHeight: 100,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateUser()),
              );
            },
            icon: Icon(Icons.add),
          ),
        ],

      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Managers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Students',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _currentIndex == 0
          ? _firestore
              .collection('stockApp')
              .doc('Users')
              .collection('Manager')
              .snapshots()
          : _firestore
              .collection('stockApp')
              .doc('Users')
              .collection('Student')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error fetching data'));
        }

        if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No users found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final userData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(userData['userName']),
                subtitle: Text('UID: ${userData['uid']}'),
                trailing: Switch(
                  value: userData['status'] == 'active',
                  onChanged: (value) async {
                    await _firestore
                        .collection('stockApp')
                        .doc('Users')
                        .collection(_currentIndex == 0 ? 'Manager' : 'Student')
                        .doc(userData['uid'])
                        .update({
                      'status': value ? 'active' : 'inactive',
                    });
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AdminHomePage(),
  ));
}
