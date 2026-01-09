import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'homepage.dart';
import 'otp_verification.dart';
import 'main_page.dart';
import 'notifications_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'station_details_page.dart';
import 'time_selection_page.dart';
import 'payment_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AmpTrail EV Charging',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/home',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomepageWidget(),
        '/otp': (context) => OTPVerificationPage(
          phoneNumber: '',
          verificationId: '',
        ),
        '/map': (context) => const MainNavigationWrapper(),
        '/history': (context) => const HistoryPage(),
        '/stationDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return StationDetailsPage(
            placeId: args['placeId'],
            latitude: args['latitude'],
            longitude: args['longitude'],
          );
        },
        '/timeSelection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TimeSelectionPage(
            placeId: args['placeId'],
            stationName: args['stationName'],
            slotType: args['slotType'],
            pricePerKwh: args['pricePerKwh'],
            serviceCharge: args['serviceCharge'],
            latitude: args['latitude'],
            longitude: args['longitude'],
          );
        },
        '/payment': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaymentPage(
            stationName: args['stationName'],
            connectorType: args['connectorType'],
            slotType: args['slotType'],
            totalPrice: args['totalPrice'],
            placeId: args['placeId'],
            latitude: args['latitude'],
            longitude: args['longitude'],
            vehicle: args['vehicle'],
            startTime: args['startTime'],
            duration: args['duration'],
          );
        },
      },
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MainPage(),
    const NotificationsPage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Offers'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}