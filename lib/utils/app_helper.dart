//
//  DNA Design System
//
//  Copyright (c) Advanced Human Imaging. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutterfirebase/utils/video_encoder.dart';
import 'package:uuid/uuid.dart';
import 'network_manager.dart';

class AppHelpers {
  /// A function that returns the Apps current build number and version from pubspec.yaml
  static Future<String> getAppBuildAndVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    return "Version_${version}_build_$buildNumber";
  }
  /// A function to get the file path to local system storage
  static Future<String> getFilePath(String fileName) async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;
    String filePath = '$appDocumentsPath/$fileName';
    return filePath;
  }
  /// Returns a <List<FileSystemEntity>> of all directory entities - Files, Videos, Images, etc 
  static Future<List<FileSystemEntity>> getDirectoryEntities() async {
    var dir = await getDir();
    List<FileSystemEntity> fileEntities = dir.listSync(recursive: true, followLinks: false);
    print("These are our fileEntities: $fileEntities");
    return fileEntities;
  }
  /// Returns the main document directory for local storage persistence
  static Future<Directory> getDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = directory.path;
    String allFilesDirectory = '$dir/';
    final appDirectory = Directory(allFilesDirectory);
    return appDirectory;
  }
  /// Recursively deletes all entities inside the main app directory
  static Future<void> deleteDirectoryEntities() async {
    var appDirectory = await getDir();
    // Check if app directory contains any entities before trying to delete
    var appDirectoryEntities = await getDirectoryEntities();
    if (appDirectory.existsSync() && appDirectoryEntities.isNotEmpty) {
      try {
        await appDirectory.delete(recursive: true);
      } catch (e) {
        print("EXCEPTION THROWN WHILE DELETING FILES: $e");
        return;
      }
      print("🔥🔥 - File Entities Deleted - 🔥🔥");
    }
  }
  /// Saves individual file as a string to local storage
  static void saveFile(dynamic fileToSave, String fileName) async {
    File file = File(await getFilePath(fileName));
    await file.writeAsString(fileToSave);
    return;
  }
  /// Saves individual file as a sequence of bytes to local storage
  static saveByteFile(dynamic fileToSave, String fileName) async {
    File file = File(await getFilePath(fileName));
    await file.writeAsBytes(fileToSave);
    print(file);
    return file;
  }

  /// A helper function that zips all file enitities inside the main app directory
  /// This function also takes a callback to track the progress of file zipping
  /// 
  /// The callback is called every 250ms with a new estimated progress value between 0 - 1
  /// The estimate can go over the value of 1 so be sure to cap your progress to 1 when displaying to the view
  static Future<File?> zipFiles(String zipFileName, callback) async {
    final directory = await getDir();
    final sourceDir = Directory(directory.path);
    final filesToZip = await getDirectoryEntities();
    final uuid = const Uuid().v4();
    final zipFile = File("${directory.path}/$zipFileName-$uuid.zip");
    var totalBytesPreCompression = 0;
    List<File> zipContentsArr = [];
    for (var entity in filesToZip) {
      if (entity is File && !entity.path.contains(".zip")) {
        zipContentsArr.add(File(entity.path));
        totalBytesPreCompression += await entity.length();
      }
      continue;
    }
    final files = [...zipContentsArr];
    try {
      var zipFileSize = 0;
      final timer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
        print("OLD: $zipFileSize NEW: ${await zipFile.length()}");
        zipFileSize = await zipFile.length();
        var percentComplete = (zipFileSize / (totalBytesPreCompression * 0.675));
        print(percentComplete);
        callback(percentComplete, "Zipping Progress", null);
      });
      await ZipFile.createFromFiles(sourceDir: sourceDir, files: files, zipFile: zipFile);
      timer.cancel();
      callback(0.0, "Zipping Progress", true);
      return zipFile;
    } catch (e) {
      print("Error Zipping Directory: $e");
      return null;
    }
  }

  /// Returns a File after taking a screenshot of the current viewport
  static Future? takeScreenshot(ScreenshotController screenshotController) {
    var file = screenshotController.capture(delay: const Duration(milliseconds: 10)).then((capturedImage) async {
      print("ls worlddd");
      var uuid = const Uuid().v4();
      var file = await AppHelpers.saveByteFile(capturedImage, "screenshot-$uuid.png");
      print("This is file: $file");
      return file;
    }).catchError((onError) {
      print(onError);
      return;
    });
    return file;
  }

  /// Return all images with the extension '.png' and '.jpg' from the main app directory
  static Future? getImagesFromEntities(List<FileSystemEntity> entities) async {
    List<Widget> localArr = [];
    var iter = entities;
    for (var entity in iter) {
      if (entity is File && entity.path.contains('.png') || entity is File && entity.path.contains('.jpg')) {
        try {
          localArr.add(
            Image.file(
              File(entity.path),
            ),
          );
        } catch (e) {
          print("Error loading in file: $e");
        }
      }
    }
    return localArr;
  }

  /// Future method used to wait for 'X' amount of seconds before continuing
  static Future<void> waitForXSeconds(int seconds) async {
    await Future.delayed(Duration(seconds: seconds));
    return;
  }

  /// Helper function to start the stopwatch timer & make sure the stopwatch has not started
  static startTimer(String eventName, BuildContext context, Stopwatch stopwatch) {
    if (stopwatch.elapsedMilliseconds <= 0) {
      stopwatch.start();
      NetworkManager.sendAnalyticsEvent(eventName, context);
    }
  }

  /// Function to pick videos from the phone media gallery
  /// Once a video is selected, the video is encoded to '.mp4' format and saved to local storage
  static Future<void> pickVideoFromGallery(setEncoding) async {
    final ImagePicker _picker = ImagePicker();
    _picker.pickVideo(source: ImageSource.gallery).then((value) async => {await EncodingProvider.encodeVideo(value?.path, setEncoding)});
  }
}
