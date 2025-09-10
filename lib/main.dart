import 'package:advertising_app/data/repository/auth_repository.dart';
import 'package:advertising_app/data/repository/car_sales_ad_repository.dart';
import 'package:advertising_app/data/repository/manage_ads_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:advertising_app/data/web_services/google_api_service.dart';
import 'package:advertising_app/data/web_services/google_maps_service.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:advertising_app/presentation/providers/car_sales_info_provider.dart';
import 'package:advertising_app/presentation/providers/car_services_ad_provider.dart';
import 'package:advertising_app/presentation/providers/car_services_info_provider.dart';
import 'package:advertising_app/presentation/providers/car_services_provider.dart';
import 'package:advertising_app/presentation/providers/car_services_offers_provider.dart';
import 'package:advertising_app/presentation/providers/manage_ads_provider.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:advertising_app/presentation/providers/settings_provider.dart';
import 'package:advertising_app/data/repository/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:advertising_app/router/go_router_app.dart';
import 'package:advertising_app/router/local_notifier.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final localeChangeNotifier = LocaleChangeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // 1. تهيئة جميع الخدمات والـ Repositories في مكان واحد
  final ApiService apiService = ApiService();
  final AuthRepository authRepository = AuthRepository(apiService);
  final CarAdRepository carAdRepository = CarAdRepository(apiService); // <-- تم تعريفه هنا
  final ManageAdsRepository myAdsRepository = ManageAdsRepository(apiService);
  final SettingsRepository settingsRepository = SettingsRepository(apiService);
  final GoogleApiService googleApiService = GoogleApiService();
  final GoogleMapsService googleMapsService = GoogleMapsService(googleApiService);

  runApp(
    // 2. استخدام MultiProvider لتوفير جميع الـ Providers
    MultiProvider(
      providers: [
         ChangeNotifierProvider.value(value: localeChangeNotifier),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CarAdProvider(carAdRepository), // <-- الآن يعمل بشكل صحيح
        ),
        ChangeNotifierProvider(
          create: (_) => CarSalesInfoProvider(), // <-- CarSalesInfoProvider بدون repository
        ),
        ChangeNotifierProvider(
          create: (_) => MyAdsProvider(myAdsRepository), // <-- استخدم الكائن الذي أنشأته
        ),
        ChangeNotifierProvider(
          create: (_) => GoogleMapsProvider(googleMapsService), // <-- Google Maps Provider
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsRepository), // <-- Settings Provider
        ),


         ChangeNotifierProvider(create: (_) => CarServicesInfoProvider()),
           ChangeNotifierProvider(create: (_) => CarServicesAdProvider()),
          ChangeNotifierProvider(create: (_) => CarServicesProvider()),
          ChangeNotifierProvider(create: (_) => CarServicesOffersProvider()),
  
        // يمكنك إضافة أي providers مستقبلية هنا
      ],
      child: const RootApp(),
    ),
  );
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  final LocaleChangeNotifier _localeNotifier = LocaleChangeNotifier();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(notifier: _localeNotifier);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeNotifier,
      builder: (context, _) {
        return ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            final baseTextTheme = Typography.englishLike2018.apply(fontSizeFactor: 1.sp);
            final theme = _localeNotifier.locale.languageCode == 'ar'
                ? ThemeData(textTheme: GoogleFonts.cairoTextTheme(baseTextTheme))
                : ThemeData(fontFamily: 'Montserrat', textTheme: baseTextTheme);

            return MaterialApp.router(
              locale: _localeNotifier.locale,
              routerConfig: _router,
              supportedLocales: S.delegate.supportedLocales,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              debugShowCheckedModeBanner: false,
              theme: theme,
              builder: (context, child) {
                return MediaQuery.withClampedTextScaling(
                  minScaleFactor: 1.0, maxScaleFactor: 1.0, child: child!,
                );
              }
            );
          },
        );
      },
    );
  }
}