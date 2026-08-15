import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication authData = await account.authentication;
      final accessToken = authData.accessToken;
      if (accessToken == null) return null;

      final authenticateClient = GoogleAuthClient({'Authorization': 'Bearer $accessToken'});
      return drive.DriveApi(authenticateClient);
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      return null;
    }
  }

  Future<String?> _getOrCreateToolHubFolder(drive.DriveApi driveApi) async {
    try {
      final drive.FileList fileList = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and name='ToolHub Scans' and trashed=false",
        spaces: 'drive',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      final drive.File folder = drive.File()
        ..name = 'ToolHub Scans'
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      debugPrint('Error finding/creating folder: $e');
      return null;
    }
  }

  Future<bool> uploadPdf(File pdfFile, String fileName) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final folderId = await _getOrCreateToolHubFolder(driveApi);
      
      final drive.File driveFile = drive.File()
        ..name = fileName
        ..parents = folderId != null ? [folderId] : null;

      final media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());
      
      await driveApi.files.create(driveFile, uploadMedia: media);
      return true;
    } catch (e) {
      debugPrint('Upload Error: $e');
      return false;
    }
  }
}
