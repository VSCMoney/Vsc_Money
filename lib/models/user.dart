// class UserModel {
//   final String uid;
//   final String? username;
//   final String? phone;
//   final String? email;
//   final String? name;
//   final List<String> brokerIds;
//   final List<String> assets;
//   final List<String> goals;
//   final List<String> watchlists;
//
//   UserModel({
//     required this.uid,
//     this.username,
//     this.phone,
//     this.email,
//     this.name,
//     this.brokerIds = const [],
//     this.assets = const [],
//     this.goals = const [],
//     this.watchlists = const [],
//   });
//
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       uid: json['uid'],
//       username: json['username'],
//       phone: json['phone'],
//       email: json['email'],
//       name: json['name'],
//       brokerIds: List<String>.from(json['broker_ids'] ?? []),
//       assets: List<String>.from(json['assets'] ?? []),
//       goals: List<String>.from(json['goals'] ?? []),
//       watchlists: List<String>.from(json['watchlists'] ?? []),
//     );
//   }
// }







class UserModel {
  final String uid;
   String? phone;
   String? email;
   String? name;
   String? username;
  final List<dynamic> brokerIds;
  final List<dynamic> assets;
  final List<dynamic> goals;
  final List<dynamic> watchlists;

   String? firstName;
   String? lastName;

  UserModel({
    required this.uid,
    this.phone,
    this.email,
    this.name,
    this.username,
    this.brokerIds = const [],
    this.assets = const [],
    this.goals = const [],
    this.watchlists = const [],
    this.firstName, // 👈 ADD THIS
    this.lastName,  // 👈 ADD THIS
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      phone: json['phone'],
      email: json['email'],
      name: json['name'],
      username: json['username'],
      brokerIds: json['broker_ids'] ?? [],
      assets: json['assets'] ?? [],
      goals: json['goals'] ?? [],
      watchlists: json['watchlists'] ?? [],
      firstName: json['first_name'], // 👈 ADD THIS
      lastName: json['last_name'],   // 👈 ADD THIS
    );
  }
}
