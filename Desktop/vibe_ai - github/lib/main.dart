// lib/main.dart
// Uygulamanın giriş (entry point) dosyasıdır

// Flutter'ın temel Material Design bileşenlerini içe aktarır
import 'package:flutter/material.dart';

// Açılışta gösterilecek splash ekranını içe aktarır
import 'screens/splash_screen.dart';

// Bildirim servisi
import 'services/notification_service.dart';

// Veri saklama servisi
import 'services/storage_service.dart';

// Giriş ekranı
import 'screens/login_screen.dart';

// Ana ekran
import 'screens/home_screen.dart';

// Uygulamanın çalışmaya başladığı ana fonksiyon
void main() async {
  // Flutter binding'i başlat
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bildirim servisini başlat
  await NotificationService().initialize();
  
  // Bildirim izni iste
  await NotificationService().requestPermission();
  
  // Günlük hatırlatma bildirimi ayarla (her gün saat 09:00'da)
  await NotificationService().scheduleDailyNotification(
    id: 999,
    title: '🌟 Günaydın!',
    body: 'Bugünkü planlarını kontrol et ve hedeflerine ulaşmak için harekete geç!',
    hour: 9,
    minute: 0,
  );
  
  // Akşam hatırlatması (her gün saat 20:00'da)
  await NotificationService().scheduleDailyNotification(
    id: 998,
    title: '📊 Günlük Değerlendirme',
    body: 'Bugün neler başardın? Yarın için planlarını gözden geçir!',
    hour: 20,
    minute: 0,
  );
  
  // Flutter uygulamasını başlatır ve kök widget'ı çalıştırır
  runApp(const WeeklyPlannerApp());
}

// Uygulamanın kök widget'ı
// StatelessWidget çünkü uygulama genelinde değişen bir state yok
class WeeklyPlannerApp extends StatelessWidget {
  // Constructor – immutable olduğu için const kullanılır
  const WeeklyPlannerApp({Key? key}) : super(key: key);

  // Widget ağacını oluşturan build metodu
  @override
  Widget build(BuildContext context) {
    // MaterialApp: Flutter'daki temel uygulama yapı taşı
    return MaterialApp(
      // Uygulama başlığı (task switcher ve bazı platformlarda görünür)
      title: 'Vibe AI',

      // Debug modundaki kırmızı "DEBUG" bandını kapatır
      debugShowCheckedModeBanner: false,

      // Açık (light) tema ayarları
      theme: ThemeData(
        // Material 3 tasarım sistemini aktif eder
        useMaterial3: true,

        // Renk şeması ayarları
        colorScheme: ColorScheme.fromSeed(
          // Uygulamanın ana rengi (seed color)
          seedColor: const Color(0xFF6C5CE7),

          // Açık tema parlaklığı
          brightness: Brightness.light,
        ),

        // Uygulamada kullanılacak varsayılan font
        fontFamily: 'SF Pro Display',
      ),

      // Koyu (dark) tema ayarları
      darkTheme: ThemeData(
        // Material 3 aktif
        useMaterial3: true,

        // Dark tema için renk şeması
        colorScheme: ColorScheme.fromSeed(
          // Aynı ana renk kullanılır
          seedColor: const Color(0xFF6C5CE7),

          // Koyu tema parlaklığı
          brightness: Brightness.dark,
        ),

        // Dark tema için de aynı font ailesi
        fontFamily: 'SF Pro Display',
      ),

      // Uygulamanın hangi temayı kullanacağını belirler
      // Şu an zorla light tema seçilmiş
      themeMode: ThemeMode.light,

      // Uygulama açıldığında gösterilecek ilk ekran
      // Giriş durumuna göre yönlendirme
      home: FutureBuilder<bool>(
        future: StorageService().isLoggedIn(),
        builder: (context, snapshot) {
          // Yükleniyor
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Giriş yapılmışsa ana ekran, değilse giriş ekranı
          final isLoggedIn = snapshot.data ?? false;
          return isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
