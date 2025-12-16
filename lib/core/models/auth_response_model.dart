import 'user_model.dart';

class AuthResponseModel {
  final UserModel user;
  final String accessToken;

  AuthResponseModel({
    required this.user,
    required this.accessToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['acces_token'] as String, // API tiene typo "acces_token"
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'acces_token': accessToken,
    };
  }
}
