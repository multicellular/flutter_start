class User {
  final String uremark;
  final String uavator;
  final String uname;
  final String ubio;
  final int uid;
  User({this.uavator, this.uremark, this.ubio, this.uname, this.uid});

  User.fromJson(Map<String, dynamic> json)
      : uid = json['uid'],
        uname = json['uname'],
        uavator = json['uavator'] ?? '',
        uremark = json['uremark'] ?? '',
        ubio = json['ubio'] ?? '';

  User filterUser(int uid, List users) {
    return User.fromJson(users.firstWhere((user) => uid == user['uid']));
  }
}
