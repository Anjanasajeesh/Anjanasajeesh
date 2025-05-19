import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String? _selectedPaymentMethod;

  final List<Map<String, String>> _paymentOptions = [
    {
      'name': 'Cash payment',
      'details': 'Default method',
      'icon': 'assets/icons/cash.png',
    },
    {
      'name': '**** **** **** 5263',
      'details': 'Expires 09/25',
      'icon': 'assets/icons/mastercard.png',
    },
    {
      'name': '**** **** **** 3802',
      'details': 'Expires 10/27',
      'icon': 'assets/icons/visacard.png',
    },
    {
      'name': 'petra_stark@email.com',
      'details': '',
      'icon': 'assets/icons/paypalcard.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment methods',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_selectedPaymentMethod != null) {
                print('Selected payment method: $_selectedPaymentMethod');
                // Simulate booking process (replace with actual logic)
                final bookingDetails = {
                  'bookingId': 'BOOK12345',
                  'vehicleType': 'Sedan',
                  'pickupLocation': 'Kochi Main Bus Stand',
                  'pickupTime': '2025-05-19 16:00',
                  'dropoffLocation': 'Your Destination',
                  'totalFare': 1500,
                  'paymentMethod': _selectedPaymentMethod,
                };
                Navigator.pushNamed(
                  context,
                  '/booking_successful',
                  arguments: bookingDetails,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a payment method'),
                  ),
                );
              }
            },
            child: Text('Done', style: GoogleFonts.poppins(color: Colors.red)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'CURRENT METHOD',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paymentOptions.length,
              separatorBuilder:
                  (BuildContext context, int index) => const Divider(),
              itemBuilder: (BuildContext context, int index) {
                final option = _paymentOptions[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = option['name'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          _selectedPaymentMethod == option['name']
                              ? Colors.black12
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 16.0,
                          ),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Image.asset(
                              option['icon']!,
                            ), // Make sure assets exist
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                option['name']!,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (option['details']!.isNotEmpty)
                                Text(
                                  option['details']!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_selectedPaymentMethod == option['name'])
                          const Icon(Icons.check_circle, color: Colors.red),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedPaymentMethod == 'Cash payment') {
                    // Navigate directly to BookingSuccessfulScreen for cash payment
                    Navigator.pushReplacementNamed(
                      context,
                      '/booking_successful',
                      arguments: {
                        'paymentMethod': 'Cash on Arrival',
                        // You can pass other relevant booking details here
                      },
                    );
                  } else {
                    // Navigate to the AddPaymentMethodScreen for other payment methods
                    Navigator.pushNamed(context, '/add_payment_method');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'ADD PAYMENT METHOD',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
