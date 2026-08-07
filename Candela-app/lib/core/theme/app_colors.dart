import 'package:flutter/material.dart';

/// App Color System for Candela Mobile App
/// Strictly adheres to brand & UI specs:
/// - Primary Brand Accent: Amber Flame #F59E0B / #D97706
/// - Dark Surface Accent: Charcoal Slate #1E293B / #0F172A
/// - Background Canvas: Warm Cream/Off-White #FAF8F5
/// - Status Accents: Success Green #10B981
class AppColors {
  // Primary Brand & Copper Terracotta Accents (from Customer Screenshots)
  static const Color primaryAmber = Color(0xFFD8580E);
  static const Color primaryAmberDark = Color(0xFFC84605);
  static const Color primaryAmberLight = Color(0xFFFCE8DB);
  static const Color copperOrange = Color(0xFFD8580E);
  static const Color copperOrangeDark = Color(0xFFB03800);

  // Background Canvas (Warm Cream / Off-White from Screenshots)
  static const Color scaffoldBackground = Color(0xFFFAF7F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Dark Surface Accents
  static const Color darkSlate = Color(0xFF1C1A17);
  static const Color darkBackground = Color(0xFF141210);
  static const Color royalNavy = Color(0xFF1E3A8A);

  // Pastel Category Background Tints (from Screenshots)
  static const Color pastelPink = Color(0xFFFCE4EC);
  static const Color pastelBlue = Color(0xFFE3F2FD);
  static const Color pastelGreen = Color(0xFFE8F5E9);
  static const Color pastelPurple = Color(0xFFF3E5F5);
  static const Color pastelTeal = Color(0xFFE0F7FA);
  static const Color pastelYellow = Color(0xFFFFFDE7);
  static const Color pastelSkyBlue = Color(0xFFE1F5FE);
  static const Color pastelGrey = Color(0xFFF5F5F5);

  // Status & Utility Accents
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenLight = Color(0xFFD1FAE5);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF97316);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C241E);
  static const Color textSecondary = Color(0xFF7A7067);
  static const Color textMuted = Color(0xFFA89F95);
  static const Color textLight = Color(0xFFFAF7F2);

  // Borders & Input Fill
  static const Color borderGrey = Color(0xFFEFE8DE);
  static const Color borderDark = Color(0xFF334155);
  static const Color inputBackground = Color(0xFFFFFFFF);
}
