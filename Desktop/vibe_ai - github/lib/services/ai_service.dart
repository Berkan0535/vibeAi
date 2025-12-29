// lib/services/ai_service.dart

import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task_model.dart';

class AIService {
  // ⚠️ GÜVENLİK UYARISI: API Anahtarını production ortamında .env dosyasından çekmelisin.
  static const String _apiKey = "UYGULAMANIN_TAM_HALİ_İÇİN_İLETİŞİME_GEÇİN";

  Future<List<Task>> generateWeeklyPlan(String userRequest) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );

      // --- GELİŞTİRİLMİŞ PROFESYONEL PROMPT ---
      final prompt =
          '''
Sen uzman bir yaşam koçu ve verimlilik danışmanısın. Kullanıcının isteğine göre bilimsel ve gerçekçi bir haftalık plan oluştur.

KULLANICI İSTEĞİ: "$userRequest"

🎯 PLANLAMA PRENSİPLERİ:

1. **BİLİMSEL YAKLAŞIM:**
   - İnsan konsantrasyonu 90 dakikada düşer, bu yüzden uzun görevleri böl
   - Sabah saatleri (08:00-12:00) yüksek konsantrasyon gerektiren işler için ideal
   - Öğleden sonra (14:00-16:00) enerji düşer, hafif görevler planla
   - Akşam (19:00-21:00) yaratıcı işler için uygun

2. **ZORUNLU YAŞAM RUTİNLERİ:**
   - Uyku: 7-8 saat (örn: 23:00-07:00)
   - Kahvaltı: 08:00-08:30 (30 dk)
   - Öğle Yemeği: 12:30-13:00 (30 dk)
   - Akşam Yemeği: 19:00-19:30 (30 dk)
   - Günlük en az 30 dk fiziksel aktivite

3. **MOLA KURALLARI:**
   - Her aktivite arasında EN AZ 15 dakika mola
   - 2 saatten uzun aktiviteler arasında 30 dakika mola
   - Öğün sonrası 30 dakika dinlenme

4. **GERÇEKÇİLİK:**
   - Günde maksimum 8-10 saat verimli çalışma
   - Hafta sonu daha hafif program
   - Sosyal zaman ve hobi için yer ayır
   - Beklenmedik durumlar için buffer time bırak

5. **AKILLI DAĞILIM:**
   - Benzer görevleri grupla (batch processing)
   - Zor görevleri sabaha, kolay görevleri öğleden sonraya
   - Her gün aynı saatte benzer rutinler (alışkanlık oluşumu)
   - Hafta içi-hafta sonu dengesi

⚠️ YASAKLAR:
- Saatleri ÜST ÜSTE BİNDİRME
- Gerçekçi olmayan sürelerde çok iş sıkıştırma
- Mola vermeden 3 saatten fazla aktivite
- Gece 23:00'dan sonra yoğun aktivite
- Sabah 07:00'den önce aktivite
-arka arkayya aralıksız plan yapma mesela 1 de işim bitiyorsa 1 de uykuya dalamam biraz düşün ona göre cevapla

📋 ÇIKTI FORMATI (SADECE BU FORMATTA VER):

Pazartesi:
- Uyanış ve Hazırlık (07:00-07:30)
- Kahvaltı (08:00-08:30)
- [Kullanıcı İsteği - Yüksek Konsantrasyon] (09:00-11:00)
- Mola (11:00-11:15)
- [Kullanıcı İsteği Devam] (11:15-12:30)
- Öğle Yemeği (12:30-13:00)
- Dinlenme (13:00-13:30)
- [Hafif Görevler] (13:30-15:00)
- Spor/Egzersiz (17:00-17:30)
- Akşam Yemeği (19:00-19:30)
- Serbest Zaman (20:00-22:00)
- Uyku Hazırlığı (22:30-23:00)

NOT: Saatleri (HH:MM-HH:MM) formatında yaz. Türkçe kullan. Sadece listeyi ver, açıklama yapma.
      ''';
      // --- PROMPT BİTİŞİ ---

      final content = [Content.text(prompt)];
      final response = await model
          .generateContent(content)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
              );
            },
          );

      if (response.text != null && response.text!.isNotEmpty) {
        return _parseTasksFromAI(response.text!);
      } else {
        throw Exception('AI boş cevap döndürdü.');
      }
    } on SocketException {
      throw Exception(
        'İnternet bağlantısı yok. Lütfen internet bağlantınızı kontrol edin.',
      );
    } on HttpException {
      throw Exception(
        'Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.',
      );
    } catch (e) {
      String errorMessage = e.toString();

      // Hata mesajını logla
      print('AI Servisi Hatası: $errorMessage');

      // Quota hatası kontrolü - daha spesifik kontrol
      if (errorMessage.toLowerCase().contains('429') ||
          errorMessage.toLowerCase().contains('resource_exhausted') ||
          (errorMessage.toLowerCase().contains('quota') &&
              errorMessage.toLowerCase().contains('exceeded'))) {
        throw Exception(
          '⚠️ API Kullanım Limiti Doldu\n\n'
          'Google Gemini API\'nin ücretsiz kullanım kotası dolmuş.\n\n'
          'Çözüm:\n'
          '• Birkaç dakika bekleyip tekrar deneyin\n'
          '• Veya daha sonra tekrar deneyin\n\n'
          'Not: Bu geçici bir durumdur.',
        );
      }

      // DNS hatası kontrolü
      if (errorMessage.contains('Failed host lookup') ||
          errorMessage.contains('SocketException')) {
        throw Exception(
          'İnternet bağlantısı yok veya DNS hatası. Lütfen:\n• İnternet bağlantınızı kontrol edin\n• Wi-Fi veya mobil veriyi açın\n• Uçak modunu kapatın',
        );
      }

      // Timeout hatası
      if (errorMessage.contains('TimeoutException') ||
          errorMessage.contains('zaman aşımı')) {
        throw Exception('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
      }

      // Genel hata - orijinal mesajı göster
      throw Exception(
        'Plan oluşturulamadı: ${errorMessage.replaceAll('Exception: ', '')}',
      );
    }
  }

  // Parse fonksiyonu aynı kalıyor, çünkü çıktı formatını değiştirmedik, sadece içeriği zenginleştirdik.
  List<Task> _parseTasksFromAI(String aiResponse) {
    List<Task> tasks = [];
    List<String> lines = aiResponse.split('\n');
    String? currentDay;

    List<String> motivationalQuotes = [
      'Harika bir adım!',
      'Başarıya giden yoldasın!',
      'Sen yaparsın!',
      'İleriye doğru!',
      'Mükemmel planlama!',
    ];

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.contains('Pazartesi') ||
          line.contains('Salı') ||
          line.contains('Çarşamba') ||
          line.contains('Perşembe') ||
          line.contains('Cuma') ||
          line.contains('Cumartesi') ||
          line.contains('Pazar')) {
        currentDay = line.replaceAll(':', '').trim();
      } else if (line.startsWith('-') && currentDay != null) {
        String taskText = line.substring(1).trim();
        String? time;

        // Köşeli parantezleri ve normal parantezleri temizle
        RegExp timeRegex = RegExp(
          r'[\[\(](\d{2}:\d{2}-\d{2}:\d{2}|\d{2}:\d{2})[\]\)]',
        );
        Match? match = timeRegex.firstMatch(taskText);

        if (match != null) {
          time = match.group(1);
          taskText = taskText.replaceAll(timeRegex, '').trim();
        }

        // Kalan köşeli parantezleri temizle
        taskText = taskText.replaceAll(RegExp(r'[\[\]]'), '').trim();

        tasks.add(
          Task(
            title: taskText,
            day: currentDay,
            time: time,
            motivationalQuote:
                motivationalQuotes[tasks.length % motivationalQuotes.length],
          ),
        );
      }
    }
    return tasks;
  }
}
