// lib/screens/splash_screen.dart
// Bu dosya, uygulama açıldığında gösterilen Splash (açılış) ekranını içerir.

import 'package:flutter/material.dart'; // Flutter Material bileşenleri
import 'home_screen.dart'; // Splash sonrası geçilecek ana ekran
import '../services/notification_service.dart'; // Bildirim servisi

// Splash ekranı StatefulWidget olarak tanımlanır
class SplashScreen extends StatefulWidget {
  // Constructor
  const SplashScreen({Key? key}) : super(key: key);

  // Widget'ın state'ini oluşturur
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Splash ekranının state sınıfı
// Animasyon kullanıldığı için SingleTickerProviderStateMixin eklenmiştir
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animasyonları kontrol eden controller
  late AnimationController _controller;

  // Logo büyütme/küçültme animasyonu
  late Animation<double> _scaleAnimation;

  // Opacity (saydamlık) animasyonu
  late Animation<double> _opacityAnimation;

  // Widget ilk oluşturulduğunda çalışan metot
  @override
  void initState() {
    super.initState();

    // Animasyon controller'ı oluşturulur
    _controller = AnimationController(
      // Animasyon süresi: 1.5 saniye
      duration: const Duration(milliseconds: 1500),

      // Animasyonun çalışması için vsync sağlayıcı
      vsync: this,
    );

    // Ölçek animasyonu (küçükten büyüğe)
    _scaleAnimation =
        Tween<double>(
          // Başlangıç boyutu (%50)
          begin: 0.5,

          // Bitiş boyutu (%100)
          end: 1.0,
        ).animate(
          // Animasyona easing efekti eklenir
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        );

    // Opacity animasyonu (şeffaf → görünür)
    _opacityAnimation =
        Tween<double>(
          // Başlangıçta görünmez
          begin: 0.0,

          // Tamamen görünür
          end: 1.0,
        ).animate(
          // Yumuşak giriş animasyonu
          CurvedAnimation(parent: _controller, curve: Curves.easeIn),
        );

    // Animasyonları başlatır
    _controller.forward();
    
    // Bildirim servisini arka planda başlat
    _initializeNotifications();

    // 2 saniye sonra ana ekrana geçiş yapılır
    Future.delayed(const Duration(seconds: 2), () {
      // Mevcut splash ekranı stack'ten silinerek HomeScreen'e geçilir
      Navigator.of(context).pushReplacement(
        // Özel geçiş animasyonu tanımlamak için PageRouteBuilder
        PageRouteBuilder(
          // Hedef sayfa
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),

          // Sayfa geçiş animasyonu
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade (solma) efekti
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  // Widget yok edildiğinde çalışan metot
  @override
  void dispose() {
    // Bellek sızıntısını önlemek için controller kapatılır
    _controller.dispose();

    super.dispose();
  }
  
  // Bildirim servisini başlatan fonksiyon
  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
      await NotificationService().requestPermission();
    } catch (e) {
      print('Bildirim servisi başlatılamadı: $e');
    }
  }

  // UI'nin çizildiği metot
  @override
  Widget build(BuildContext context) {
    // Scaffold sayfa iskeleti
    return Scaffold(
      // Sayfanın ana gövdesi
      body: Container(
        // Arka plan gradyanı
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Gradyan başlangıç noktası
            begin: Alignment.topLeft,

            // Gradyan bitiş noktası
            end: Alignment.bottomRight,

            // Kullanılan renkler
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE), Color(0xFFFF7675)],
          ),
        ),

        // İçerik ortalanır
        child: Center(
          // Animasyonları dinleyen builder
          child: AnimatedBuilder(
            // Dinlenecek animasyon controller
            animation: _controller,

            // Animasyon her değiştiğinde yeniden çizilir
            builder: (context, child) {
              return Opacity(
                // Opacity animasyonu uygulanır
                opacity: _opacityAnimation.value,

                child: Transform.scale(
                  // Scale animasyonu uygulanır
                  scale: _scaleAnimation.value,

                  child: Column(
                    // İçerik dikeyde ortalanır
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      // Logo kutusu
                      Container(
                        // Logo genişliği
                        width: 120,

                        // Logo yüksekliği
                        height: 120,

                        // Logo arka plan tasarımı
                        decoration: BoxDecoration(
                          // Beyaz arka plan
                          color: Colors.white,

                          // Yuvarlatılmış köşeler
                          borderRadius: BorderRadius.circular(30),

                          // Gölge efekti
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),

                        // Logo resmi
                        child: Image.asset(
                          // Asset yolu
                          'assets/logo.png',

                          // Resim genişliği
                          width: 80,

                          // Resim yüksekliği
                          height: 80,
                        ),
                      ),

                      // Logo ile başlık arası boşluk
                      const SizedBox(height: 24),

                      // Uygulama adı
                      const Text(
                        'Vibe AI',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),

                      // Başlık ile slogan arası boşluk
                      const SizedBox(height: 8),

                      // Uygulama sloganı
                      const Text(
                        'Haftanı Akıllıca Planla',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
