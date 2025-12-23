import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';

class MoodHelper {
  static String getMoodEmoji(String mood) {
    const moodEmojis = {
      'happy': '😊',
      'sad': '😢',
      'anxious': '😰',
      'excited': '🤩',
      'calm': '😌',
      'neutral': '😐',
      'angry': '😠',
      'frustrated': '😤',
      'tired': '😴',
      'energetic': '⚡',
      'grateful': '🙏',
      'loved': '🥰',
      'lonely': '😔',
      'stressed': '😫',
      'confused': '😕',
      'hopeful': '🌟',
      'proud': '😎',
      'content': '☺️',
      'overwhelmed': '😵',
      'peaceful': '🕊️',
      'bored': '😑',
      'surprised': '😲',
      'worried': '😟',
      'relaxed': '😊',
      'playful': '😜',
    };
    return moodEmojis[mood] ?? '😐';
  }

  static List<String> getAllMoods() {
    return [
      'happy',
      'sad',
      'anxious',
      'excited',
      'calm',
      'neutral',
      'angry',
      'frustrated',
      'tired',
      'energetic',
      'grateful',
      'loved',
      'lonely',
      'stressed',
      'confused',
      'hopeful',
      'proud',
      'content',
      'overwhelmed',
      'peaceful',
      'bored',
      'surprised',
      'worried',
      'relaxed',
      'playful',
    ];
  }

  static String getMoodLabel(String mood) {
    final emoji = getMoodEmoji(mood);
    final label = _capitalize('moods.$mood'.tr());
    return '$emoji $label';
  }
  
  // Build dropdown items for mood filter with emojis
  static List<DropdownMenuItem<String>> buildMoodFilterItems() {
    return [
      DropdownMenuItem(value: null, child: Text('moods.all_moods'.tr())),
      ...getAllMoods().map((mood) {
        return DropdownMenuItem(
          value: mood,
          child: Text(getMoodLabel(mood)), // Uses emoji + translated label
        );
      }),
    ];
  }
  
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}