import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_model.dart';
import 'booking_history_service.dart';

class PaymentPage extends StatefulWidget {
  final String stationName;
  final String connectorType;
  final String slotType;
  final int totalPrice;
  final String placeId;
  final double latitude;
  final double longitude;
  final String vehicle;
  final DateTime startTime;
  final int duration;

  const PaymentPage({
    super.key,
    required this.stationName,
    required this.connectorType,
    required this.slotType,
    required this.totalPrice,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.vehicle,
    required this.startTime,
    required this.duration,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'UPI';
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isProcessingPayment = false;

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF103050),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Station', widget.stationName),
                    _buildSummaryRow('Connector', widget.connectorType),
                    _buildSummaryRow('Slot Type', widget.slotType),
                    _buildSummaryRow('Vehicle', widget.vehicle),
                    _buildSummaryRow('Date', _formatDate(widget.startTime)),
                    _buildSummaryRow('Time', _formatTime(widget.startTime)),
                    _buildSummaryRow('Duration', '${widget.duration} hour(s)'),
                    const Divider(),
                    _buildSummaryRow(
                      'Total Amount',
                      '₹${widget.totalPrice}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodTile('UPI', 'assets/upi.png'),
            _buildPaymentMethodTile('Credit/Debit Card', 'assets/card.png'),
            _buildPaymentMethodTile('Net Banking', 'assets/netbanking.png'),
            const SizedBox(height: 16),

            // Payment Form
            if (_selectedPaymentMethod == 'UPI') _buildUPIForm(),
            if (_selectedPaymentMethod == 'Credit/Debit Card') _buildCardForm(),
            if (_selectedPaymentMethod == 'Net Banking') _buildNetBankingForm(),

            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessingPayment ? null : _openDirections,
                    child: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF103050),
                    ),
                    onPressed: _isProcessingPayment ? null : _confirmPayment,
                    child: _isProcessingPayment
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String method, String iconPath) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Image.asset(
          iconPath,
          width: 40,
          height: 40,
        ),
        title: Text(method),
        trailing: Radio<String>(
          value: method,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildUPIForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter UPI ID',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _upiIdController,
          decoration: const InputDecoration(
            hintText: 'example@upi',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter UPI ID';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Popular UPI Apps',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUPIAppIcon('assets/gpay.png', 'Google Pay'),
            _buildUPIAppIcon('assets/phonepe.png', 'PhonePe'),
            _buildUPIAppIcon('assets/paytm.png', 'Paytm'),
          ],
        ),
      ],
    );
  }

  Widget _buildUPIAppIcon(String imagePath, String label) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          width: 50,
          height: 50,
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            hintText: 'Card Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  hintText: 'CVV',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Cardholder Name',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildNetBankingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Bank',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: [
            'State Bank of India',
            'HDFC Bank',
            'ICICI Bank',
            'Axis Bank',
            'Kotak Mahindra Bank',
          ].map((bank) {
            return DropdownMenuItem<String>(
              value: bank,
              child: Text(bank),
            );
          }).toList(),
          onChanged: (value) {},
        ),
      ],
    );
  }

  Future<void> _openDirections() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmPayment() async {
    // Validate form based on payment method
    if (_selectedPaymentMethod == 'UPI' && _upiIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UPI ID')),
      );
      return;
    }

    if (_selectedPaymentMethod == 'Credit/Debit Card' &&
        (_cardNumberController.text.isEmpty ||
            _expiryController.text.isEmpty ||
            _cvvController.text.isEmpty ||
            _nameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all card details')),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      // Create booking record
      final booking = Booking(
        id: BookingHistoryService.generateBookingId(),
        stationName: widget.stationName,
        connectorType: widget.connectorType,
        slotType: widget.slotType,
        vehicle: widget.vehicle,
        startTime: widget.startTime,
        duration: widget.duration,
        totalPrice: widget.totalPrice,
        paymentMethod: _selectedPaymentMethod,
        placeId: widget.placeId,
        latitude: widget.latitude,
        longitude: widget.longitude,
        status: 'Upcoming',
      );

      // Save to booking history
      await BookingHistoryService.saveBooking(booking);

      // Navigate to map page after successful payment
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/map', // Replace with your actual map page route
            (route) => false, // Remove all previous routes
      );

      // Show success message on the map page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful! Booking confirmed.')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }
}