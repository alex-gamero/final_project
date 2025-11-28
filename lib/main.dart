import 'package:flutter/material.dart';
import 'purchase_offers/purchase_offer_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'cars/cars_page.dart';
import 'localization/app_localizations.dart';

/// The main entry point of the Vehicle Sales Management application.
///
/// This function initializes and runs the Flutter application by calling
/// [runApp] with an instance of [MyApp].
void main() {
  runApp(const MyApp());
}

/// The root widget of the Vehicle Sales Management application.
///
/// This [StatefulWidget] manages the application's locale state and provides
/// internationalization support for English and Spanish languages.
///
class MyApp extends StatefulWidget {
  /// Creates a [MyApp] widget.
  const MyApp({super.key});

  /// Changes the application's current locale.
  ///
  /// This static method allows any widget in the application to change
  /// the language by providing a new [Locale] object.
  ///
  /// Parameters:
  /// - [context]: The build context used to find the current state
  /// - [newLocale]: The new locale to switch to (either 'en' or 'es')
  ///
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

/// The state class for [MyApp] that manages the application's locale and theme.
///
/// This class handles language switching and provides the material app
/// configuration with internationalization support.
class _MyAppState extends State<MyApp> {
  /// The current locale of the application.
  ///
  /// Defaults to English ('en') but can be changed to Spanish ('es')
  /// through the [changeLanguage] method.
  Locale _locale = const Locale('en');

  /// Changes the application's current language.
  ///
  /// Updates the [_locale] state variable and triggers a rebuild of the
  /// widget tree to reflect the language change.
  ///
  /// Parameters:
  /// - [newLocale]: The new locale to switch to
  ///
  void changeLanguage(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vehicle Sales Management',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// The home page widget that displays the main navigation dashboard.
///
/// This stateless widget provides a grid of feature cards that allow users
/// to navigate to different sections of the Vehicle Sales Management app,
/// including Customers, Cars, Boats, and Purchase Offers.
class HomePage extends StatelessWidget {
  /// Creates a [HomePage] widget.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Sales Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Welcome to Vehicle Sales Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage your vehicle sales operations efficiently',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    'Customers',
                    'Manage customer database',
                    Icons.people,
                    Colors.green,
                        () {
                      // Navigate to Customer List page
                      _showComingSoonSnackbar(context, 'Customers');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Cars',
                    'Manage car inventory',
                    Icons.directions_car,
                    Colors.orange,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CarsPage(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Boats',
                    'Manage boat inventory',
                    Icons.directions_boat,
                    Colors.blue,
                        () {
                      // Navigate to Boats for Sale page
                      _showComingSoonSnackbar(context, 'Boats');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Offers',
                    'Manage purchase offers',
                    Icons.attach_money,
                    Colors.purple,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PurchaseOfferPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a feature card for the home page dashboard.
  ///
  /// Creates a visually appealing card with an icon, title, and subtitle
  /// that users can tap to navigate to different sections of the app.
  ///
  /// Parameters:
  /// - [context]: The build context
  /// - [title]: The main title displayed on the card
  /// - [subtitle]: The descriptive text below the title
  /// - [icon]: The icon to display on the card
  /// - [color]: The primary color theme for the card
  /// - [onTap]: The callback function executed when the card is tapped
  ///
  /// Returns:
  /// A [Card] widget with an [InkWell] for tap interactions.
  ///
  Widget _buildFeatureCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a snackbar notification for features that are not yet implemented.
  ///
  /// Displays a temporary message at the bottom of the screen indicating
  /// that the requested feature is coming soon.
  ///
  /// Parameters:
  /// - [context]: The build context used to show the snackbar
  /// - [feature]: The name of the feature that is coming soon
  ///
  void _showComingSoonSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature - Coming Soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}