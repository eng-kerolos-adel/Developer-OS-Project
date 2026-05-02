import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 استوردنا دي
import 'package:developer_os/features/ai/services/ai_service.dart';

// المفتاح الثابت في الـ SharedPreferences
const String _geminiKeyStorageKey = 'gemini_api_key';

// =====================
// API Key Provider
// =====================
final aiApiKeyProvider =
    StateNotifierProvider<AIKeyNotifier, String?>((ref) {
  return AIKeyNotifier();
});

class AIKeyNotifier extends StateNotifier<String?> {
  AIKeyNotifier([String? initialKey]) : super(initialKey) {
    // لو الـ main بعت الكي، الـ state هتكون هي الـ initialKey علطول
    // لو ملقاش كي جاي من المين، هيروح يدور عليه في الـ Storage
    if (initialKey == null) {
      _load();
    }
  }

  // 🔥 قراءة الـ Key أول ما الـ Provider يقوم
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_geminiKeyStorageKey);
      if (savedKey != null) {
        debugPrint('🔑 [AIKeyNotifier]: API Key loaded from SharedPreferences');
        state = savedKey;
      }
    } catch (e) {
      debugPrint('❌ [AIKeyNotifier] Load Error: $e');
    }
  }

  Future<bool> saveKey(String key) async {
    try {
      final service = AIService(apiKey: key);
      final valid = await service.validateKey();
      if (!valid) return false;
      
      // 🔥 الحفظ في الـ SharedPreferences العادية
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_geminiKeyStorageKey, key);
      
      debugPrint('💾 [saveKey]: API Key saved successfully!');
      state = key;
      return true;
    } catch (e) {
      debugPrint('❌ [saveKey] Error: $e');
      return false;
    }
  }

  Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiKeyStorageKey); // 🔥 بنمسح الكي بجد
    state = null;
    debugPrint('🗑️ [clearKey]: API Key cleared from storage.');
  }
}

// =====================
// AI Service Provider
// =====================
final aiServiceProvider = Provider<AIService?>((ref) {
  final key = ref.watch(aiApiKeyProvider);
  if (key == null) return null;
  return AIService(apiKey: key);
});

// =====================
// AI Generation State
// =====================
class AIGenerationState {
  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;

  const AIGenerationState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  AIGenerationState copyWith({
    bool? isLoading,
    Map<String, dynamic>? result,
    String? error,
  }) {
    return AIGenerationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

final aiGenerationProvider =
    StateNotifierProvider<AIGenerationNotifier, AIGenerationState>((ref) {
  return AIGenerationNotifier(ref);
});

class AIGenerationNotifier extends StateNotifier<AIGenerationState> {
  final Ref _ref;

  AIGenerationNotifier(this._ref) : super(const AIGenerationState());

  Future<Map<String, dynamic>?> generateProject({
    required String name,
    String? specialization,
    List<String>? skills,
  }) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) {
      state = state.copyWith(
          error: 'AI not configured. Add Gemini API key in Settings.');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await service.generateProjectDetails(
        projectName: name,
        specialization: specialization,
        existingTechs: skills,
      );
      state = state.copyWith(isLoading: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: 'AI generation failed: ${e.toString()}');
      return null;
    }
  }

  Future<List<String>> generateInterviewQuestions({
    required String position,
    required String company,
  }) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) return [];

    try {
      return await service.generateInterviewQuestions(
        position: position,
        company: company,
      );
    } catch (e) {
      return [];
    }
  }

  void clear() {
    state = const AIGenerationState();
  }

  // ميثود تلخيص اليوميات
  Future<String?> summarizeJournal(String content) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) return null;
    return await service.generateJournalSummary(content);
  }

  // ميثود وصف المهام
  Future<String?> generateTaskDesc(String taskTitle, String projectName) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) return null;
    return await service.generateTaskDescription(taskTitle, projectName);
  }

  // ميثود وصف المهام
  Future<String?> generateBio(String prompt) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) return null;
    return await service.generateBio(prompt);
  }

  // ميثود وصف المهام
  Future<String?> generateReadme(String prompt) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) return null;
    return await service.generateReadme(prompt);
  }

  // ميثود شرح الكود
  Future<String?> explainMyCode(String code, String lang) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) return null;
    return await service.explainCode(code, lang);
  }
}