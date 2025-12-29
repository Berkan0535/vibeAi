// lib/models/task_model.dart
// Bu dosya, uygulamada kullanılacak Task (Görev) modelini tanımlar.

class Task {
  // Görevin başlığını tutar (ör: "Spor Yap", "Ders Çalış")
  final String title;

  // Görevin ait olduğu günü tutar (ör: "Pazartesi", "Salı")
  final String day;

  // Görevin saat bilgisi (opsiyonel olabilir, null olabilir)
  final String? time;

  // Görev için gösterilecek motivasyon cümlesi
  final String motivationalQuote;

  // Görevin tamamlanıp tamamlanmadığını tutar
  // false = tamamlanmadı, true = tamamlandı
  bool isCompleted;

  // Task sınıfının constructor (kurucu) metodu
  Task({
    // Görev başlığı zorunludur
    required this.title,

    // Görev günü zorunludur
    required this.day,

    // Saat bilgisi opsiyoneldir
    this.time,

    // Motivasyon cümlesi verilmezse varsayılan olarak bu metin kullanılır
    this.motivationalQuote = 'Harika bir adım!',

    // Görev ilk oluşturulduğunda tamamlanmamış kabul edilir
    this.isCompleted = false,
  });
}
