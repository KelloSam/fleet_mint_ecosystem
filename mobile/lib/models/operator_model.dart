import 'package:flutter/material.dart';

class OperatorModel {
  final int id;
  final String name;
  final String slug;
  final String tagline;
  final String? phone;
  final String? email;
  final String brandColor;
  final bool active;
  final int? activeRoutesCount;

  const OperatorModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.tagline,
    this.phone,
    this.email,
    required this.brandColor,
    required this.active,
    this.activeRoutesCount,
  });

  Color get color {
    try {
      final hex = brandColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1565C0);
    }
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'B';

  factory OperatorModel.fromJson(Map<String, dynamic> json) => OperatorModel(
        id: json['id'],
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        tagline: json['tagline'] ?? '',
        phone: json['contact_phone'],
        email: json['contact_email'],
        brandColor: json['brand_color'] ?? '#1565C0',
        active: json['active'] ?? true,
        activeRoutesCount: json['active_routes_count'],
      );

  static List<OperatorModel> mock = [
    OperatorModel(id: 1, name: 'Power Tools Bus Services', slug: 'power_tools',
        tagline: 'Power Through Every Journey', phone: '+260977100200',
        email: 'info@powertools.zm', brandColor: '#E53935', active: true, activeRoutesCount: 5),
    OperatorModel(id: 2, name: 'Jordan Bus Services', slug: 'jordan',
        tagline: 'Your Journey, Our Priority', phone: '+260966200300',
        email: 'info@jordan.zm', brandColor: '#43A047', active: true, activeRoutesCount: 8),
    OperatorModel(id: 3, name: 'Likili Bus Services', slug: 'likili',
        tagline: 'Comfort Across Zambia', phone: '+260955300400',
        email: 'info@likili.zm', brandColor: '#7B1FA2', active: true, activeRoutesCount: 4),
    OperatorModel(id: 4, name: 'Rayon Bus Services', slug: 'rayon',
        tagline: 'Fast, Safe, Reliable', phone: '+260944400500',
        email: 'info@rayon.zm', brandColor: '#FB8C00', active: true, activeRoutesCount: 6),
    OperatorModel(id: 5, name: 'Oasis Bus Services', slug: 'oasis',
        tagline: 'Refreshing Travel Experience', phone: '+260933500600',
        email: 'info@oasis.zm', brandColor: '#00897B', active: true, activeRoutesCount: 3),
    OperatorModel(id: 6, name: 'Madithel Bus Services', slug: 'madithel',
        tagline: 'Pride of Zambia Roads', phone: '+260977654321',
        email: 'info@madithel.zm', brandColor: '#1565C0', active: true, activeRoutesCount: 7),
  ];
}
