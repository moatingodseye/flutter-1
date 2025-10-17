//import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
//import 'package:jwt/jwt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const _jwtSecret = String.fromEnvironment('JWT_SECRET', defaultValue: 'change_this_secret_in_production');

/// Hash password using bcrypt
String hashPassword(String plain) => BCrypt.hashpw(plain, BCrypt.gensalt());

/// Verify password using bcrypt
bool verifyPassword(String plain, String hash) => BCrypt.checkpw(plain, hash);

/// Generate JWT using dart_jsonwebtoken
String generateJwt(Map<String, dynamic> claims) {
  final jwt = JWT(claims);
  final token = jwt.sign(SecretKey(_jwtSecret));
  return token;
}

/// Verify and decode JWT using dart_jsonwebtoken
Map<String, dynamic> verifyJwt(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    return jwt.payload;
  } on JWTExpiredException {
    throw Exception('JWT has expired');
  } on JWTException catch (e) {
    // covers other JWT errors like invalid token, parsing, undefined, etc.
    throw Exception('JWT verification failed: ${e.message}');
  }
}