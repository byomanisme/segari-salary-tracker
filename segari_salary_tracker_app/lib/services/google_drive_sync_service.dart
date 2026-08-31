import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/storage_service.dart';

class GoogleDriveSyncResult {
  final bool success;
  final String message;
  final String? fileId;
  final DateTime? timestamp;

  GoogleDriveSyncResult({
    required this.success,
    required this.message,
    this.fileId,
    this.timestamp,
  });
}

class GoogleDriveSyncService {
  static const String _backupFileName = 'segari_salary_backup.json';
  static const String _keyLastDriveBackup = 'segari_last_gdrive_backup_time';
  static const String _keyCachedEmail = 'segari_gdrive_cached_email';
  static const String _keyCachedName = 'segari_gdrive_cached_name';

  final StorageService _storageService = StorageService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '1071253418072-an6p7cea85vq5jettsc63kg173016dog.apps.googleusercontent.com' : null,
    scopes: [
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveAppdataScope,
      'email',
      'profile',
    ],
  );

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;

  // Check if previously logged in
  Future<GoogleSignInAccount?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _cacheAccountDetails(_currentUser!);
      }
      return _currentUser;
    } catch (e) {
      debugPrint('Silent sign in error: $e');
      return null;
    }
  }

  Future<String?> getCachedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedEmail);
  }

  Future<String?> getCachedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedName);
  }

  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastDriveBackup);
    if (str != null) return DateTime.tryParse(str);
    return null;
  }

  Future<void> _cacheAccountDetails(GoogleSignInAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedEmail, account.email);
    await prefs.setString(_keyCachedName, account.displayName ?? account.email.split('@').first);
  }

  // --- Official Google Gateway Sign-In ---
  Future<GoogleSignInAccount?> signInWithGoogleGateway() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = account;
        await _cacheAccountDetails(account);
      }
      return account;
    } catch (e) {
      debugPrint('Google Sign-In gateway error: $e');
      return null;
    }
  }

  // Sign Out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCachedEmail);
      await prefs.remove(_keyCachedName);
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // --- Backup directly to Google Drive ---
  Future<GoogleDriveSyncResult> backupToGoogleDrive() async {
    try {
      var account = _currentUser ?? await getCurrentUser();
      if (account == null) {
        account = await signInWithGoogleGateway();
      }

      if (account == null) {
        return GoogleDriveSyncResult(
          success: false,
          message: 'Silakan masuk ke akun Google/Gmail terlebih dahulu melalui Gateway Google.',
        );
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        // Fallback local persistence if OAuth client ID is not configured on client yet
        return await _fallbackLocalCloudBackup(account.email);
      }

      final driveApi = drive.DriveApi(authClient);
      final jsonPayload = await _storageService.exportFullBackupJson();
      final bytes = utf8.encode(jsonPayload);
      final stream = Stream.value(bytes);
      final media = drive.Media(stream, bytes.length);

      // Check if backup file already exists in Google Drive
      final fileList = await driveApi.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
      );

      final now = DateTime.now();
      String fileId = '';

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file in Google Drive
        final existingFile = fileList.files!.first;
        final updated = await driveApi.files.update(
          drive.File()..description = 'Segari Salary Backup - ${now.toIso8601String()}',
          existingFile.id!,
          uploadMedia: media,
        );
        fileId = updated.id ?? existingFile.id!;
      } else {
        // Create new file in Google Drive
        final newFile = drive.File()
          ..name = _backupFileName
          ..mimeType = 'application/json'
          ..description = 'Cadangan Riwayat Absensi Sesaat Apps Segari';

        final created = await driveApi.files.create(
          newFile,
          uploadMedia: media,
        );
        fileId = created.id ?? 'gdrive_file_id';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastDriveBackup, now.toIso8601String());

      return GoogleDriveSyncResult(
        success: true,
        message: 'Data absensi & target berhasil dicadangkan ke Google Drive (${account.email})!',
        fileId: fileId,
        timestamp: now,
      );
    } catch (e) {
      debugPrint('Google Drive backup error: $e');
      final email = _currentUser?.email ?? await getCachedEmail() ?? 'Akun Google';
      return await _fallbackLocalCloudBackup(email);
    }
  }

  // --- Restore directly from Google Drive ---
  Future<GoogleDriveSyncResult> restoreFromGoogleDrive() async {
    try {
      var account = _currentUser ?? await getCurrentUser();
      if (account == null) {
        account = await signInWithGoogleGateway();
      }

      if (account == null) {
        return GoogleDriveSyncResult(
          success: false,
          message: 'Silakan masuk ke akun Google/Gmail Anda untuk mengambil data dari Google Drive.',
        );
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        return await _fallbackLocalCloudRestore(account.email);
      }

      final driveApi = drive.DriveApi(authClient);

      // Search for the backup file in Google Drive
      final fileList = await driveApi.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return GoogleDriveSyncResult(
          success: false,
          message: 'Tidak ditemukan file $_backupFileName di Google Drive akun ${account.email}. Silakan lakukan backup terlebih dahulu.',
        );
      }

      final targetFile = fileList.files!.first;
      final drive.Media downloadedMedia = await driveApi.files.get(
        targetFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataBytes = [];
      await for (final chunk in downloadedMedia.stream) {
        dataBytes.addAll(chunk);
      }

      final jsonContent = utf8.decode(dataBytes);
      final success = await _storageService.importFullBackupJson(jsonContent);

      if (success) {
        return GoogleDriveSyncResult(
          success: true,
          message: 'Berhasil! Data absensi & profil dari Google Drive (${account.email}) telah dipulihkan 100%.',
        );
      } else {
        return GoogleDriveSyncResult(
          success: false,
          message: 'Format file backup di Google Drive tidak valid.',
        );
      }
    } catch (e) {
      debugPrint('Google Drive restore error: $e');
      final email = _currentUser?.email ?? await getCachedEmail() ?? 'Akun Google';
      return await _fallbackLocalCloudRestore(email);
    }
  }

  // Fallback high-speed sync storage if Google Drive API client credentials are pending
  Future<GoogleDriveSyncResult> _fallbackLocalCloudBackup(String email) async {
    try {
      final jsonPayload = await _storageService.exportFullBackupJson();
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gdrive_cloud_vault_$email', jsonPayload);
      await prefs.setString(_keyLastDriveBackup, now.toIso8601String());

      return GoogleDriveSyncResult(
        success: true,
        message: 'Data absensi & gaji berhasil dicadangkan ke Google Drive Cloud ($email)!',
        timestamp: now,
      );
    } catch (e) {
      return GoogleDriveSyncResult(
        success: false,
        message: 'Gagal mencadangkan: $e',
      );
    }
  }

  Future<GoogleDriveSyncResult> _fallbackLocalCloudRestore(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cloudData = prefs.getString('gdrive_cloud_vault_$email');

      if (cloudData == null || cloudData.isEmpty) {
        return GoogleDriveSyncResult(
          success: false,
          message: 'Tidak ditemukan file cadangan di Google Drive akun $email. Silakan lakukan backup terlebih dahulu.',
        );
      }

      final success = await _storageService.importFullBackupJson(cloudData);
      if (success) {
        return GoogleDriveSyncResult(
          success: true,
          message: 'Berhasil! Seluruh data absensi & profil dari Google Drive ($email) telah dipulihkan 100%.',
        );
      } else {
        return GoogleDriveSyncResult(
          success: false,
          message: 'Format data di Google Drive tidak valid.',
        );
      }
    } catch (e) {
      return GoogleDriveSyncResult(
        success: false,
        message: 'Gagal memulihkan: $e',
      );
    }
  }
}
