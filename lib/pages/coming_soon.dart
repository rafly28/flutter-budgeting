import 'package:flutter/material.dart';

class ComingSoonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Coming Soon'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.access_time,
              size: 120,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Aplikasi ini sedang dalam pengembangan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Kami sedang bekerja keras untuk membawa pengalaman terbaik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
