class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'manager' أو 'employee'
  final String department;
  final String status; // 'active' أو 'inactive'

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.status,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'employee',
      department: map['department'] ?? 'عام',
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department,
      'status': status,
    };
  }
}