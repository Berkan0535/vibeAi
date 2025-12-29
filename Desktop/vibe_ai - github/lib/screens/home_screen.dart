// lib/screens/home_screen.dart
// Bu dosya, kullanıcının haftalık plan isteğini yazdığı ana ekranı içerir.

import 'package:flutter/material.dart'; // Flutter Material bileşenleri
import 'package:flutter/services.dart'; // Haptic feedback (titreşim) için
import '../services/ai_service.dart'; // Yapay zekâ servis sınıfı
import '../services/storage_service.dart'; // Veri saklama servisi
import 'planning_screen.dart'; // AI sonucu gösterilecek ekran
import 'login_screen.dart'; // Giriş ekranı

// Ana ekran StatefulWidget olarak tanımlanır
class HomeScreen extends StatefulWidget {
  // Constructor
  const HomeScreen({Key? key}) : super(key: key);

  // State oluşturulur
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// HomeScreen'in state sınıfı
// Animasyon kullanıldığı için TickerProviderStateMixin eklenmiştir
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Kullanıcının yazdığı metni kontrol eden controller
  final TextEditingController _textController = TextEditingController();

  // Yapay zekâ servisi nesnesi
  final AIService _aiService = AIService();

  // Yüklenme (loading) durumu
  bool _isLoading = false;

  // Buton animasyonu için controller
  late AnimationController _buttonController;

  // Buton ölçek (scale) animasyonu
  late Animation<double> _buttonAnimation;

  // Widget ilk açıldığında çalışan metot
  @override
  void initState() {
    super.initState();

    // Buton animasyon controller'ı
    _buttonController = AnimationController(
      // Animasyon süresi (300 ms)
      duration: const Duration(milliseconds: 300),

      // Vsync sağlayıcı
      vsync: this,
    );

    // Butonun basıldığında küçülüp büyümesini sağlayan animasyon
    _buttonAnimation =
        Tween<double>(
          // Normal boyut
          begin: 1.0,

          // Biraz küçülmüş boyut
          end: 0.95,
        ).animate(
          // Yumuşak geçiş eğrisi
          CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
        );
    
    // Kaydedilmiş planları kontrol et
    _checkSavedPlans();
  }
  
  // Kaydedilmiş planları kontrol eden fonksiyon
  Future<void> _checkSavedPlans() async {
    final tasks = await StorageService().loadTasks();
    
    if (tasks.isNotEmpty && mounted) {
      // Kaydedilmiş plan varsa kullanıcıya sor
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📋 Kaydedilmiş Plan Bulundu'),
          content: Text('${tasks.length} görevli planınız var. Devam etmek ister misiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                StorageService().clearTasks();
              },
              child: const Text('Yeni Plan Oluştur'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanningScreen(tasks: tasks),
                  ),
                );
              },
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );
    }
  }

  // Widget kapatıldığında çalışan metot
  @override
  void dispose() {
    // Text controller bellekten temizlenir
    _textController.dispose();

    // Animasyon controller temizlenir
    _buttonController.dispose();

    super.dispose();
  }

  // Yapay zekâya isteği gönderen fonksiyon
  Future<void> _sendToAI() async {
    // Eğer kullanıcı hiçbir şey yazmadıysa
    if (_textController.text.trim().isEmpty) {
      // Uyarı snackbar'ı gösterilir
      _showSnackBar(
        'Lütfen haftalık planınızı yazın',
        Icons.warning_amber_rounded,
        Colors.orange,
      );
      return;
    }

    // Buton basma animasyonu oynatılır
    _buttonController.forward().then((_) => _buttonController.reverse());

    // Hafif titreşim (haptic feedback)
    HapticFeedback.mediumImpact();

    // Loading başlatılır
    setState(() => _isLoading = true);

    try {
      // AI servisi kullanılarak görevler oluşturulur
      final tasks = await _aiService.generateWeeklyPlan(_textController.text);

      // Loading kapatılır
      setState(() => _isLoading = false);

      // Eğer AI görev üretemediyse
      if (tasks.isEmpty) {
        _showSnackBar(
          'Görev bulunamadı, lütfen daha detaylı yazın',
          Icons.info_outline,
          Colors.blue,
        );
        return;
      }

      // Planlama ekranına geçiş yapılır
      Navigator.push(
        context,

        // Özel slide animasyonlu geçiş
        PageRouteBuilder(
          // Hedef sayfa
          pageBuilder: (context, animation, secondaryAnimation) =>
              PlanningScreen(tasks: tasks),

          // Sayfa geçiş animasyonu
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Sağdan sola kayan animasyon
            var tween = Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      // Hata olursa loading kapatılır
      setState(() => _isLoading = false);

      // Hata mesajını temizle ve kullanıcı dostu hale getir
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Özel hata mesajları
      if (errorMessage.contains('quota') || 
          errorMessage.contains('exceeded') ||
          errorMessage.contains('Kullanım Limiti')) {
        _showSnackBar(
          '⚠️ API Kullanım Limiti\n\nGoogle Gemini API kotası doldu.\nBirkaç dakika bekleyip tekrar deneyin.',
          Icons.hourglass_empty,
          Colors.orange,
        );
      } else if (errorMessage.contains('İnternet') || errorMessage.contains('DNS')) {
        _showSnackBar(
          '📡 İnternet bağlantısı yok\n\nLütfen:\n• Wi-Fi veya mobil veriyi açın\n• Uçak modunu kapatın\n• Bağlantınızı kontrol edin',
          Icons.wifi_off,
          Colors.orange,
        );
      } else if (errorMessage.contains('zaman aşımı')) {
        _showSnackBar(
          '⏱️ İstek zaman aşımına uğradı\n\nLütfen tekrar deneyin',
          Icons.timer_off,
          Colors.orange,
        );
      } else {
        _showSnackBar(
          '❌ Bir hata oluştu\n\n$errorMessage',
          Icons.error_outline,
          Colors.red,
        );
      }
    }
  }

  // Ortak kullanılan Snackbar gösterme fonksiyonu
  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Snackbar içeriği
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),

        // Arka plan rengi
        backgroundColor: color,

        // Floating snackbar
        behavior: SnackBarBehavior.floating,

        // Yuvarlatılmış köşeler
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        // Ekran kenar boşlukları
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Ekranın UI'ının çizildiği metot
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sayfanın ana gövdesi
      body: Container(
        // Arka plan gradyanı
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),

        // Güvenli alan (çentik, status bar)
        child: SafeArea(
          // Sayfa iç boşluğu
          child: Padding(
            padding: const EdgeInsets.all(24.0),

            // Dikey düzen
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Üst karşılama alanı
                Row(
                  children: [
                    // Sol ikon kutusu
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Karşılama metni
                    Expanded(
                      child: FutureBuilder<Map<String, String?>>(
                        future: StorageService().getUser(),
                        builder: (context, snapshot) {
                          final userName = snapshot.data?['name'] ?? 'Kullanıcı';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Merhaba, $userName! 👋',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Haftanı planlamaya başla',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    
                    // Çıkış butonu
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Çıkış Yap'),
                            content: const Text('Çıkış yapmak istediğinize emin misiniz?\n\nPlanlarınız kaydedilecek.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Çıkış Yap'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true && mounted) {
                          await StorageService().logout();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      color: Colors.red,
                      tooltip: 'Çıkış Yap',
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Bilgilendirme kartı
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kart başlığı
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: Color(0xFF6C5CE7),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Haftalık Planın',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Açıklama metni
                      const Text(
                        'Yapacaklarını serbest metin olarak yaz, yapay zeka senin için planlasın! 🚀',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Metin giriş alanı
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6C5CE7).withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      // Kullanıcı metin alanı
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        minLines: 10,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        decoration: InputDecoration(
                          hintText:
                              '💭 Örnek:\n\nPazartesi sabah spor yapacağım...\nSalı toplantım var...\nÇarşamba proje teslimi...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(24),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Planla butonu (animasyonlu)
                ScaleTransition(
                  scale: _buttonAnimation,
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? const LinearGradient(
                              colors: [Colors.grey, Colors.grey],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                            ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _sendToAI,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          // Yükleniyorsa spinner, değilse buton içeriği
                          child: _isLoading
                              ? const SizedBox(
                                  height: 28,
                                  width: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Vibe ile Planla',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
