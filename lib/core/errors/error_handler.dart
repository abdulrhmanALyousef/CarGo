import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handle(Object error, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[ErrorHandler]${tag != null ? ' [$tag]' : ''} $error');
    }

    if (error is AppException) return error;

    if (error is FirebaseAuthException) {
      return AppException(
        _mapAuthCode(error.code),
        debugMessage: '${error.code}: ${error.message}',
      );
    }

    if (error is FirebaseException) {
      return AppException(
        _mapFirebaseCode(error.code),
        debugMessage: '[${error.code}]: ${error.message}',
      );
    }

    if (error is FirebaseFunctionsException) {
      return AppException(
        _mapFunctionsError(error.code, error.message),
        debugMessage: '[${error.code}]: ${error.message}',
      );
    }

    final msg = error.toString().toLowerCase();
    if (msg.contains('insufficient')) {
      return const AppException('Insufficient balance to complete this action.');
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection refused') ||
        msg.contains('failed host lookup')) {
      return const AppException('No internet connection. Please try again.');
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return const AppException('Request timed out. Please try again.');
    }

    return const AppException('Something went wrong. Please try again.');
  }

  static String _mapAuthCode(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'Verification session expired. Please request a new code.';
      case 'requires-recent-login':
        return 'Please log out and log back in to complete this action.';
      case 'operation-not-allowed':
        return 'This sign-in method is not available.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  static String _mapFirebaseCode(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'The requested data could not be found.';
      case 'already-exists':
        return 'This record already exists.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'deadline-exceeded':
      case 'cancelled':
        return 'Request timed out. Please try again.';
      case 'storage/unauthorized':
        return 'You do not have permission to upload files.';
      case 'storage/canceled':
        return 'Upload was cancelled.';
      case 'storage/unknown':
        return 'Upload failed. Please try again.';
      case 'storage/object-not-found':
        return 'File not found. Please try again.';
      case 'storage/retry-limit-exceeded':
        return 'Upload failed. Please check your connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String _mapFunctionsError(String code, String? message) {
    // Cloud Function messages set by our own functions are already user-friendly.
    // Pass them through unless they look technical.
    if (message != null && message.isNotEmpty && !_looksLikeCode(message)) {
      return message;
    }

    switch (code) {
      case 'not-found':
        return 'The requested resource could not be found.';
      case 'already-exists':
        return 'This record already exists.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'invalid-argument':
        return 'Invalid input. Please check your details and try again.';
      case 'internal':
        return 'An error occurred. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static bool _looksLikeCode(String message) {
    final lower = message.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('firebase') ||
        lower.contains('firestore') ||
        lower.contains('null') ||
        lower.contains('stack trace') ||
        lower.contains('[error') ||
        message.contains(RegExp(r'\[.+\]')); // e.g. [permission-denied]
  }
}
