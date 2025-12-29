// lib/services/storage_service.dart
// Veri kalıcılığı için local storage servisi

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'package:crypto/crypto.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Şifreyi hashle (güvenlik için)
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Kullanıcı kaydı oluştur
  Future<bool> registerUser({
    required String email,
    required String name,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Email zaten kayıtlı mı kontrol et
    final existingUsers = prefs.getStringList('registered_users') ?? [];
    
    for (var userJson in existingUsers) {
      final user = jsonDecode(userJson);
      if (user['email'] == email) {
        return false; // Email zaten kayıtlı
      }
    }
    
    // Yeni kullanıcı oluştur
    final newUser = {
      'email': email,
      'name': name,
      'password': _hashPassword(password),
      'created_at': DateTime.now().toIso8601String(),
    };
    
    existingUsers.add(jsonEncode(newUser));
    await prefs.setStringList('registered_users', existingUsers);
    
    print('✅ Kullanıcı kaydedildi: $email');
    return true;
  }

  // Kullanıcı girişi yap
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final registeredUsers = prefs.getStringList('registered_users') ?? [];
    
    final hashedPassword = _hashPassword(password);
    
    for (var userJson in registeredUsers) {
      final user = jsonDecode(userJson);
      if (user['email'] == email && user['password'] == hashedPassword) {
        // Giriş başarılı - oturum aç
        await prefs.setString('current_user_email', email);
        await prefs.setString('current_user_name', user['name']);
        await prefs.setBool('is_logged_in', true);
        
        print('✅ Giriş başarılı: $email');
        return {
          'success': true,
          'name': user['name'],
          'email': email,
        };
      }
    }
    
    print('❌ Giriş başarısız: Email veya şifre hatalı');
    return {
      'success': false,
      'error': 'Email veya şifre hatalı',
    };
  }

  // Kullanıcı giriş durumunu kontrol et
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Kullanıcı bilgilerini al
  Future<Map<String, String?>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('current_user_email'),
      'name': prefs.getString('current_user_name'),
    };
  }

  // Çıkış yap
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('current_user_email');
    await prefs.remove('current_user_name');
    print('✅ Çıkış yapıldı');
  }

  // Planları kaydet (kullanıcıya özel)
  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('current_user_email');
    
    if (userEmail == null) {
      print('❌ Kullanıcı girişi yapılmamış');
      return;
    }
    
    // Task listesini JSON'a çevir
    List<Map<String, dynamic>> tasksJson = tasks.map((task) => {
      'title': task.title,
      'day': task.day,
      'time': task.time,
      'isCompleted': task.isCompleted,
      'motivationalQuote': task.motivationalQuote,
    }).toList();
    
    String jsonString = jsonEncode(tasksJson);
    await prefs.setString('tasks_$userEmail', jsonString);
    await prefs.setString('tasks_save_date_$userEmail', DateTime.now().toIso8601String());
    
    print('✅ ${tasks.length} görev kaydedildi ($userEmail)');
  }

  // Planları yükle (kullanıcıya özel)
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('current_user_email');
    
    if (userEmail == null) {
      print('❌ Kullanıcı girişi yapılmamış');
      return [];
    }
    
    String? jsonString = prefs.getString('tasks_$userEmail');
    
    if (jsonString == null || jsonString.isEmpty) {
      print('❌ Kaydedilmiş plan bulunamadı ($userEmail)');
      return [];
    }
    
    try {
      List<dynamic> tasksJson = jsonDecode(jsonString);
      List<Task> tasks = tasksJson.map((json) => Task(
        title: json['title'] ?? '',
        day: json['day'] ?? '',
        time: json['time'],
        isCompleted: json['isCompleted'] ?? false,
        motivationalQuote: json['motivationalQuote'] ?? 'Harika!',
      )).toList();
      
      print('✅ ${tasks.length} görev yüklendi ($userEmail)');
      return tasks;
    } catch (e) {
      print('❌ Görevler yüklenirken hata: $e');
      return [];
    }
  }

  // Planları sil
  Future<void> clearTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('current_user_email');
    
    if (userEmail == null) return;
    
    await prefs.remove('tasks_$userEmail');
    await prefs.remove('tasks_save_date_$userEmail');
    print('✅ Planlar silindi ($userEmail)');
  }

  // Son plan oluşturma tarihini al
  Future<DateTime?> getLastPlanDate() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('current_user_email');
    
    if (userEmail == null) return null;
    
    String? dateString = prefs.getString('tasks_save_date_$userEmail');
    
    if (dateString == null) return null;
    
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Tek bir görevi güncelle
  Future<void> updateTask(Task updatedTask) async {
    List<Task> tasks = await loadTasks();
    
    // Görevi bul ve güncelle
    int index = tasks.indexWhere((task) => 
      task.title == updatedTask.title && 
      task.day == updatedTask.day &&
      task.time == updatedTask.time
    );
    
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
      print('✅ Görev güncellendi: ${updatedTask.title}');
    }
  }
}
