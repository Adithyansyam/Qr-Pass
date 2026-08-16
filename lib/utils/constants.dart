import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Supabase configuration
// Replace these with your actual Supabase project URL and anon key.
// ---------------------------------------------------------------------------
class SupabaseConfig {
  static const String url = 'https://vpivslvyvmjggntfazbt.supabase.co';
  static const String anonKey = 'sb_publishable_Tz2_i9KrlxAYXMaCkzSp9g_XTvMf6Z9';
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------
class DbTable {
  static const String students = 'students';
}

// ---------------------------------------------------------------------------
// Pass
// ---------------------------------------------------------------------------
class PassConstants {
  static const String prefix = 'ONAM-';
  static const int idLength = 8; // hex chars after prefix
}

// ---------------------------------------------------------------------------
// Pass status values
// ---------------------------------------------------------------------------
class PassStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
}

// ---------------------------------------------------------------------------
// Onam-inspired colour palette
// ---------------------------------------------------------------------------
class OnamColors {
  // Primary gold — pookalam / lamp
  static const Color gold = Color(0xFFE6A817);
  static const Color goldLight = Color(0xFFFFC947);
  static const Color goldDark = Color(0xFFB07D0B);

  // Deep Kerala green — banana leaf / plantain
  static const Color green = Color(0xFF1B6B36);
  static const Color greenLight = Color(0xFF2E9451);
  static const Color greenDark = Color(0xFF0F4020);

  // Warm cream / white
  static const Color cream = Color(0xFFFFF8E7);
  static const Color white = Color(0xFFFFFFFF);

  // Status colours
  static const Color pending = Color(0xFFE6A817);
  static const Color approved = Color(0xFF2E9451);
  static const Color error = Color(0xFFD32F2F);

  // Surface & background
  static const Color surface = Color(0xFFFFFDF5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF0F1C13);
  static const Color darkSurface = Color(0xFF1A2E1F);

  // Text
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF555555);
  static const Color textLight = Color(0xFF888888);
}

// ---------------------------------------------------------------------------
// Common border radii (use as values, not constants with BorderRadius)
// ---------------------------------------------------------------------------
class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static BorderRadius card = BorderRadius.circular(16);
  static BorderRadius button = BorderRadius.circular(24);
}

// ---------------------------------------------------------------------------
// Spacing constants
// ---------------------------------------------------------------------------
class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
