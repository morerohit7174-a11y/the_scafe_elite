import 'package:cafe_elite/firebase_options.dart';
import 'package:cafe_elite/providers/login_provider.dart';
import 'package:cafe_elite/screens/login_screen.dart';
import 'package:cafe_elite/screens/profile_screen.dart';
import 'package:cafe_elite/widgets/db_constants.dart';
import 'package:cafe_elite/widgets/pref_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/products_provider.dart';
import 'providers/bills_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/printer_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferenceUtils.init(); 
  print("Startup userId: ${SharedPreferenceUtils.getString(DatabaseConstants.userId)}");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const CafeEliteApp());
}

class CafeEliteApp extends StatelessWidget {
  const CafeEliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ listenToProducts() आता call होतो
        ChangeNotifierProvider(create: (_) {
          final provider = ProductsProvider();
          provider.listenToProducts();
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => BillsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
       ChangeNotifierProvider<LoginProvider>(create: (_) => LoginProvider()),
      ],
      child: MaterialApp( 
        title: 'The Cafe Elite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        routes: {
          '/login':     (_) =>  const LoginScreen(), 
          '/dashboard': (_) => const DashboardScreen(),
          '/pos':       (_) => const PosScreen(),
          '/products':  (_) => const ProductsScreen(),
          '/reports':   (_) => const ReportsScreen(),
          '/printer':   (_) => const PrinterScreen(),
          '/profile':   (_) => const ProfileScreen(),
        },
      ),
    );
  }
}