class Role {
  final int id;
  final String name;
  final String description;
  final bool isDefault;
  final String createdAt;

  Role({
    required this.id,
    required this.name,
    required this.description,
    required this.isDefault,
    required this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class Permission {
  final int id;
  final String key;
  final String name;
  final String description;
  final String createdAt;

  Permission({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
        id: (json['id'] as num?)?.toInt() ?? 0,
        key: json['key']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class Admin {
  final int id;
  final String name;
  final String email;
  final String contactNo;
  final String createdAt;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.contactNo,
    required this.createdAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) => Admin(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        contactNo: json['contactNo']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class Profile {
  final int id;
  final String name;
  final String email;
  final String contactNo;
  final String createdAt;
  final List<String> roles;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.contactNo,
    required this.createdAt,
    required this.roles,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        contactNo: json['contactNo']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
