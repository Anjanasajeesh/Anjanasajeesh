import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'firebase_options.dart'; // Added this import

// --- Global Firebase Instances ---
// These will be initialized once the app starts.
FirebaseFirestore? db;
fb_auth.FirebaseAuth? auth;

// Global variables provided by the Canvas environment for Firebase setup
// These are used to initialize Firebase and authenticate the user.
const String appId = String.fromEnvironment(
  'APP_ID',
  defaultValue: 'default-app-id',
);
// Removed firebaseConfigString as DefaultFirebaseOptions handles it

User?
currentUser; // Currently logged-in user (will be updated from Firebase Auth)

// --- Models ---

enum UserRole { user, admin }

enum OrderStatus { pending, approved, declined, completed, cancelled }

enum PaymentMethodType { cash, card }

class User {
  final String id;
  final String username; // Firebase email
  final UserRole role;
  String name;
  String email;
  String phone;
  Address? deliveryAddress;
  RecipientDetails? recipientDetails;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.deliveryAddress,
    this.recipientDetails,
  });

  // Factory constructor to create a User from a Firestore DocumentSnapshot
  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return User(
      id: doc.id,
      username: data['username'] ?? '',
      role: (data['role'] == 'admin') ? UserRole.admin : UserRole.user,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      deliveryAddress:
          data['deliveryAddress'] != null
              ? Address.fromMap(
                Map<String, dynamic>.from(data['deliveryAddress']),
              )
              : null,
      recipientDetails:
          data['recipientDetails'] != null
              ? RecipientDetails.fromMap(
                Map<String, dynamic>.from(data['recipientDetails']),
              )
              : null,
    );
  }

  // Method to convert a User object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'role': role == UserRole.admin ? 'admin' : 'user',
      'name': name,
      'email': email,
      'phone': phone,
      'deliveryAddress': deliveryAddress?.toMap(),
      'recipientDetails': recipientDetails?.toMap(),
    };
  }
}

class Product {
  final String id;
  String name;
  double price;
  String unit;
  String imageUrl; // Placeholder image URL

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.imageUrl,
  });

  // Factory constructor to create a Product from a Firestore DocumentSnapshot
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '',
      imageUrl:
          data['imageUrl'] ??
          'https://placehold.co/100x100/grey/white?text=Product',
    );
  }

  // Method to convert a Product object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {'name': name, 'price': price, 'unit': unit, 'imageUrl': imageUrl};
  }

  // Override equality and hashCode for Product to compare by ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents an item in the shopping cart.
/// This class is designed to be immutable.
class CartItem {
  final Product product;
  final double quantity; // Declared final for immutability

  CartItem({required this.product, this.quantity = 1.0});

  double get totalPrice => product.price * quantity;

  /// Creates a new [CartItem] instance with updated properties.
  /// This is the immutable way to "modify" a CartItem.
  CartItem copyWith({Product? product, double? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  // Method to convert CartItem to a Map for Firestore (as part of an Order)
  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'productPrice': product.price,
      'productUnit': product.unit,
      'productImageUrl': product.imageUrl,
      'quantity': quantity,
    };
  }

  // Factory constructor to create a CartItem from a Map (from Firestore)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product(
        id: map['productId'] ?? '',
        name: map['productName'] ?? '',
        price: (map['productPrice'] as num?)?.toDouble() ?? 0.0,
        unit: map['productUnit'] ?? '',
        imageUrl:
            map['productImageUrl'] ??
            'https://placehold.co/100x100/grey/white?text=Product',
      ),
      // Ensure quantity is parsed as double
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  // Override equality and hashCode for CartItem to compare by product ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product; // Compare based on product equality

  @override
  int get hashCode => product.hashCode; // Hash based on product's hash
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  OrderStatus status;
  PaymentMethodType paymentMethod;
  String? cardDetails; // For card payments

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.status = OrderStatus.pending,
    required this.paymentMethod,
    this.cardDetails,
  });

  // Factory constructor to create an Order from a Firestore DocumentSnapshot
  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      items:
          (data['items'] as List<dynamic>?)
              ?.map(
                (itemMap) =>
                    CartItem.fromMap(Map<String, dynamic>.from(itemMap)),
              )
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethodType.values.firstWhere(
        (e) => e.toString().split('.').last == data['paymentMethod'],
        orElse: () => PaymentMethodType.cash,
      ),
      cardDetails: data['cardDetails'],
    );
  }

  // Method to convert an Order object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'cardDetails': cardDetails,
    };
  }
}

class Address {
  String street;
  String city;
  String postalCode;
  String country;

  Address({
    this.street = '',
    this.city = '',
    this.postalCode = '',
    this.country = '',
  });

  String get fullAddress => '$street, $city, $postalCode, $country';

  // Method to convert Address to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
    };
  }

  // Factory constructor to create an Address from a Map (from Firestore)
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
    );
  }
}

class RecipientDetails {
  String name;
  String phone;
  String email;

  RecipientDetails({this.name = '', this.phone = '', this.email = ''});

  // Method to convert RecipientDetails to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'email': email};
  }

  // Factory constructor to create RecipientDetails from a Map (from Firestore)
  factory RecipientDetails.fromMap(Map<String, dynamic> map) {
    return RecipientDetails(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
    );
  }
}

// --- Services (Firebase Implementations) ---

class AuthService {
  // Login with Firebase Authentication
  Future<User?> login(String email, String password) async {
    try {
      fb_auth.UserCredential userCredential = await auth!
          .signInWithEmailAndPassword(email: email, password: password);
      final userDoc =
          await db!
              .collection('artifacts')
              .doc(appId)
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
      if (userDoc.exists) {
        return User.fromFirestore(userDoc);
      } else {
        // If user document doesn't exist, it might be a new user or admin not yet in Firestore
        // For this demo, we'll assume admin is pre-created in Firestore or handled differently.
        // For regular users, you might want to create their profile here.
        return null; // Or create a default user profile
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw e; // Re-throw to be caught by UI
    } catch (e) {
      print('Login Error: $e');
      rethrow; // Re-throw any other exceptions
    }
  }

  // Register a new user with Firebase Authentication and create a Firestore profile
  Future<User?> register(
    String email,
    String password,
    String name,
    String phone,
    UserRole role,
  ) async {
    try {
      fb_auth.UserCredential userCredential = await auth!
          .createUserWithEmailAndPassword(email: email, password: password);
      final newUser = User(
        id: userCredential.user!.uid,
        username: email,
        role: role, // Use the selected role
        name: name,
        email: email,
        phone: phone,
      );
      await db!
          .collection('artifacts')
          .doc(appId)
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toFirestore());
      return newUser;
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw e; // Re-throw to be caught by UI
    } catch (e) {
      print('Registration Error: $e');
      rethrow; // Re-throw any other exceptions
    }
  }

  // Logout from Firebase
  Future<void> logout() async {
    await auth!.signOut();
    currentUser = null;
  }

  // Get user details from Firestore
  Future<User?> getUserDetails(String userId) async {
    try {
      final doc =
          await db!
              .collection('artifacts')
              .doc(appId)
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting user details: $e');
    }
    return null;
  }

  // Update user details in Firestore
  Future<void> updateUserDetails(User user) async {
    try {
      await db!
          .collection('artifacts')
          .doc(appId)
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      print('Error updating user details: $e');
    }
  }
}

class ProductService {
  // Get all products from Firestore
  Stream<List<Product>> getProducts() {
    return db!
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('products')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  // Add a new product to Firestore
  Future<void> addProduct(Product product) async {
    try {
      await db!
          .collection('artifacts')
          .doc(appId)
          .collection('public')
          .doc('data')
          .collection('products')
          .add(product.toFirestore());
    } catch (e) {
      print('Error adding product: $e');
    }
  }

  // Update an existing product in Firestore
  Future<void> updateProduct(Product updatedProduct) async {
    try {
      await db!
          .collection('artifacts')
          .doc(appId)
          .collection('public')
          .doc('data')
          .collection('products')
          .doc(updatedProduct.id)
          .update(updatedProduct.toFirestore());
    } catch (e) {
      print('Error updating product: $e');
    }
  }

  // Delete a product from Firestore
  Future<void> deleteProduct(String productId) async {
    try {
      await db!
          .collection('artifacts')
          .doc(appId)
          .collection('public')
          .doc('data')
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      print('Error deleting product: $e');
    }
  }
}

class OrderService {
  // Place a new order in Firestore
  Future<void> placeOrder(Order order) async {
    try {
      await db!
          .collection('artifacts')
          .doc(appId)
          .collection('users')
          .doc(order.userId)
          .collection('orders')
          .add(order.toFirestore());
    } catch (e) {
      print('Error placing order: $e');
    }
  }

  // Get user-specific orders from Firestore
  Stream<List<Order>> getUserOrders(String userId) {
    return db!
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(userId)
        .collection('orders')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
        });
  }

  // Get all orders (for admin) from Firestore
  Stream<List<Order>> getAllOrders() {
    // This query assumes a flat collection of all orders or iterates through user subcollections.
    // For simplicity, we'll fetch from all user subcollections. In a real app, you might have a single 'all_orders' collection for admin view.
    // A more robust solution would involve a dedicated 'all_orders' collection or cloud functions.
    return db!
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .snapshots()
        .asyncMap((userSnapshots) async {
          List<Order> allOrders = [];
          for (var userDoc in userSnapshots.docs) {
            final ordersSnapshot =
                await db!
                    .collection('artifacts')
                    .doc(appId)
                    .collection('users')
                    .doc(userDoc.id)
                    .collection('orders')
                    .get();
            allOrders.addAll(
              ordersSnapshot.docs
                  .map((doc) => Order.fromFirestore(doc))
                  .toList(),
            );
          }
          return allOrders;
        });
  }

  // Update order status in Firestore
  Future<void> updateOrderStatus(
    String userId,
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      await db!
          .collection('artifacts')
          .doc(appId)
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus.toString().split('.').last});
    } catch (e) {
      print('Error updating order status: $e');
    }
  }
}

// --- Main Application ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase using DefaultFirebaseOptions
    FirebaseApp app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    db = FirebaseFirestore.instanceFor(app: app);
    auth = fb_auth.FirebaseAuth.instanceFor(app: app);

    // --- MODIFICATION START ---
    try {
      // This part attempts to sign in automatically based on the Canvas environment.
      // It's wrapped in a try-catch to prevent "admin-restricted-operation" errors
      // from blocking the app's startup if the auto-login fails due to permissions.
      const String initialAuthToken = String.fromEnvironment(
        'INITIAL_AUTH_TOKEN',
        defaultValue: '',
      );
      if (initialAuthToken.isNotEmpty) {
        await auth!.signInWithCustomToken(initialAuthToken);
        print('Signed in with custom token.');
      } else {
        await auth!.signInAnonymously();
        print('Signed in anonymously.');
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'admin-restricted-operation') {
        print(
          'Initial sign-in restricted: ${e.message}. Proceeding without auto-login.',
        );
        // If this specific error occurs, we don't block the app.
        // The user will be directed to the LoginPage to sign in manually.
      } else {
        print(
          'Error during initial Firebase sign-in: ${e.code} - ${e.message}',
        );
        // For other FirebaseAuthExceptions, you might want to log them or show a critical error.
      }
    } catch (e) {
      print('Unexpected error during initial Firebase sign-in: $e');
      // Catch any other unexpected errors during the initial sign-in process.
    }
    // --- MODIFICATION END ---

    // Listen for auth state changes to set currentUser
    auth!.authStateChanges().listen((fb_auth.User? fbUser) async {
      if (fbUser != null) {
        final userDoc =
            await db!
                .collection('artifacts')
                .doc(appId)
                .collection('users')
                .doc(fbUser.uid)
                .get();
        if (userDoc.exists) {
          currentUser = User.fromFirestore(userDoc);
          print(
            'Current user set: ${currentUser!.username}, Role: ${currentUser!.role}',
          );
        } else {
          // If user document doesn't exist, create a basic one.
          // This handles cases where a user logs in via Firebase Auth but has no profile yet.
          currentUser = User(
            id: fbUser.uid,
            username: fbUser.email ?? 'anonymous_user',
            role: UserRole.user, // Default to user role for new profiles
            email: fbUser.email ?? '',
          );
          await db!
              .collection('artifacts')
              .doc(appId)
              .collection('users')
              .doc(currentUser!.id)
              .set(currentUser!.toFirestore());
          print(
            'Created new user profile in Firestore for: ${currentUser!.username}',
          );
        }
      } else {
        currentUser = null;
        print('User logged out or no user signed in.');
      }
    });
  } catch (e) {
    print('Critical Error initializing Firebase app: $e');
    // Handle Firebase initialization error, e.g., show an error screen
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green, // Green app bar as in images
          foregroundColor: Colors.white, // White text/icons on app bar
        ),
      ),
      home: StreamBuilder<fb_auth.User?>(
        stream: auth!.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final fb_auth.User? fbUser = snapshot.data;

          if (fbUser == null) {
            // No user logged in, show login page
            return LoginPage();
          } else {
            // User logged in, fetch their role from Firestore
            return FutureBuilder<User?>(
              future: AuthService().getUserDetails(
                fbUser.uid,
              ), // Fetch user details including role
              builder: (context, userDetailsSnapshot) {
                if (userDetailsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (userDetailsSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading user profile: ${userDetailsSnapshot.error}',
                    ),
                  );
                }
                final User? appUser = userDetailsSnapshot.data;

                if (appUser == null) {
                  // User exists in Firebase Auth but not in Firestore, or profile not found
                  // This could happen if a user registers but their Firestore doc isn't created yet,
                  // or if there's a data inconsistency.
                  // For now, redirect to login, or you could create a default profile here.
                  return LoginPage();
                } else {
                  // Set the global currentUser here once it's fully loaded with role
                  currentUser = appUser;
                  if (appUser.role == UserRole.admin) {
                    return AdminApp();
                  } else {
                    return UserApp();
                  }
                }
              },
            );
          }
        },
      ),
    );
  }
}

// --- Login Page ---

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;
  bool _isLoading = false; // New state for loading indicator
  // Removed _selectedRole as it's no longer needed

  void _login() async {
    print('Login button pressed!'); // Added for debugging
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessageBox(
        context,
        'Error',
        'Please enter both email and password.',
      );
      return;
    }

    setState(() {
      _errorMessage = null; // Clear previous errors
      _isLoading = true; // Show loading indicator
    });

    try {
      final User? authenticatedUser = await _authService.login(email, password);

      if (mounted) {
        // Check if the widget is still mounted
        if (authenticatedUser != null) {
          // Login successful. MyApp's StreamBuilder will handle navigation.
          // No explicit navigation needed here.
        } else {
          // This 'else' might be hit if getUserDetails returns null after successful Firebase Auth,
          // which implies a missing Firestore profile.
          _showMessageBox(
            context,
            'Login Failed',
            'User profile not found. Please try registering or contact support.',
          );
        }
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided for that user.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        } else if (e.code == 'invalid-credential') {
          message =
              'Invalid login credentials. Please check email and password.';
        } else {
          message = 'Login failed: ${e.message}';
        }
        _showMessageBox(context, 'Login Error', message);
      }
    } catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
        _showMessageBox(
          context,
          'Login Error',
          'An unexpected error occurred: $e',
        );
      }
    } finally {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  void _register() async {
    print('Register button pressed!'); // Added for debugging
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessageBox(
        context,
        'Error',
        'Please enter email and password for registration.',
      );
      return;
    }

    setState(() {
      _errorMessage = null; // Clear previous errors
      _isLoading = true; // Show loading indicator
    });

    try {
      final User? newUser = await _authService.register(
        email,
        password,
        email, // Use email as default name for new registration
        '', // Phone can be empty initially
        UserRole.user, // All new registrations are regular users
      );

      if (mounted) {
        // Check if the widget is still mounted
        if (newUser != null) {
          _showMessageBox(
            context,
            'Success',
            'Registration successful! You can now log in.',
          );
          _emailController.clear();
          _passwordController.clear();
        } else {
          // This 'else' might be hit if Firebase Auth succeeds but Firestore profile creation fails.
          _showMessageBox(
            context,
            'Registration Failed',
            'Failed to create user profile. Please try again.',
          );
        }
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
        String message;
        if (e.code == 'email-already-in-use') {
          message = 'The email address is already in use by another account.';
        } else if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        } else {
          message = 'Registration failed: ${e.message}';
        }
        _showMessageBox(context, 'Registration Error', message);
      }
    } catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
        _showMessageBox(
          context,
          'Registration Error',
          'An unexpected error occurred: $e',
        );
      }
    } finally {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Grocery App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Username)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator() // Show loading indicator
                  : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Login', style: TextStyle(fontSize: 18)),
                  ),
              SizedBox(height: 20),
              // Removed the "Register as: User / Admin" radio buttons
              TextButton(
                onPressed: _register,
                child: Text('Register New Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- User Application ---

class UserApp extends StatefulWidget {
  @override
  _UserAppState createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  int _selectedIndex = 0;
  final ProductService _productService = ProductService();
  List<CartItem> _cartItems = [];
  List<Product> _favoriteProducts =
      []; // Favorites still in-memory for simplicity

  // Pages for the User App
  // MODIFICATION START: Convert _userPages to a getter
  List<Widget> get _userPages => <Widget>[
    // UserHomePage will now listen to product changes from Firestore
    StreamBuilder<List<Product>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading products: ${snapshot.error}'),
          );
        }
        final products = snapshot.data ?? [];
        return UserHomePage(
          products: products,
          onAddToCart: _addToCart,
          onToggleFavorite: _toggleFavorite,
          favoriteProducts: _favoriteProducts,
        );
      },
    ),
    CartPage(
      cartItems: _cartItems, // This will now always pass the latest _cartItems
      onQuantityChanged: _updateCartItemQuantity,
      onRemoveFromCart: _removeFromCart,
      onCheckout: _checkout,
    ),
    FavoriteProductsPage(
      favoriteProducts: _favoriteProducts,
      onAddToCart: _addToCart,
      onRemoveFromFavorites: _toggleFavorite,
    ),
    OrderHistoryPage(
      userId: currentUser!.id,
    ), // OrderHistoryPage will use StreamBuilder internally
    ProfilePage(
      user: currentUser!,
      onLogout: _logout,
      onUpdateUser: _updateCurrentUserDetails,
    ),
  ];
  // MODIFICATION END

  @override
  void initState() {
    super.initState();
    // No need to initialize _userPages here anymore, as it's a getter
  }

  /// Adds a product to the cart.
  /// This method ensures immutability by creating a new list and new CartItem objects.
  void _addToCart(Product product) {
    setState(() {
      // Create a mutable copy of the current cart items list.
      final List<CartItem> updatedCart = List.from(_cartItems);
      int index = updatedCart.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (index != -1) {
        // If the product is already in the cart, create a new CartItem with updated quantity
        // and replace the old one in the new list.
        updatedCart[index] = updatedCart[index].copyWith(
          quantity: updatedCart[index].quantity + 1.0,
        );
      } else {
        // If the product is new, create a new CartItem and add it to the new list.
        updatedCart.add(CartItem(product: product, quantity: 1.0));
      }
      // Assign the newly created list back to _cartItems to trigger a UI rebuild.
      _cartItems = updatedCart;
      print(
        'Cart after add: ${_cartItems.map((e) => '${e.product.name}:${e.quantity}').join(', ')}',
      ); // Debug print
      _showMessageBox(context, 'Success', '${product.name} added to cart!');
    });
  }

  /// Updates the quantity of a specific item in the cart.
  /// This method ensures immutability by creating a new list and new CartItem objects.
  void _updateCartItemQuantity(CartItem item, double newQuantity) {
    setState(() {
      // Create a new list by mapping over the existing cart items.
      // For the item being updated, use copyWith to create a new CartItem instance.
      _cartItems =
          _cartItems
              .map((cartItem) {
                if (cartItem.product.id == item.product.id) {
                  return cartItem.copyWith(quantity: newQuantity);
                }
                return cartItem;
              })
              .where((cartItem) => cartItem.quantity > 0)
              .toList(); // Filter out items with 0 or less quantity and convert to a new list
      print(
        'Cart after quantity update: ${_cartItems.map((e) => '${e.product.name}:${e.quantity}').join(', ')}',
      ); // Debug print
    });
  }

  /// Removes a specific item from the cart.
  /// This method ensures immutability by creating a new list.
  void _removeFromCart(CartItem item) {
    setState(() {
      // Create a new list by filtering out the item to be removed.
      _cartItems =
          _cartItems
              .where((cartItem) => cartItem.product.id != item.product.id)
              .toList();
      print(
        'Cart after remove: ${_cartItems.map((e) => '${e.product.name}:${e.quantity}').join(', ')}',
      ); // Debug print
      _showMessageBox(
        context,
        'Removed',
        '${item.product.name} removed from cart.',
      );
    });
  }

  void _toggleFavorite(Product product) {
    setState(() {
      if (_favoriteProducts.contains(product)) {
        _favoriteProducts.remove(product);
        _showMessageBox(
          context,
          'Removed',
          '${product.name} removed from favorites.',
        );
      } else {
        _favoriteProducts.add(product);
        _showMessageBox(
          context,
          'Added',
          '${product.name} added to favorites!',
        );
      }
    });
  }

  void _checkout() {
    if (_cartItems.isEmpty) {
      _showMessageBox(
        context,
        'Cart Empty',
        'Please add items to your cart before checking out.',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OrderConfirmationPage(
              cartItems: _cartItems,
              onConfirmOrder: _placeOrder,
            ),
      ),
    );
  }

  void _placeOrder(
    List<CartItem> items,
    PaymentMethodType paymentMethod,
    String? cardDetails,
  ) async {
    final double totalAmount = items.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final Order newOrder = Order(
      id: db!.collection('temp').doc().id, // Firestore will assign a unique ID
      userId: currentUser!.id,
      items: List.from(items), // Create a copy to avoid reference issues
      totalAmount: totalAmount,
      orderDate: DateTime.now(),
      paymentMethod: paymentMethod,
      cardDetails: cardDetails,
    );

    await OrderService().placeOrder(newOrder); // Use await for Firebase call
    setState(() {
      _cartItems.clear(); // Clear cart after order
    });
    // Pop back to the main user app page, then navigate to Order History
    Navigator.popUntil(context, (route) => route.isFirst);
    _onItemTapped(3); // Navigate to Order History
    _showMessageBox(
      context,
      'Order Placed!',
      'Your order has been placed successfully. You can view its status in Order History.',
    );
  }

  void _logout() async {
    await AuthService().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false, // Remove all routes from stack
    );
  }

  void _updateCurrentUserDetails(User updatedUser) async {
    setState(() {
      currentUser = updatedUser; // Update global current user
    });
    await AuthService().updateUserDetails(updatedUser); // Update in Firestore
    _showMessageBox(
      context,
      'Profile Updated',
      'Your profile details have been updated.',
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      // This should ideally not happen if MyApp's StreamBuilder works correctly,
      // but as a fallback or during initial loading.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _showMessageBox(
                context,
                'Search',
                'Search functionality not implemented.',
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              _showMessageBox(
                context,
                'Notifications',
                'No new notifications.',
              );
            },
          ),
        ],
      ),
      body: _userPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
      ),
    );
  }
}

// --- User App Pages ---

class UserHomePage extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onAddToCart;
  final Function(Product) onToggleFavorite;
  final List<Product> favoriteProducts;

  UserHomePage({
    required this.products,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.favoriteProducts,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out some "top deals" for demonstration
    final List<Product> topDeals =
        products.where((p) => p.price < 5.0).take(4).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for groceries...',
                  prefixIcon: Icon(Icons.search, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 15,
                  ),
                ),
                onTap: () {
                  _showMessageBox(
                    context,
                    'Search',
                    'Search functionality is under development.',
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Text(
              'All Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Categories section (simplified)
            Container(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryItem(Icons.home, 'HouseHold'),
                  _buildCategoryItem(Icons.local_grocery_store, 'Grocery'),
                  _buildCategoryItem(Icons.liquor, 'Liquor'),
                  _buildCategoryItem(Icons.fastfood, 'Chilled'),
                  _buildCategoryItem(Icons.local_drink, 'Beverages'),
                  _buildCategoryItem(Icons.bakery_dining, 'Bakery'),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (topDeals.isNotEmpty) ...[
              Text(
                'Top Deals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                height: 250, // Adjust height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: topDeals.length,
                  itemBuilder: (context, index) {
                    final product = topDeals[index];
                    final isFavorite = favoriteProducts.contains(product);
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: _buildProductCard(
                        product,
                        onAddToCart,
                        onToggleFavorite,
                        isFavorite,
                        isCompact: true,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
            Text(
              'All Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            products.isEmpty
                ? Center(child: Text('No products available.'))
                : GridView.builder(
                  shrinkWrap: true,
                  physics:
                      NeverScrollableScrollPhysics(), // Disable scrolling for inner grid
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    // MODIFICATION: Adjusted childAspectRatio to make cards narrower
                    childAspectRatio: 0.44, // Changed from 0.46 to 0.44
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isFavorite = favoriteProducts.contains(product);
                    return _buildProductCard(
                      product,
                      onAddToCart,
                      onToggleFavorite,
                      isFavorite,
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.green.shade100,
            child: Icon(icon, color: Colors.green, size: 30),
          ),
          SizedBox(height: 5),
          Text(title, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    Function(Product) onAddToCart,
    Function(Product) onToggleFavorite,
    bool isFavorite, {
    bool isCompact = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: isCompact ? 160 : null, // Fixed width for compact cards
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  // MODIFICATION: Added a fixed height to the image to prevent overflow
                  height: 120.0, // Explicitly set height
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${product.unit}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: isCompact ? 10 : 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$ ${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 14 : 16,
                          color: Colors.green,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: isCompact ? 20 : 24,
                            ),
                            onPressed: () => onToggleFavorite(product),
                            visualDensity: VisualDensity.compact,
                          ),
                          InkWell(
                            onTap: () => onAddToCart(product),
                            child: Container(
                              padding: EdgeInsets.all(isCompact ? 4 : 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: isCompact ? 16 : 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---  Cart Page ---
class CartPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(CartItem, double) onQuantityChanged;
  final Function(CartItem) onRemoveFromCart;
  final VoidCallback onCheckout;

  CartPage({
    required this.cartItems,
    required this.onQuantityChanged,
    required this.onRemoveFromCart,
    required this.onCheckout,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    double subtotal = widget.cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    return Column(
      children: [
        Expanded(
          child:
              widget.cartItems.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Your cart is empty!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Add some delicious groceries to get started.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate back to the home page
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              // If cart is the first page, navigate to home (index 0)
                              // This assumes UserApp has a way to change selected index
                              // For this example, we'll just pop if possible.
                            }
                          },
                          icon: Icon(Icons.storefront),
                          label: Text('Start Shopping'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return _buildCartItemCard(
                        context,
                        item,
                        widget.onQuantityChanged,
                        widget.onRemoveFromCart,
                      );
                    },
                  ),
        ),
        if (widget.cartItems.isNotEmpty)
          _buildCartSummary(context, subtotal, widget.onCheckout),
      ],
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItem item,
    Function(CartItem, double) onQuantityChanged,
    Function(CartItem) onRemoveFromCart,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6, // Increased elevation for a more prominent look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ), // More rounded corners
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding from 16 to 12
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10), // Rounded image corners
              child: Image.network(
                item.product.imageUrl,
                // MODIFICATION: Reduced image size in CartPage
                width: 40, // Changed from 45 to 40
                height: 40, // Changed from 45 to 40
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 40, // Changed from 45 to 40
                      height: 40, // Changed from 45 to 40
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.grey.shade500,
                      ), // Reduced icon size
                    ),
              ),
            ),
            SizedBox(width: 6), // Changed from 8 to 6
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade800,
                    ), // Reduced font size from 18 to 16
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$ ${item.product.price.toStringAsFixed(2)} / ${item.product.unit}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ), // Reduced font size from 14 to 13
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Pill shape for quantity control
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.remove,
                                color: Colors.green.shade700,
                                size: 20,
                              ), // Reduced icon size
                              onPressed: () {
                                double newQty = item.quantity - 0.5;
                                // Round to one decimal place to prevent floating point inaccuracies
                                newQty = double.parse(
                                  newQty.toStringAsFixed(1),
                                );
                                if (newQty < 0.1) {
                                  // Check against a small threshold for removal
                                  _showConfirmationBox(
                                    context,
                                    'Remove Item',
                                    'Are you sure you want to remove ${item.product.name} from your cart?',
                                    () => onRemoveFromCart(item),
                                  );
                                } else {
                                  onQuantityChanged(item, newQty);
                                }
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            // Display quantity with its unit for clarity
                            Text(
                              '${item.quantity.toStringAsFixed(1)} ${item.product.unit}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ), // Reduced font size from 16 to 14
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add,
                                color: Colors.green.shade700,
                                size: 20,
                              ), // Reduced icon size
                              onPressed: () {
                                double newQty = item.quantity + 0.5;
                                // Round to one decimal place
                                newQty = double.parse(
                                  newQty.toStringAsFixed(1),
                                );
                                onQuantityChanged(item, newQty);
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$ ${item.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green.shade900,
                        ), // Reduced font size from 18 to 16
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 3),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade600,
                size: 24,
              ), // Reduced icon size from 28 to 24
              onPressed: () {
                _showConfirmationBox(
                  context,
                  'Remove Item',
                  'Are you sure you want to remove ${item.product.name} from your cart?',
                  () => onRemoveFromCart(item),
                );
              },
              tooltip: 'Remove from Cart',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(
    BuildContext context,
    double subtotal,
    VoidCallback onCheckout,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0), // Reduced padding from 16 to 12
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ), // Reduced font size from 18 to 16
              Text(
                '\$ ${subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ), // Reduced font size from 20 to 18
            ],
          ),
          SizedBox(height: 8), // Reduced height from 10 to 8
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ), // Reduced font size from 16 to 14
              Text(
                '\$ 5.00',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ), // Reduced font size from 16 to 14
            ],
          ),
          Divider(height: 16, thickness: 1), // Reduced height from 20 to 16
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ), // Reduced font size from 22 to 20
              Text(
                '\$ ${(subtotal + 5.00).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ), // Reduced font size from 24 to 22
            ],
          ),
          SizedBox(height: 16), // Reduced height from 20 to 16
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              minimumSize: Size(
                double.infinity,
                50,
              ), // Reduced height from 55 to 50
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: Text(
              'Proceed to Checkout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ), // Reduced font size from 20 to 18
          ),
        ],
      ),
    );
  }
}

class OrderConfirmationPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(List<CartItem>, PaymentMethodType, String?) onConfirmOrder;

  OrderConfirmationPage({
    required this.cartItems,
    required this.onConfirmOrder,
  });

  @override
  _OrderConfirmationPageState createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.cash;
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  double get _totalAmount =>
      widget.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  void _confirmOrder() {
    String? cardDetails;
    if (_selectedPaymentMethod == PaymentMethodType.card) {
      if (_cardNumberController.text.isEmpty ||
          _expiryDateController.text.isEmpty ||
          _cvvController.text.isEmpty) {
        _showMessageBox(context, 'Error', 'Please fill in all card details.');
        return;
      }
      cardDetails =
          'Card: **** **** **** ${_cardNumberController.text.substring(_cardNumberController.text.length - 4)}, Exp: ${_expiryDateController.text}';
    }
    widget.onConfirmOrder(
      widget.cartItems,
      _selectedPaymentMethod,
      cardDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirm Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} x ${item.quantity.toStringAsFixed(1)}',
                        ),
                      ), // Display quantity with one decimal
                      Text('\$ ${item.totalPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                );
              },
            ),
            Divider(height: 30, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$ ${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Text(
              'Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            RadioListTile<PaymentMethodType>(
              title: Text('Cash Payment'),
              value: PaymentMethodType.cash,
              groupValue: _selectedPaymentMethod,
              onChanged: (PaymentMethodType? value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            RadioListTile<PaymentMethodType>(
              title: Text('Card Payment'),
              value: PaymentMethodType.card,
              groupValue: _selectedPaymentMethod,
              onChanged: (PaymentMethodType? value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            if (_selectedPaymentMethod == PaymentMethodType.card) ...[
              SizedBox(height: 20),
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryDateController,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date (MM/YY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Confirm Order', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteProductsPage extends StatelessWidget {
  final List<Product> favoriteProducts;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromFavorites;

  FavoriteProductsPage({
    required this.favoriteProducts,
    required this.onAddToCart,
    required this.onRemoveFromFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return favoriteProducts.isEmpty
        ? Center(child: Text('You have no favorite products yet.'))
        : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: favoriteProducts.length,
          itemBuilder: (context, index) {
            final product = favoriteProducts[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Image.network(
                      product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported, size: 50),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '\$ ${product.price.toStringAsFixed(2)} / ${product.unit}',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.shopping_cart, color: Colors.green),
                      onPressed: () => onAddToCart(product),
                      tooltip: 'Add to Cart',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onRemoveFromFavorites(product),
                      tooltip: 'Remove from Favorites',
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}

class OrderHistoryPage extends StatefulWidget {
  final String userId;

  OrderHistoryPage({required this.userId});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  List<Order> _userOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Listen to order changes from Firestore
    _orderService.getUserOrders(widget.userId).listen((orders) {
      if (mounted) {
        setState(() {
          _userOrders = orders;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Order> _getOrdersByStatus(OrderStatus status) {
    return _userOrders.where((order) => order.status == status).toList();
  }

  // --- ADDED _buildOrderList METHOD ---
  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(child: Text('No orders in this category.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () => _showOrderDetails(context, order),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Date: ${order.orderDate.day} ${getMonthName(order.orderDate.month)} ${order.orderDate.year}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    'Total: \$ ${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Status: ${order.status.toString().split('.').last.toUpperCase()}',
                  ),
                  Text(
                    'Items: ${order.items.map((e) => '${e.product.name} x ${e.quantity.toStringAsFixed(1)}').join(', ')}',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // --- END _buildOrderList METHOD ---

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: [
            Tab(text: 'COMPLETED'),
            Tab(text: 'PENDING'),
            Tab(text: 'CANCELED'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(_getOrdersByStatus(OrderStatus.completed)),
              _buildOrderList(_getOrdersByStatus(OrderStatus.pending)),
              _buildOrderList(_getOrdersByStatus(OrderStatus.cancelled)),
            ],
          ),
        ),
      ],
    );
  }

  String getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Details (ID: ${order.id})'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Status: ${order.status.toString().split('.').last.toUpperCase()}',
                ),
                Text(
                  'Payment: ${order.paymentMethod.toString().split('.').last.toUpperCase()}',
                ),
                if (order.cardDetails != null)
                  Text('Card: ${order.cardDetails}'),
                SizedBox(height: 10),
                Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items
                    .map(
                      (item) => Text(
                        '${item.product.name} x ${item.quantity.toStringAsFixed(1)} (\$${item.totalPrice.toStringAsFixed(2)})',
                      ),
                    )
                    .toList(),
                SizedBox(height: 10),
                Text(
                  'Total: \$ ${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class ProfilePage extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;
  final Function(User) onUpdateUser;

  ProfilePage({
    required this.user,
    required this.onLogout,
    required this.onUpdateUser,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User _displayUser; // Local copy for display

  @override
  void initState() {
    super.initState();
    _displayUser = widget.user;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.id != oldWidget.user.id ||
        widget.user.name != oldWidget.user.name ||
        widget.user.email != oldWidget.user.email ||
        widget.user.phone != oldWidget.user.phone ||
        widget.user.deliveryAddress?.fullAddress !=
            oldWidget.user.deliveryAddress?.fullAddress ||
        widget.user.recipientDetails?.name !=
            oldWidget.user.recipientDetails?.name) {
      setState(() {
        _displayUser = widget.user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://placehold.co/100x100/grey/white?text=User',
              ), // Placeholder for user image
              onBackgroundImageError: (Object error, StackTrace? stackTrace) {
                // Fallback if image fails to load
                print('Error loading image: $error');
              },
            ),
            SizedBox(height: 10),
            Text(
              _displayUser.name.isNotEmpty ? _displayUser.name : 'User Name',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              _displayUser.email.isNotEmpty
                  ? _displayUser.email
                  : 'user@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              _displayUser.phone.isNotEmpty ? _displayUser.phone : 'N/A',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            // Removed Dark Mode button as requested
            _buildProfileOption(
              context,
              Icons.person_outline,
              'Recipient Details',
              () async {
                final updatedDetails = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RecipientDetailsPage(
                          recipientDetails:
                              _displayUser.recipientDetails ??
                              RecipientDetails(),
                        ),
                  ),
                );
                if (updatedDetails != null &&
                    updatedDetails is RecipientDetails) {
                  setState(() {
                    _displayUser.recipientDetails = updatedDetails;
                    widget.onUpdateUser(
                      _displayUser,
                    ); // Update the parent's user object
                  });
                }
              },
            ),
            _buildProfileOption(
              context,
              Icons.location_on_outlined,
              'Delivery Address',
              () async {
                final updatedAddress = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DeliveryAddressPage(
                          address: _displayUser.deliveryAddress ?? Address(),
                        ),
                  ),
                );
                if (updatedAddress != null && updatedAddress is Address) {
                  setState(() {
                    _displayUser.deliveryAddress = updatedAddress;
                    widget.onUpdateUser(
                      _displayUser,
                    ); // Update the parent's user object
                  });
                }
              },
            ),
            _buildProfileOption(
              context,
              Icons.payment_outlined,
              'Payment Methods',
              () {
                _showMessageBox(
                  context,
                  'Payment Methods',
                  'Payment method management not implemented in detail.',
                );
              },
            ),
            _buildProfileOption(
              context,
              Icons.lock_outline,
              'Change Password',
              () {
                _showMessageBox(
                  context,
                  'Change Password',
                  'Change password functionality not implemented.',
                );
              },
            ),
            Divider(),
            _buildProfileOption(
              context,
              Icons.logout,
              'Logout',
              widget.onLogout,
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onPressed, {
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, color: isLogout ? Colors.red : Colors.green, size: 28),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: isLogout ? Colors.red : Colors.black,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class DeliveryAddressPage extends StatefulWidget {
  final Address address;

  DeliveryAddressPage({required this.address});

  @override
  _DeliveryAddressPageState createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(text: widget.address.street);
    _cityController = TextEditingController(text: widget.address.city);
    _postalCodeController = TextEditingController(
      text: widget.address.postalCode,
    );
    _countryController = TextEditingController(text: widget.address.country);
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    final updatedAddress = Address(
      street: _streetController.text,
      city: _cityController.text,
      postalCode: _postalCodeController.text,
      country: _countryController.text,
    );
    Navigator.pop(context, updatedAddress); // Return updated address
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delivery Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _streetController,
              decoration: InputDecoration(
                labelText: 'Street Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _postalCodeController,
              decoration: InputDecoration(
                labelText: 'Postal Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Update Address', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipientDetailsPage extends StatefulWidget {
  final RecipientDetails recipientDetails;

  RecipientDetailsPage({required this.recipientDetails});

  @override
  _RecipientDetailsPageState createState() => _RecipientDetailsPageState();
}

class _RecipientDetailsPageState extends State<RecipientDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipientDetails.name);
    _phoneController = TextEditingController(
      text: widget.recipientDetails.phone,
    );
    _emailController = TextEditingController(
      text: widget.recipientDetails.email,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveRecipientDetails() {
    final updatedDetails = RecipientDetails(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
    );
    Navigator.pop(context, updatedDetails); // Return updated details
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recipient Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Recipient Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Recipient Phone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Recipient Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveRecipientDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Update Details', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Admin App Pages (Moved up for proper referencing) ---

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _imageUrlController =
      TextEditingController(); // For placeholder image

  final ProductService _productService = ProductService();

  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: '', // Firestore will assign ID
        name: _nameController.text,
        price: double.parse(_priceController.text),
        unit: _unitController.text,
        imageUrl:
            _imageUrlController.text.isNotEmpty
                ? _imageUrlController.text
                : 'https://placehold.co/100x100/grey/white?text=Product',
      );
      await _productService.addProduct(newProduct);
      _showMessageBox(
        context,
        'Success',
        '${newProduct.name} added successfully!',
      );
      _nameController.clear();
      _priceController.clear();
      _unitController.clear();
      _imageUrlController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Product',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _unitController,
              decoration: InputDecoration(
                labelText: 'Unit (e.g., 1KG, 100G)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter unit';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image URL (Optional, uses placeholder if empty)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Add Product', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageProductsPage extends StatefulWidget {
  @override
  _ManageProductsPageState createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading products: ${snapshot.error}'),
          );
        }
        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(child: Text('No products to manage. Add some first!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Image.network(
                      product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported, size: 50),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '\$ ${product.price.toStringAsFixed(2)} / ${product.unit}',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editProduct(context, product),
                      tooltip: 'Edit Product',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(context, product.id),
                      tooltip: 'Delete Product',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editProduct(BuildContext context, Product product) async {
    final updatedProduct = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: product),
      ),
    );
    if (updatedProduct != null && updatedProduct is Product) {
      await _productService.updateProduct(updatedProduct);
      _showMessageBox(context, 'Success', '${updatedProduct.name} updated.');
    }
  }

  void _deleteProduct(BuildContext context, String productId) {
    _showConfirmationBox(
      context,
      'Delete Product',
      'Are you sure you want to delete this product?',
      () async {
        await _productService.deleteProduct(productId);
        _showMessageBox(context, 'Deleted', 'Product deleted successfully.');
      },
    );
  }
}

class EditProductPage extends StatefulWidget {
  final Product product;

  EditProductPage({required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _unitController = TextEditingController(text: widget.product.unit);
    _imageUrlController = TextEditingController(text: widget.product.imageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _updateProduct() {
    if (_formKey.currentState!.validate()) {
      final updatedProduct = Product(
        id: widget.product.id,
        name: _nameController.text,
        price: double.parse(_priceController.text),
        unit: _unitController.text,
        imageUrl: _imageUrlController.text,
      );
      Navigator.pop(context, updatedProduct); // Return updated product
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editing: ${widget.product.name}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: 'Unit (e.g., 1KG, 100G)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Update Product', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Explicitly define type for QuerySnapshot
      stream:
          db!
              .collection('artifacts')
              .doc(appId)
              .collection('users')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading users: ${snapshot.error}'));
        }
        final users =
            snapshot.data?.docs
                .map((doc) => User.fromFirestore(doc))
                .toList() ??
            [];

        if (users.isEmpty) {
          return Center(child: Text('No registered users.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ID: ${user.id}',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      'Username: ${user.username}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text('Name: ${user.name.isNotEmpty ? user.name : 'N/A'}'),
                    Text(
                      'Email: ${user.email.isNotEmpty ? user.email : 'N/A'}',
                    ),
                    Text(
                      'Phone: ${user.phone.isNotEmpty ? user.phone : 'N/A'}',
                    ),
                    SizedBox(height: 10),
                    if (user.deliveryAddress != null)
                      Text(
                        'Address: ${user.deliveryAddress!.fullAddress}',
                        style: TextStyle(fontSize: 14),
                      ),
                    if (user.recipientDetails != null)
                      Text(
                        'Recipient: ${user.recipientDetails!.name} (${user.recipientDetails!.phone})',
                        style: TextStyle(fontSize: 14),
                      ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          _showMessageBox(
                            context,
                            'User Actions',
                            'Further user actions (e.g., block user) not implemented.',
                          );
                        },
                        child: Text(
                          'View Details',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class OrderManagementPage extends StatefulWidget {
  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService =
      AuthService(); // To fetch user details for orders

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _orderService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading orders: ${snapshot.error}'));
        }
        final allOrders = snapshot.data ?? [];

        if (allOrders.isEmpty) {
          return Center(child: Text('No orders placed yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: allOrders.length,
          itemBuilder: (context, index) {
            final order = allOrders[index];
            return FutureBuilder<User?>(
              future: _authService.getUserDetails(order.userId),
              builder: (context, userSnapshot) {
                final user = userSnapshot.data;
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${order.id}',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          'User: ${user?.name.isNotEmpty == true ? user!.name : user?.username ?? 'Unknown User'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Total Amount: \$ ${order.totalAmount.toStringAsFixed(2)}',
                        ),
                        Text(
                          'Items: ${order.items.map((e) => '${e.product.name} x ${e.quantity.toStringAsFixed(1)}').join(', ')}',
                        ), // Display quantity with one decimal
                        Text(
                          'Status: ${order.status.toString().split('.').last.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (order.status == OrderStatus.pending) ...[
                              ElevatedButton(
                                onPressed:
                                    () => _updateOrderStatus(
                                      order.userId,
                                      order.id,
                                      OrderStatus.approved,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: Text(
                                  'Approve',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed:
                                    () => _updateOrderStatus(
                                      order.userId,
                                      order.id,
                                      OrderStatus.declined,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(
                                  'Decline',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            if (order.status == OrderStatus.approved)
                              ElevatedButton(
                                onPressed:
                                    () => _updateOrderStatus(
                                      order.userId,
                                      order.id,
                                      OrderStatus.completed,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: Text(
                                  'Mark Completed',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.approved:
        return Colors.blue;
      case OrderStatus.declined:
        return Colors.red;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  void _updateOrderStatus(
    String userId,
    String orderId,
    OrderStatus newStatus,
  ) async {
    await _orderService.updateOrderStatus(userId, orderId, newStatus);
    _showMessageBox(
      context,
      'Order Status Updated',
      'Order ID: $orderId status changed to ${newStatus.toString().split('.').last}.',
    );
  }
}

// --- Admin Application ---

class AdminApp extends StatefulWidget {
  @override
  _AdminAppState createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  int _selectedIndex = 0;

  // Pages for the Admin App
  // Moved these definitions above AdminApp for proper referencing
  static List<Widget> _adminPages = <Widget>[
    AdminHomePage(),
    AddProductPage(),
    ManageProductsPage(),
    UserManagementPage(),
    OrderManagementPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await AuthService().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false, // Remove all routes from stack
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _adminPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Manage Products',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// --- Admin App Pages --- (Ensuring full definition)

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: ProductService().getProducts(),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final totalProducts = productSnapshot.data?.length ?? 0;

        return StreamBuilder<List<Order>>(
          stream: OrderService().getAllOrders(),
          builder: (context, orderSnapshot) {
            if (orderSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final allOrders = orderSnapshot.data ?? [];
            final pendingOrders =
                allOrders.where((o) => o.status == OrderStatus.pending).length;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // Explicitly define type for QuerySnapshot
              stream:
                  db!
                      .collection('artifacts')
                      .doc(appId)
                      .collection('users')
                      .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final totalUsers = userSnapshot.data?.docs.length ?? 0;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 100,
                        color: Colors.green,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Welcome, Admin!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('Use the navigation below to manage the app.'),
                      SizedBox(height: 30),
                      // Quick links/summary
                      Card(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              _buildAdminInfoRow(
                                Icons.shopping_bag,
                                'Total Products:',
                                '$totalProducts',
                              ),
                              _buildAdminInfoRow(
                                Icons.people,
                                'Total Users:',
                                '$totalUsers',
                              ),
                              _buildAdminInfoRow(
                                Icons.receipt,
                                'Pending Orders:',
                                '$pendingOrders',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAdminInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// --- Utility Function for Message Box (instead of alert) ---
void _showMessageBox(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// --- Utility Function for Confirmation Box (instead of confirm) ---
void _showConfirmationBox(
  BuildContext context,
  String title,
  String message,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      );
    },
  );
}
