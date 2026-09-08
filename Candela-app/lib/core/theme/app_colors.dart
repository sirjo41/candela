import 'package:flutter/material.dart';

/// App Color System for Candela Mobile App
/// Strictly adheres to brand & UI specs:
/// - Dark Mode Tokens: #0F172A dark slate surfaces, #1E293B dark cards, #F59E0B amber accents
/// - Primary Brand Accent: Amber Flame #F59E0B / #D97706 / Copper #D8580E
/// - Background Canvas: Warm Cream/Off-White #FAF8F5 (Light Mode)
/// - Status Accents: Success Green #10B981
class AppColors {
  // Primary Brand & Amber Accents
  static const Color primaryAmber = Color(0xFFF59E0B);
  static const Color primaryAmberDark = Color(0xFFD97706);
  static const Color primaryAmberLight = Color(0xFFFEF3C7);
  static const Color copperOrange = Color(0xFFD8580E);
  static const Color copperOrangeDark = Color(0xFFB03800);

  // Light Mode Canvas & Surfaces
  static const Color scaffoldBackground = Color(0xFFFAF7F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Dark Mode Tokens (Production-Grade Specs)
  static const Color darkSlateSurface = Color(0xFF0F172A); // #0F172A dark slate surfaces
  static const Color darkSlateCard = Color(0xFF1E293B);    // #1E293B dark card background
  static const Color darkSlateBorder = Color(0xFF334155);  // #334155 border
  static const Color darkAmberAccent = Color(0xFFF59E0B);  // #F59E0B amber accents
  static const Color darkTextPrimary = Color(0xFFF8FAFC);  // Slate 50 high contrast text
  static const Color darkTextSecondary = Color(0xFF94A3B8);// Slate 400 secondary text
  static const Color darkInputBg = Color(0xFF1E293B);

  // Dark Surface Accents (Shared)
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color darkBackground = Color(0xFF0A0F1D);
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

  // Text Colors (Light Mode)
  static const Color textPrimary = Color(0xFF2C241E);
  static const Color textSecondary = Color(0xFF7A7067);
  static const Color textMuted = Color(0xFFA89F95);
  static const Color textLight = Color(0xFFFAF7F2);

  // Borders & Input Fill
  static const Color borderGrey = Color(0xFFEFE8DE);
  static const Color borderDark = Color(0xFF334155);
  static const Color inputBackground = Color(0xFFFFFFFF);
}
