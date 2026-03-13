class UserModel {

  final String uid;
  final String email;
  final String name;
  final String? photo;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photo,
  });

  factory UserModel.fromJson(Map<String,dynamic> json) {

    return UserModel(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      photo: json['photo'],
    );
  }

  Map<String,dynamic> toJson(){

    return{
      "uid":uid,
      "email":email,
      "name":name,
      "photo":photo
    };
  }
}