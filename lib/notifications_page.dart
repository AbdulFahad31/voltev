import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Track which offer is expanded
  Map<int, bool> expandedOffers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offers',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF103050),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          bool isExpanded = expandedOffers[index] ?? false;

          return Card(
            color: const Color(0xFF103050),
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.local_offer, color: Colors.white),
                  title: Text(
                    offer['title']!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    offer['subtitle']!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onTap: () {
                    setState(() {
                      expandedOffers[index] = !isExpanded;
                    });
                  },
                ),
                if (isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      offer['details']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const Divider(color: Colors.white54),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => _showCouponMessage(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                      ),
                      child: const Text('Apply Coupon'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCouponMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coupon Application'),
        content: const Text('Coupon will be applied after payment integration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Sample Offers
final List<Map<String, String>> offers = [
  {
    'title': '20% off on weekend charging',
    'subtitle': 'Valid until Dec 31, 2025',
    'details': 'Get a 20% discount when you charge your EV on Saturdays and Sundays at any of our partner charging stations.',
  },
  {
    'title': '₹50 cashback on first booking',
    'subtitle': 'Limited period offer',
    'details': 'Enjoy a ₹50 cashback when you make your first EV charging slot reservation through our app.',
  },
];
