import 'package:car_booking_app/add_payment_method_screen.dart';
import 'package:car_booking_app/booking_successful_screen.dart';
import 'package:car_booking_app/intercity_trip_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import for the loading indicator
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart'; // Import for custom fonts
import 'home_screen.dart'; // Or the correct path
import 'payment_methods_screen.dart';
import 'my_rides_screen.dart';
import 'intercity_destination_screen.dart'; // Import the new screen
import 'plan_intercity_trip_screen.dart'; // Import the new screen
import 'plan_trip_screen.dart'; // Or the correct relative path

// Firebase options (replace with your actual configuration)
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCI4WHMtwLv1GS_jjYa61Zgg3QPZVj5bP8",
  appId: "1:1009455757269:android:14026f095a520b5127ef5c",
  messagingSenderId: "1009455757269", //
  projectId: "car-booking-app-59594",
  authDomain: "YOUR_AUTH_DOMAIN", // REPLACE WITH YOURS
  databaseURL: "YOUR_DATABASE_URL", // REPLACE WITH YOURS
  storageBucket: "YOUR_STORAGE_BUCKET", // REPLACE WITH YOURS
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const CarBookingApp());
}

class CarBookingApp extends StatelessWidget {
  const CarBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juber',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          color: Colors.red,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.red,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            textStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.red),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.red.shade400.withOpacity(0.8)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.red.shade400.withOpacity(0.8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
      home: const AuthCheck(), // Use AuthCheck to determine the initial screen
      routes: {
        '/home': (context) => const HomeScreen(),
        '/my_rides': (context) => MyRidesScreen(),
        '/payment_methods': (context) => const PaymentMethodsScreen(),
        '/main': (context) => const MainPage(),
        '/plan_trip': (context) => PlanTripScreen(pickup: '', dropoff: ''),
        '/plan_intercity_trip':
            (context) =>
                PlanIntercityTripScreen(destination: 'PlanIntercityTripScreen'),
        '/intercity_destination': (context) => IntercityDestinationScreen(),
        '/booking_successful': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return BookingSuccessfulScreen(bookingDetails: args);
        },
        '/add_payment_method': (context) => const AddPaymentMethodScreen(),
        // ignore: equal_keys_in_map
        '/booking_successful': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return BookingSuccessfulScreen(bookingDetails: args);
        },
        '/intercity_trip_options': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, String>?;
          return IntercityTripOptionsScreen(
            destination: args?['destination'] ?? '',
            pickupDateTime: args?['pickupDateTime'] ?? '',
          );
        },
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(); // Show splash screen while checking auth
        }
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in
          return const HomeScreen();
        } else {
          // User is not logged in
          return const LoginPage();
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // No need for delayed navigation here, AuthCheck handles it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SpinKitSpinningCircle(color: Colors.white, size: 50.0),
            const SizedBox(height: 16),
            Text(
              'JUBER',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance; // Firebase Auth instance
  final _firestore = FirebaseFirestore.instance; // Firestore instance
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSignUp = false; // Track if it's login or sign up

  // Function to handle Login and Sign Up
  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = ''; // Clear any previous error
      });
      try {
        if (_isSignUp) {
          // --- Sign Up ---
          UserCredential userCredential = await _auth
              .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );
          // Store additional user data in Firestore
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': _emailController.text.trim(),
                // Add any other user data you want to store (e.g., name, phone)
              });
          // Navigate to home screen after successful signup
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          // --- Log In ---
          await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          // Navigate to home screen after successful login
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth errors
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
          _isLoading = false;
        });
      } catch (e) {
        // Handle other errors
        print('An unexpected error occurred: $e');
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
          _isLoading = false;
        });
      }
    }
  }

  // Function to get error message from Firebase Auth error code
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Sign Up' : 'Log In'), // Dynamic title
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                      ).hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed:
                        _isLoading ? null : _handleAuth, // Disable when loading
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                            : Text(_isSignUp ? 'Sign Up' : 'Log In'),
                  ),
                  const SizedBox(height: 12.0),
                  TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = ''; //clear error message
                              });
                            },
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Log In'
                          : 'Need an account? Sign Up',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for the main application page (you might not need this if HomeScreen is your main page)
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Juber'), centerTitle: true),
      body: const Center(
        child: Text('Main Page Content', style: TextStyle(fontSize: 20.0)),
      ),
    );
  }
}
