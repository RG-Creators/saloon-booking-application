import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "../config.dart";

class RemoteConfig {
  static String? apiBaseUrl;
  static String? apiSecret;
  static String? appLogoUrl;

  // Maintenance Mode Fields & State Tracker
  static bool isMaintenance = false;
  static bool isOnMaintenanceScreen = false;
  static final ValueNotifier<bool> maintenanceNotifier = ValueNotifier<bool>(false);
  static void Function(bool inMaintenance)? onMaintenanceModeChanged;

  static String maintenanceTitle = "System Maintenance Underway";
  static String maintenanceMessage = "We are currently performing scheduled maintenance to enhance system performance. Please check back shortly.";
  static String maintenanceEta = "";

  static Map<String, dynamic> theme = {
    "primary_color": "#4F46E5",
    "font_family": "Poppins",
    "button_border_radius": 14.0,
    "show_revenue_card": true,
    "app_logo": null,
  };
  
  static Map<String, dynamic> features = {
    "enable_offline_mode": true,
    "enable_booking_chat": false,
    "enable_billing": true,
  };

  static Future<void> fetchConfig() async {
    final endpoints = <String>[
      "${AppConfig.defaultBaseUrl}/app-config",
      "https://bookingsaas.visticafeandrestaurant.com/api/v1/app-config",
    ];

    for (final url in endpoints) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["success"] == true) {
            final configData = data["data"] ?? {};
            
            if (configData["theme"] != null) {
              theme = configData["theme"];
              appLogoUrl = configData["theme"]["app_logo"];
            }
            if (configData["features"] != null) {
              features = configData["features"];
            }
            if (configData["api_config"] != null) {
              final remoteBase = configData["api_config"]["api_base_url"];
              // If fetching from local IP, preserve local IP to prevent production redirection
              if (remoteBase != null && remoteBase.toString().isNotEmpty && !url.contains(AppConfig.serverIp)) {
                apiBaseUrl = remoteBase;
              }
              apiSecret = configData["api_config"]["api_secret"];
            }
            if (configData["maintenance"] != null) {
              final maint = configData["maintenance"];
              final bool newMaint = maint["enabled"] == true;
              isMaintenance = newMaint;
              maintenanceTitle = maint["title"] ?? "System Maintenance Underway";
              maintenanceMessage = maint["message"] ?? "We are currently performing scheduled maintenance. Please check back shortly.";
              maintenanceEta = maint["eta"] ?? "";
              maintenanceNotifier.value = isMaintenance;

              onMaintenanceModeChanged?.call(isMaintenance);
            }

            debugPrint('🚀 [RemoteConfig] Config synced successfully from $url! Maintenance: $isMaintenance (ETA: $maintenanceEta)');
            return;
          }
        }
      } catch (_) {
        // Silently skip to next endpoint if primary fails
      }
    }
  }

  static Color get primaryColor {
    String hex = theme["primary_color"] ?? "#4F46E5";
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }

  static String get fontFamily => theme["font_family"] ?? "Poppins";
  static double get buttonRadius => (theme["button_border_radius"] ?? 14).toDouble();
  static bool get showRevenueCard => theme["show_revenue_card"] ?? true;
}
