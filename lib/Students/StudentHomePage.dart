import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:getaccess/BasePage.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({Key? key}) : super(key: key);

  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _currentIndex = 0;
  late String _userName = "";
  bool _isBlocked = false;
  String _blockedRequestDetails = '';
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBlockedRequests();
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
        .collection('Student')
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
    return _isBlocked
        ? Center(
            child: Scaffold(
            body: SafeArea(
              child: Center(
                child: Container(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 3,
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Container(
                            child: Column(
                              children: [
                                Text(
                                  "You have been blocked\n from Application",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "Reason: Not Returning Item, \nPlease contact rescpected manager",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 18),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  _blockedRequestDetails,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ))
        : Scaffold(
            appBar: AppBar(
              title: Text(
                'Student Home',
                style: TextStyle(
                  color: Color.fromARGB(255, 68, 68, 68),
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _logout,
                  icon: Icon(Icons.logout),
                ),
              ],
              backgroundColor: Color.fromARGB(255, 254, 255, 219),
              // centerTitle: true,
              toolbarHeight: 100,
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
                  label: 'Holdings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message),
                  label: 'Your Requests',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message),
                  label: 'All Items',
                ),
              ],
            ),
          );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHoldings();
      case 1:
        return _buildNotifications();
      case 2:
        return _buildDashboard();
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading products: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No products available.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot product = snapshot.data!.docs[index];
            return ListTile(
              title: Text(product['productName']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available: ${product['quantity']}'),
                  SizedBox(height: 4),
                  FutureBuilder(
                    future: _getManagerName(product['managerUid']),
                    builder: (context, AsyncSnapshot<String> managerSnapshot) {
                      if (managerSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Text('Loading manager...');
                      }
                      if (managerSnapshot.hasError) {
                        return Text(
                            'Error loading manager: ${managerSnapshot.error}');
                      }
                      return Text('Manager: ${managerSnapshot.data}');
                    },
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  _showRequestDialog(
                    context,
                    product.id,
                    product['managerUid'],
                  );
                },
                child: Text('Request'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRequestDialog(
      BuildContext context, String productId, String managerUid) async {
    TextEditingController quantityController = TextEditingController();
    DateTime? fromDate;
    DateTime? toDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Request Product'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    fromDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 5),
                    );

                    if (fromDate != null) {
                      setState(() {});
                    }
                  },
                  child: Text('Select From Date'),
                ),
                SizedBox(height: 8),
                Text(
                  'From Date: ${fromDate != null ? fromDate!.toString().split(' ')[0] : 'Not selected'}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    toDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 5),
                    );

                    if (toDate != null) {
                      setState(() {});
                    }
                  },
                  child: Text('Select To Date'),
                ),
                SizedBox(height: 8),
                Text(
                  'To Date: ${toDate != null ? toDate!.toString().split(' ')[0] : 'Not selected'}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (quantityController.text.isNotEmpty &&
                      fromDate != null &&
                      toDate != null) {
                    await _sendRequest(productId, managerUid,
                        quantityController.text, fromDate!, toDate!);
                    Navigator.pop(context);
                  }
                },
                child: Text('Send'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendRequest(String productId, String managerUid,
      String quantity, DateTime fromDate, DateTime toDate) async {
    try {
      String? uid;
      String? productName;

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

      // Fetch product name
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Products')
          .collection('pid')
          .doc(productId)
          .get();

      if (productSnapshot.exists) {
        productName = productSnapshot['productName'];
      }

      FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Requests')
          .collection("req")
          .add({
        'productId': productId,
        'productName': productName,
        'managerUid': managerUid,
        'studentUid': uid,
        'quantity': quantity,
        'fromDate': fromDate,
        'toDate': toDate,
        'status': 'requested',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request sent successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error sending request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error sending request. Please try again.' + e.toString()),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildNotifications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Requests')
          .collection('req')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot request = snapshot.data!.docs[index];
              return Dismissible(
                key: ValueKey(request.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await _deleteRequest(request.id);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    child: ListTile(
                      title: Text('Product: ${request['productName']}'),
                      subtitle: Column(
                        children: [
                          Text('Status: ${request['status']}'),
                          FutureBuilder(
                            future: _getManagerName(request['managerUid']),
                            builder: (context,
                                AsyncSnapshot<String> managerSnapshot) {
                              if (managerSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text('Loading...');
                              }
                              if (managerSnapshot.hasError) {
                                return Text('Error loading manager');
                              }
                              return Text('Manager: ${managerSnapshot.data}');
                            },
                          ),
                        ],
                      ),
                      tileColor: _getTileColor(request['status']),
                    ),
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

  Color _getTileColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return Colors.yellow[100]!;
      case 'approved':
        return Colors.green[100]!;
      case 'denied':
        return Colors.red[100]!;
      default:
        return Colors.white;
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('stockapp')
          .doc('request')
          .collection('req')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request deleted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting request. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildHoldings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Requests')
          .collection('req')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot request = snapshot.data!.docs[index];
              return ListTile(
                title: Text('ProductName: ${request['productName']}'),
                subtitle: FutureBuilder(
                  future: _getManagerName(request['managerUid']),
                  builder: (context, AsyncSnapshot<String> managerSnapshot) {
                    if (managerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Text('Loading...');
                    }
                    if (managerSnapshot.hasError) {
                      return Text('Error loading manager');
                    }
                    return Text('Manager: ${managerSnapshot.data}');
                  },
                ),
                trailing: FutureBuilder(
                  future: _calculateRemainingDays(request['toDate']),
                  builder: (context, AsyncSnapshot<int?> daysSnapshot) {
                    if (daysSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Text('Calculating...');
                    }
                    if (daysSnapshot.hasError || daysSnapshot.data == null) {
                      return Text('Error');
                    }
                    return Text('${daysSnapshot.data} days remaining');
                  },
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading holdings'));
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<String> _getManagerName(String managerUid) async {
    DocumentSnapshot managerDoc = await FirebaseFirestore.instance
        .collection('stockApp')
        .doc('Users')
        .collection('Manager')
        .doc(managerUid)
        .get();

    return managerDoc['userName'];
  }

  Future<int?> _calculateRemainingDays(Timestamp toDateTimestamp) async {
    DateTime toDate = toDateTimestamp.toDate();
    DateTime currentDate = DateTime.now();

    if (toDate.isAfter(currentDate)) {
      return toDate.difference(currentDate).inDays;
    }
    return null;
  }

  Future<void> _checkBlockedRequests() async {
    try {
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

      QuerySnapshot blockedRequestsSnapshot = await FirebaseFirestore.instance
          .collection('stockApp')
          .doc('Requests')
          .collection('req')
          .where('studentUid', isEqualTo: uid)
          .where('status', isEqualTo: 'blocked')
          .get();

      if (blockedRequestsSnapshot.docs.isNotEmpty) {
        setState(() async {
          _isBlocked = true;
          _blockedRequestDetails =
              'Product Name: ${blockedRequestsSnapshot.docs.first['productName']}\n';
          // 'Manager: ${await _getManagerName(blockedRequestsSnapshot.docs.first['managerUid']).toString()}';
        });
      }
    } catch (e) {
      print('Error checking blocked requests: $e');
    }
  }
}
