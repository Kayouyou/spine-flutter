/// Demo user model
class DemoUser {
  final String id;
  final String name;
  final String email;

  const DemoUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory DemoUser.fromJson(Map<String, dynamic> json) => DemoUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
  };
}
