import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/model/repository/user_2fa_repository.dart';
import 'package:mamapola_app_v1/model/entities/user_2fa_config.dart';
import 'dart:math';

class User2FAState {
  final bool isLoading;
  final User2FAConfig? user2FAConfig;
  final String? qrCodeUrl;
  final List<String>? backupCodes;
  final String? error;
  final bool is2FAEnabled;
  final bool isVerifying;

  const User2FAState({
    this.isLoading = false,
    this.user2FAConfig,
    this.qrCodeUrl,
    this.backupCodes,
    this.error,
    this.is2FAEnabled = false,
    this.isVerifying = false,
  });

  User2FAState copyWith({
    bool? isLoading,
    User2FAConfig? user2FAConfig,
    String? qrCodeUrl,
    List<String>? backupCodes,
    String? error,
    bool? is2FAEnabled,
    bool? isVerifying,
  }) {
    return User2FAState(
      isLoading: isLoading ?? this.isLoading,
      user2FAConfig: user2FAConfig ?? this.user2FAConfig,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      backupCodes: backupCodes ?? this.backupCodes,
      error: error,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }
}

final user2FAControllerProvider = StateNotifierProvider<User2FAController, User2FAState>((ref) {
  return User2FAController(User2FARepository());
});

class User2FAController extends StateNotifier<User2FAState> {
  final User2FARepository _2faRepository;

  User2FAController(this._2faRepository)
      : super(const User2FAState());

  Future<void> loadUser2FAConfig(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final config = await _2faRepository.getUser2FAConfig(userId);
      state = state.copyWith(
        isLoading: false,
        user2FAConfig: config,
        is2FAEnabled: config?.isEnabled ?? false,
        backupCodes: config?.backupCodes,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> enable2FA(String userId, String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Generar clave secreta
      final secretKey = _generateSecretKey();
      
      // Generar códigos de respaldo
      final backupCodes = _generateBackupCodes();
      
      // Crear URL del QR code
      final qrCodeUrl = _generateQRCodeUrl(email, secretKey);
      
      // Habilitar 2FA en la base de datos
      await _2faRepository.enable2FA(userId, secretKey, backupCodes);
      
      state = state.copyWith(
        isLoading: false,
        qrCodeUrl: qrCodeUrl,
        backupCodes: backupCodes,
        is2FAEnabled: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> disable2FA(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _2faRepository.disable2FA(userId);
      state = state.copyWith(
        isLoading: false,
        is2FAEnabled: false,
        user2FAConfig: null,
        qrCodeUrl: null,
        backupCodes: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> verifyBackupCode(String userId, String backupCode) async {
    state = state.copyWith(isVerifying: true, error: null);
    try {
      final isValid = await _2faRepository.verifyBackupCode(userId, backupCode);
      
      if (isValid) {
        // Remover el código usado
        await _2faRepository.removeBackupCode(userId, backupCode);
      }
      
      state = state.copyWith(isVerifying: false);
      return isValid;
    } catch (e) {
      state = state.copyWith(isVerifying: false, error: e.toString());
      return false;
    }
  }

  Future<List<String>> generateNewBackupCodes(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newCodes = await _2faRepository.generateNewBackupCodes(userId);
      state = state.copyWith(
        isLoading: false,
        backupCodes: newCodes,
      );
      return newCodes;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }

  String _generateSecretKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  List<String> _generateBackupCodes() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random.secure();
    final codes = <String>[];
    
    for (int i = 0; i < 10; i++) {
      String code = '';
      for (int j = 0; j < 8; j++) {
        code += chars[random.nextInt(chars.length)];
      }
      codes.add(code);
    }
    
    return codes;
  }

  String _generateQRCodeUrl(String email, String secretKey) {
    final issuer = 'MamaPola App';
    final accountName = email;
    
    // Formato: otpauth://totp/Issuer:AccountName?secret=SECRET&issuer=Issuer
    return 'otpauth://totp/${Uri.encodeComponent(issuer)}:${Uri.encodeComponent(accountName)}'
           '?secret=$secretKey'
           '&issuer=${Uri.encodeComponent(issuer)}'
           '&algorithm=SHA1'
           '&digits=6'
           '&period=30';
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearQRCode() {
    state = state.copyWith(qrCodeUrl: null);
  }

  void clearBackupCodes() {
    state = state.copyWith(backupCodes: null);
  }

  bool get hasBackupCodes => state.backupCodes != null && state.backupCodes!.isNotEmpty;
  
  int get remainingBackupCodes => state.backupCodes?.length ?? 0;
} 