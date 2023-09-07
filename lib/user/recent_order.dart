// ignore_for_file: non_constant_identifier_names, prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentOrder extends StatefulWidget {
  const RecentOrder({Key? key}) : super(key: key);

  @override
  State<RecentOrder> createState() => _RecentOrderState();
}

class _RecentOrderState extends State<RecentOrder> {
  Timestamp? request_time;
  User? user = FirebaseAuth.instance.currentUser;
  int order = 0;
  String? userId;
  String? date;

  @override
  void initState() {
    userId = user?.uid;
    super.initState();
  }

  String formatRequestTime(Timestamp? timestamp) {
    if (timestamp != null) {
      DateTime dateTime = timestamp.toDate();
      date = DateFormat('yyyy-MM-dd ').format(dateTime);
      return DateFormat('HH:mm:ss').format(dateTime);
    } else {
      return '';
    }
  }

  void _editRecentFuelOrder(String index) async {
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(index)
        .update({"orderstate": 1});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          'Recent Order',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where("").snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          List<QueryDocumentSnapshot> documents = snapshot.data?.docs ?? [];

          // Filter the documents based on the document ID
          List<QueryDocumentSnapshot> filteredDocuments =
              documents.where((document) => document.id == userId).toList();

          if (filteredDocuments.isEmpty) {
            return Center(
              child: Text(
                'No fuel orders yet for this user.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            itemCount: filteredDocuments.length,
            itemBuilder: (BuildContext context, int index) {
              QueryDocumentSnapshot document = filteredDocuments[index];
              Map<String, dynamic>? data =
                  document.data() as Map<String, dynamic>?;

              var price = data?['Total'];

              request_time = data?['orderTime'] as Timestamp?;
              date = data?['date'] as String?;
              order = index + 1;

              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.shopping_cart),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Order $order",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.done),
                        onPressed: () {
                          _editRecentFuelOrder(document.id);
                        },
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatRequestTime(request_time),
                        style: TextStyle(
                          color: Colors.black,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        date!, // Use the null operator to handle null values
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    'Amount: ${price?.toStringAsFixed(2) ?? ''}', // Use the null operator to handle null values
                    style: TextStyle(
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
