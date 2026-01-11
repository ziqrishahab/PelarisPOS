// User model
class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final String? cabangId; // Store cabangId for fallback
  final Cabang? cabang;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
    this.cabangId,
    this.cabang,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'KASIR',
      isActive: json['isActive'] ?? true,
      cabangId: json['cabangId'], // Save cabangId directly
      cabang: json['cabang'] != null ? Cabang.fromJson(json['cabang']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'cabangId': cabangId,
      'cabang': cabang?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isOwner => role == 'OWNER';
  bool get isManager => role == 'MANAGER';
  bool get isAdmin => role == 'ADMIN';
  bool get isKasir => role == 'KASIR';
  bool get isOwnerOrManager => isOwner || isManager;
}

// Cabang model
class Cabang {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;

  Cabang({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
  });

  factory Cabang.fromJson(Map<String, dynamic> json) {
    return Cabang(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'isActive': isActive,
    };
  }
}

// Auth response
class AuthResponse {
  final String message;
  final User user;
  final String token;

  AuthResponse({
    required this.message,
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] ?? '',
      user: User.fromJson(json['user']),
      token: json['token'] ?? '',
    );
  }
}
