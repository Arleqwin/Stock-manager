import 'package:flutter/material.dart';
import 'package:getaccess/Admin/AdminLogin.dart';
import 'package:getaccess/Manager/ManagerLogin.dart';
import 'package:getaccess/Students/StudentLogin.dart';

class BasePage extends StatelessWidget {
  const BasePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login Options',
          style: TextStyle(
            color: Color.fromARGB(255, 68, 68, 68),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 254, 255, 219),
        centerTitle: true,
        toolbarHeight: 100,
      ),
      body: Container(
        
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/image/background_image.jpg"), // Replace "background_image.jpg" with your image file
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color.fromARGB(117, 255, 255, 255), BlendMode.srcATop),

          ),
        ),
        child: Center(
    
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:CrossAxisAlignment.center,
            // mainAxisSize: MainAxisSize.max,
            
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StudentLogin()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 255, 139, 0),
                  backgroundColor:
                      const Color.fromARGB(255, 68, 68, 68), // Text color
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20), // Button size
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Button border radius
                  ),
                ),
                child: Text('Student Login'),
                
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminLoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 255, 139, 0),
                  backgroundColor:
                      const Color.fromARGB(255, 68, 68, 68), // Text color
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20), // Button size
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Button border radius
                  ),
                ),
                child: Text('Admin Login'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManagerLoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 255, 139, 0),
                  backgroundColor:
                      const Color.fromARGB(255, 68, 68, 68), // Text color
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20), // Button size
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Button border radius
                  ),
                ),
                child: Text('Manager Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
