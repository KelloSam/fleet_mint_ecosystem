class UserModel {
  final int id;
  final String name;
  final String email;
  final String username;
  final String role;
  final String? phone;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    this.phone,
    this.lastLoginAt,
  });

  String get staffId => 'STAFF-${id.toString().padLeft(4, '0')}';
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || isAdmin;
  bool get isCashier => role == 'cashier';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        username: json['username'] ?? '',
        role: json['role'] ?? 'cashier',
        phone: json['phone'],
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.tryParse(json['last_login_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'role': role,
        'phone': phone,
        'last_login_at': lastLoginAt?.toIso8601String(),
      };

  // Mock data for development/demo
  static List<UserModel> mockOnDutyStaff = [
    UserModel(
      id: 1, name: 'Chanda Mwewa', email: 'chanda@madithel.zm',
      username: 'chanda', role: 'admin', phone: '+260977001122',
      lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    UserModel(
      id: 2, name: 'Miriam Banda', email: 'miriam@madithel.zm',
      username: 'miriam', role: 'cashier', phone: '+260966334455',
      lastLoginAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    UserModel(
      id: 3, name: 'Joseph Tembo', email: 'joseph@madithel.zm',
      username: 'joseph', role: 'manager', phone: '+260955667788',
      lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
}
