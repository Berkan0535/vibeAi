// lib/widgets/task_item.dart
// Bu dosya, tek bir görevi (Task) ekranda gösteren özel widget'ı içerir.

// Flutter Material bileşenlerini kullanabilmek için import edilir
import 'package:flutter/material.dart';

// Task modeline erişmek için import edilir
import '../models/task_model.dart';

// Tek bir görev kartını temsil eden StatelessWidget
class TaskItem extends StatelessWidget {
  // Gösterilecek görev nesnesi
  final Task task;

  // Checkbox değiştiğinde tetiklenecek callback fonksiyon
  final ValueChanged<bool?> onChanged;

  // Constructor
  const TaskItem({
    Key? key,

    // Task zorunlu parametre
    required this.task,

    // Checkbox değişim fonksiyonu zorunlu
    required this.onChanged,
  }) : super(key: key);

  // Widget'ın ekranda nasıl çizileceğini belirleyen build metodu
  @override
  Widget build(BuildContext context) {
    // Görev kartını saran ana Container
    return Container(
      // Kartlar arası alt boşluk
      margin: const EdgeInsets.only(bottom: 12),

      // Kartın iç boşluğu
      padding: const EdgeInsets.all(16),

      // Kartın görsel tasarımı
      decoration: BoxDecoration(
        // Görev tamamlandıysa açık gri, değilse beyaz arka plan
        color: task.isCompleted ? Colors.grey[50] : Colors.white,

        // Yuvarlatılmış köşeler
        borderRadius: BorderRadius.circular(16),

        // Kart kenarlığı
        border: Border.all(
          // Tamamlandıysa gri, değilse mor tonlu border
          color: task.isCompleted
              ? Colors.grey[300]!
              : const Color(0xFF6C5CE7).withOpacity(0.2),

          // Border kalınlığı
          width: 2,
        ),

        // Görev tamamlanmadıysa hafif gölge efekti
        boxShadow: task.isCompleted
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),

      // Yatay hizalama için Row kullanılır
      child: Row(
        children: [
          // Checkbox'ı biraz büyütmek için Transform.scale
          Transform.scale(
            scale: 1.2,

            // Görevin tamamlanma durumunu gösteren checkbox
            child: Checkbox(
              // Checkbox'ın mevcut değeri
              value: task.isCompleted,

              // Değer değiştiğinde dışarıdan gelen fonksiyon çağrılır
              onChanged: onChanged,

              // Checkbox köşelerinin yuvarlaklığı
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),

              // Aktif (işaretli) checkbox rengi
              activeColor: const Color(0xFF6C5CE7),
            ),
          ),

          // Checkbox ile metin arasına boşluk
          const SizedBox(width: 12),

          // Kalan alanı kaplaması için Expanded
          Expanded(
            child: Column(
              // Metinler sola hizalanır
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Görev başlığı
                Text(
                  task.title,
                  style: TextStyle(
                    // Yazı boyutu
                    fontSize: 16,

                    // Yazı kalınlığı
                    fontWeight: FontWeight.w500,

                    // Görev tamamlandıysa üstü çizili
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,

                    // Tamamlandıysa gri, değilse siyah ton
                    color: task.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),

                // Eğer görev için saat bilgisi varsa
                if (task.time != null) ...[
                  // Başlık ile saat arasına boşluk
                  const SizedBox(height: 4),

                  // Saat bilgisi satırı
                  Row(
                    children: [
                      // Saat ikonu
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),

                      // İkon ile saat metni arasına boşluk
                      const SizedBox(width: 4),

                      // Saat metni
                      Text(
                        task.time!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],

                // Eğer görev tamamlandıysa motivasyon mesajı gösterilir
                if (task.isCompleted) ...[
                  // Saat bilgisi ile mesaj arasına boşluk
                  const SizedBox(height: 6),

                  // Motivasyon mesajı satırı
                  Row(
                    children: [
                      // Onay (check) ikonu
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Color(0xFF00B894),
                      ),

                      // İkon ile metin arasına boşluk
                      const SizedBox(width: 4),

                      // Motivasyon cümlesi
                      Text(
                        task.motivationalQuote,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00B894),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
