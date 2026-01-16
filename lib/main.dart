import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyShop',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FirebaseAuth.instance.currentUser == null
          ? LoginPage()
          : HomePage(),
    );
  }
}

/* ---------------- LOGIN ---------------- */

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  login() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text, password: password.text);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => HomePage()));
  }

  signup() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text, password: password.text);
    login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: password, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text("Login")),
            TextButton(onPressed: signup, child: Text("Create Account"))
          ],
        ),
      ),
    );
  }
}

/* ---------------- HOME / PRODUCTS ---------------- */

class HomePage extends StatelessWidget {
  final cart = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Products"),
        actions: [
          IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CartPage(cart)));
              })
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          return ListView(
            children: snap.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text("₹ ${doc['price']}"),
                trailing: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    cart.add(doc);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Added to cart")));
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/* ---------------- CART ---------------- */

class CartPage extends StatelessWidget {
  final List cart;
  CartPage(this.cart);

  placeOrder(BuildContext context) async {
    await FirebaseFirestore.instance.collection('orders').add({
      'user': FirebaseAuth.instance.currentUser!.email,
      'items': cart.map((e) => e['name']).toList(),
      'date': Timestamp.now()
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Order Placed")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cart")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: cart.map((e) => ListTile(title: Text(e['name']))).toList(),
            ),
          ),
          ElevatedButton(
              onPressed: () => placeOrder(context),
              child: Text("Place Order (COD)"))
        ],
      ),
    );
  }
}
