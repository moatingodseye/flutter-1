import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:jwt/jwt.dart';

const _jwtSecret = String.fromEnvironment('JWT_SECRET', defaultValue: 'change_this_secret_in_production');

String hashPassword(String plain) => BCrypt.hashpw(plain, BCrypt.gensalt());

bool verifyPassword(String plain, String hash) => BCrypt.checkpw(plain, hash);

String generateJwt(Map<String, dynamic> claims) {
  final token = JwtEncoder.encode(claims, _jwtSecret);
  return token;
}

Map<String, dynamic> verifyJwt(String token) {
  final decoded = JwtDecoder.decode(token, _jwtSecret);
  return decoded;
}
