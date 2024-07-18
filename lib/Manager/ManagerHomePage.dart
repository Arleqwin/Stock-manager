import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:getaccess/Manager/AddProducts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getaccess/BasePage.dart';

class ManagerHomePage extends StatefulWidget {
  const ManagerHomePage({Key? key}) : super(key: key);

  @override
  _ManagerHomePageState createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  int _currentIndex = 0;
  late String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> _loadUserData() async {
    String? uid;
    try {
      var box = await Hive.openBox('myBox');
      uid = box.get('uid');
    } catch (e) {
      print('Hive error: $e');
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        uid = prefs.getString('uid');
      } else {
        print('Unsupported platform or web');
      }
    }

    FirebaseFirestore.instance
        .collection('stockApp')
        .doc('Users')
        .collection('Manager')
        .doc(uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          _userName = documentSnapshot['userName'];
        });
      } else {
        print('Document does not exist on the database');
      }
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BasePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manager Home',
          style: TextStyle(
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
            onPressed: _logout,
            icon: Icon(Icons.logout),
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
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Supplied Items',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                print('Add new item');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AddProducts()),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildRequests();
      case 2:
        return _buildSuppliedItems();

      default:
        return Center(child: Text('Unknown Page'));
    }
  }

  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Products')
          .collection('pid')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot product = snapshot.data!.docs[index];
              return ListTile(
                title: Text(product['productName']),
                subtitle: Text('Quantity: ${product['quantity']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteProduct(product.id);
                  },
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading products'));
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

//////////////

  Widget _buildRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Requests')
          .collection('req')
          .where('status', isEqualTo: 'requested')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot request = snapshot.data!.docs[index];
              return Card(
                color: Colors.yellow[100],
                child: ListTile(
                  title: FutureBuilder(
                    future: _getStudentDetails(request['studentUid']),
                    builder: (context, AsyncSnapshot<String> studentSnapshot) {
                      if (studentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Text('Loading...');
                      }
                      if (studentSnapshot.hasError) {
                        return Text('Error loading student');
                      }
                      return Text('Student: ${studentSnapshot.data}');
                    },
                  ),
                  subtitle: Column(
                    children: [
                      FutureBuilder(
                        future: _getProductName(request['productId']),
                        builder:
                            (context, AsyncSnapshot<String> productSnapshot) {
                          if (productSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text('Loading...');
                          }
                          if (productSnapshot.hasError) {
                            return Text('Error loading product');
                          }
                          return Text('Product Name: ${productSnapshot.data}');
                        },
                      ),
                      Text('Till: ${_formatDate(request['toDate'])}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await _updateRequestStatus(request.id, 'approved');
                          await _decreaseProductQuantity(
                              request['productId'], request['quantity']);
                        },
                        child: Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _updateRequestStatus(request.id, 'rejected');
                        },
                        child: Text('Reject'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading requests'));
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<String> _getProductName(String productId) async {
    DocumentSnapshot productDoc = await FirebaseFirestore.instance
        .collection('stockApp')
        .doc('Products')
        .collection('pid')
        .doc(productId)
        .get();

    return productDoc['productName'];
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection('stockApp')
        .doc('Requests')
        .collection('req')
        .doc(requestId)
        .update({'status': status});
  }

  Future<void> _decreaseProductQuantity(String productId, int quantity) async {
    DocumentReference productRef = FirebaseFirestore.instance
        .collection('stockApp')
        .doc('Products')
        .collection('pid')
        .doc(productId);

    DocumentSnapshot productDoc = await productRef.get();

    if (productDoc.exists) {
      int currentQuantity = productDoc['quantity'];
      int updatedQuantity = currentQuantity - quantity;

      await productRef.update({'quantity': updatedQuantity});
    }
  }

  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

//////////////////////////////

  Future<String> _getStudentDetails(String studentUid) async {
    DocumentSnapshot studentDoc = await FirebaseFirestore.instance
        .collection('stockApp')
        .doc('Users')
        .collection('Student')
        .doc(studentUid)
        .get();

    return studentDoc['userName'];
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Products')
          .collection('pid')
          .doc(productId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product deleted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildSuppliedItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Requests')
          .collection('req')
          .where('status', whereIn: ['approved', 'blocked']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot request = snapshot.data!.docs[index];
              bool isBlocked = request['status'] == 'blocked';
              return Card(
                color: isBlocked ? Colors.red[100] : null,
                child: ListTile(
                  title: FutureBuilder(
                    future: _getStudentDetails(request['studentUid']),
                    builder: (context, AsyncSnapshot<String> studentSnapshot) {
                      if (studentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Text('Loading...');
                      }
                      if (studentSnapshot.hasError) {
                        return Text('Error loading student');
                      }
                      return Text('Student: ${studentSnapshot.data}');
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Product Name: ${request['productName']}'),
                      FutureBuilder(
                        future: _calculateRemainingTime(request['toDate']),
                        builder:
                            (context, AsyncSnapshot<String?> timeSnapshot) {
                          if (timeSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text('Calculating...');
                          }
                          if (timeSnapshot.hasError ||
                              timeSnapshot.data == null) {
                            return Text('Error');
                          }
                          return Text('Time Remaining: ${timeSnapshot.data}');
                        },
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await _updateRequestStatus(request.id, 'received');
                        },
                        child: Text('Received'),
                      ),
                      if (!isBlocked)
                        ElevatedButton(
                          onPressed: () async {
                            await _updateRequestStatus(request.id, 'blocked');
                          },
                          child: Text('Block'),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading supplied items'));
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<String?> _calculateRemainingTime(Timestamp toDateTimestamp) async {
    DateTime toDate = toDateTimestamp.toDate();
    DateTime currentDate = DateTime.now();

    if (toDate.isAfter(currentDate)) {
      Duration remainingTime = toDate.difference(currentDate);
      return '${remainingTime.inDays} days ${remainingTime.inHours.remainder(24)} hours';
    }
    return null;
  }
}
