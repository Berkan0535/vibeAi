// lib/screens/planning_screen.dart
// Haftalık görevlerin günlere göre listelendiği ve kullanıcı ilerlemesinin
// görsel olarak gösterildiği ana planlama ekranı

// Flutter’ın temel UI bileşenlerini içe aktarır
import 'package:flutter/material.dart';

// Telefonda titreşim (haptic feedback) gibi sistem servisleri için
import 'package:flutter/services.dart';

// Görev verisini temsil eden Task model sınıfı
import '../models/task_model.dart';

// Tek bir görevi temsil eden özel widget
import '../widgets/task_item.dart';

// Bildirim servisi
import '../services/notification_service.dart';

// Veri saklama servisi
import '../services/storage_service.dart';

// Haftalık plan ekranı
// StatefulWidget çünkü görevlerin tamamlanma durumu değişebilir
class PlanningScreen extends StatefulWidget {
  // Dışarıdan alınan görev listesi
  final List<Task> tasks;

  // Constructor – görev listesi zorunludur
  const PlanningScreen({Key? key, required this.tasks}) : super(key: key);

  // State sınıfını oluşturur
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

// PlanningScreen’e ait state sınıfı
// Animasyon kullanıldığı için TickerProviderStateMixin eklenmiştir
class _PlanningScreenState extends State<PlanningScreen>
    with TickerProviderStateMixin {
  // Haftanın günlerini tutan sabit liste
  final List<String> _weekDays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  // Gün kartları için animasyonları yöneten controller
  late AnimationController _animationController;

  // Widget ilk oluşturulduğunda çalışır
  @override
  void initState() {
    super.initState();

    // 800 milisaniye süren animasyon controller’ı oluşturulur
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this, // Performans için ekran yenileme ile senkron
    );

    // Sayfa açılır açılmaz animasyonu başlat
    _animationController.forward();
    
    // Görevler için bildirimleri planla
    _scheduleNotificationsForTasks();
    
    // Planları kaydet
    _saveTasks();
  }
  
  // Planları kaydeden fonksiyon
  Future<void> _saveTasks() async {
    try {
      await StorageService().saveTasks(widget.tasks);
      print('✅ Planlar kaydedildi');
    } catch (e) {
      print('❌ Plan kaydetme hatası: $e');
    }
  }

  // Widget ekrandan kaldırıldığında çalışır
  @override
  void dispose() {
    // Bellek sızıntısını önlemek için controller kapatılır
    _animationController.dispose();
    super.dispose();
  }
  
  // Görevler için bildirimleri planlayan fonksiyon
  void _scheduleNotificationsForTasks() {
    try {
      final now = DateTime.now();
      
      for (int i = 0; i < widget.tasks.length; i++) {
        final task = widget.tasks[i];
        
        // Eğer görevin saati varsa
        if (task.time != null && task.time!.contains('-')) {
          try {
            // Saat aralığını parse et (örn: "09:00-10:00")
            final timeParts = task.time!.split('-');
            final startTime = timeParts[0].trim();
            final startHourMin = startTime.split(':');
            final hour = int.parse(startHourMin[0]);
            final minute = int.parse(startHourMin[1]);
            
            // Günü bul
            final dayIndex = _weekDays.indexOf(task.day);
            if (dayIndex == -1) continue;
            
            // Bugünden itibaren kaç gün sonra
            final currentDayIndex = now.weekday - 1; // 0=Pazartesi
            int daysUntil = dayIndex - currentDayIndex;
            if (daysUntil < 0) daysUntil += 7; // Gelecek hafta
            
            // Görev zamanını hesapla
            final taskDateTime = DateTime(
              now.year,
              now.month,
              now.day + daysUntil,
              hour,
              minute,
            );
            
            // Sadece gelecekteki görevler için bildirim ayarla
            if (taskDateTime.isAfter(now)) {
              // 5 dakika öncesi bildirimi
              final reminderTime = taskDateTime.subtract(const Duration(minutes: 5));
              if (reminderTime.isAfter(now)) {
                NotificationService().scheduleNotification(
                  id: i * 2, // Çift sayılar 5 dk öncesi için
                  title: '⏰ Yaklaşan Görev',
                  body: '5 dakika sonra: ${task.title}',
                  scheduledTime: reminderTime,
                  payload: 'reminder_${task.title}',
                );
              }
              
              // Tam zamanında bildirim
              NotificationService().scheduleNotification(
                id: i * 2 + 1, // Tek sayılar tam zaman için
                title: '🎯 Görev Zamanı!',
                body: 'Şimdi: ${task.title}',
                scheduledTime: taskDateTime,
                payload: 'task_${task.title}',
              );
            }
          } catch (e) {
            print('Görev bildirim zamanlama hatası: $e');
          }
        }
      }
    } catch (e) {
      print('Bildirim zamanlama genel hatası: $e');
    }
  }

  // Görevleri günlere göre gruplandıran fonksiyon
  Map<String, List<Task>> _groupTasksByDay() {
    // Gün – görev listesi eşleşmesi için map
    Map<String, List<Task>> grouped = {};

    // Haftanın her günü için boş bir liste oluşturulur
    for (var day in _weekDays) {
      grouped[day] = [];
    }

    // Tüm görevler dolaşılır
    for (var task in widget.tasks) {
      // Görevin günü listede varsa o güne eklenir
      if (grouped.containsKey(task.day)) {
        grouped[task.day]!.add(task);
      }
    }

    // Gruplanmış görevler geri döndürülür
    return grouped;
  }

  // Tamamlanan görev sayısını hesaplayan getter
  int get _completedTasks {
    return widget.tasks.where((task) => task.isCompleted).length;
  }

  // İlerleme yüzdesini hesaplayan getter
  double get _progressPercentage {
    // Hiç görev yoksa sıfır döndür
    if (widget.tasks.isEmpty) return 0;

    // Tamamlanan / toplam görev oranı
    return _completedTasks / widget.tasks.length;
  }

  // Gün kartları için renk seçen fonksiyon
  Color _getDayColor(int index) {
    // Günlere özel renk listesi
    List<Color> colors = [
      const Color(0xFF6C5CE7),
      const Color(0xFF00B894),
      const Color(0xFFFF7675),
      const Color(0xFFFD79A8),
      const Color(0xFFFF9FF3),
      const Color(0xFF00CEC9),
      const Color(0xFFFDCB6E),
    ];

    // Index taşmasını önlemek için mod alınır
    return colors[index % colors.length];
  }

  // Gün kartları için ikon seçen fonksiyon
  IconData _getDayIcon(int index) {
    // Günlere özel ikon listesi
    List<IconData> icons = [
      Icons.wb_sunny_outlined,
      Icons.brightness_5_outlined,
      Icons.star_outline,
      Icons.celebration_outlined,
      Icons.favorite_outline,
      Icons.beach_access_outlined,
      Icons.nightlight_outlined,
    ];

    // Güvenli ikon döndürme
    return icons[index % icons.length];
  }

  // Ekranın çizildiği ana build fonksiyonu
  @override
  Widget build(BuildContext context) {
    // Görevleri günlere göre grupla
    final groupedTasks = _groupTasksByDay();

    // Toplam görev sayısı
    final totalTasks = widget.tasks.length;

    // Sayfa iskeleti
    return Scaffold(
      body: Container(
        // Arka plan için yumuşak gradyan
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C5CE7).withOpacity(0.1),
              const Color(0xFFA29BFE).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ================= ÜST ALAN =================
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Geri butonu ve başlık satırı
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Navigator.pop(context),
                            color: const Color(0xFF6C5CE7),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Sayfa başlık metinleri
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✨ Haftalık Planın Hazır!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Hedeflerine ulaşmak için adım adım ilerle',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bildirim butonu
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () async {
                              try {
                                // Anında bildirim gönder
                                await NotificationService().showInstantNotification(
                                  title: '🎯 Görev Hatırlatması',
                                  body: 'Bu Hafta ${widget.tasks.where((t) => !t.isCompleted).length} görevin var. Hadi başlayalım!',
                                );
                                
                                // Kullanıcıya geri bildirim
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Bildirim gönderildi!'),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: Color(0xFF6C5CE7),
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Hata durumunda kullanıcıyı bilgilendir
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Bildirim gönderilemedi: $e'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            color: const Color(0xFF6C5CE7),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ================= İLERLEME KARTI =================
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // İlerleme başlığı ve sayaç
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '📊 İlerleme',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Devam et, harikasın! 🎯',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              // Tamamlanan / toplam görev bilgisi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_completedTasks/$totalTasks',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Animasyonlu progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(
                                begin: 0,
                                end: _progressPercentage,
                              ),
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.3,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                    minHeight: 12,
                                  ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Yüzdelik ilerleme bilgisi
                          Text(
                            '${(_progressPercentage * 100).toInt()}% Tamamlandı',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ================= ALT ALAN – GÖREVLER =================
              Expanded(
                child: widget.tasks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Henüz görev yok',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _weekDays.length,
                        itemBuilder: (context, index) {
                          String day = _weekDays[index];
                          List<Task> dayTasks = groupedTasks[day] ?? [];

                          if (dayTasks.isEmpty) return const SizedBox.shrink();

                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final slideAnimation =
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        index * 0.1,
                                        0.6 + (index * 0.1),
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  );

                              final fadeAnimation =
                                  Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        index * 0.1,
                                        0.6 + (index * 0.1),
                                        curve: Curves.easeIn,
                                      ),
                                    ),
                                  );

                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: SlideTransition(
                                  position: slideAnimation,
                                  child: child,
                                ),
                              );
                            },

                            // Gün kartı içeriği
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getDayColor(index).withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Gün başlığı alanı
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _getDayColor(index),
                                            _getDayColor(
                                              index,
                                            ).withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getDayIcon(index),
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  day,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  '${dayTasks.length} görev',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Günün görevleri
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: dayTasks.map((task) {
                                          return TaskItem(
                                            task: task,
                                            onChanged: (value) async {
                                              setState(() {
                                                task.isCompleted =
                                                    value ?? false;
                                              });

                                              // Kullanıcıya hafif titreşim
                                              HapticFeedback.lightImpact();
                                              
                                              // Görevi güncelle ve kaydet
                                              await StorageService().updateTask(task);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
