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

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:core';
import 'package:flutterfirebase/utils/app_helper.dart';
import 'package:uuid/uuid.dart';

class NetworkManager {
  // We need to pass in the current BuildContext for the view that is calling this function
  static Future<void> sendAnalyticsEvent(String eventName, BuildContext context) async {
    FirebaseAnalytics analytics = Provider.of<FirebaseAnalytics>(context, listen: false);
    await analytics.logEvent(
      name: eventName,
      parameters: <String, dynamic>{
        'email': FirebaseAuth.instance.currentUser?.email,
        'uuid': FirebaseAuth.instance.currentUser?.uid,
      },
    );
    print('${eventName} logged successfully.');
  }
  // Used to log time spent on each required view. 
  // Seperate to standard analytics event as we also pass in the stopwatch instance
  static Future<void> sendTimeSpentAnalyticsEvent(String eventName, BuildContext context, stopwatch) async {
    FirebaseAnalytics analytics = Provider.of<FirebaseAnalytics>(context, listen: false);
    await analytics.logEvent(
      name: eventName,
      parameters: <String, dynamic>{
        'timeElapsed': stopwatch.elapsedMilliseconds,
        'email': FirebaseAuth.instance.currentUser?.email,
        'uuid': FirebaseAuth.instance.currentUser?.uid,
      },
    );
    print('${eventName} logged successfully.');
  }

  static Future<firebase_storage.ListResult> listAllFilesAndDirectoriesInStorage() async {
    firebase_storage.ListResult result = await firebase_storage.FirebaseStorage.instance.ref().listAll();
    result.items.forEach((firebase_storage.Reference ref) {
      print('Found file: $ref');
    });
    result.prefixes.forEach((firebase_storage.Reference ref) {
      print('Found directory: $ref');
    });
    return result;
  }

  static Future<void> listTenRecentFiles() async {
    firebase_storage.ListResult result = await firebase_storage.FirebaseStorage.instance.ref().list(const firebase_storage.ListOptions(maxResults: 10));
    if (result.nextPageToken != null) {
      firebase_storage.ListResult additionalResults = await firebase_storage.FirebaseStorage.instance.ref().list(firebase_storage.ListOptions(
            maxResults: 10,
            pageToken: result.nextPageToken,
          ));
      additionalResults.items.forEach((firebase_storage.Reference ref) {
        print('Found file: $ref');
      });
      additionalResults.prefixes.forEach((firebase_storage.Reference ref) {
        print('Found directory: $ref');
      });
    }
    result.items.forEach((firebase_storage.Reference ref) {
      print('Found file: $ref');
    });
    result.prefixes.forEach((firebase_storage.Reference ref) {
      print('Found directory: $ref');
    });
  }

  Future<Object> uploadFile(String filePath) async {
    File file = File(filePath);
    var uuid = const Uuid().v4();
    var userId = FirebaseAuth.instance.currentUser?.uid;
    String appPlatform = Platform.isIOS ? "IOS" : "Android";
    String appDetails = await AppHelpers.getAppBuildAndVersion();
    try {
      await firebase_storage.FirebaseStorage.instance.ref('${appPlatform}_${appDetails}/${userId}/${uuid}.zip').putFile(file);
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'canceled') {
        print("User cancelled upload, please try again");
        return e;
      }
      if (e.code == 'permission-denied') {
        print('User does not have permission to upload to this reference.');
        return e;
      }
      print("Error code: ${e.code}");
      return e;
    }
  }

  // Pick Image/Video from device and upload to Firebase Storage
  Future<void> uploadFileFromDevice() async {
    _pickFileFromDevice().then((value) async {
      if (value != null) {
        return await uploadFile(value);
      }
      return e;
    });
  }

  // This function here as it should only be called from within the uploadFileFromDevice() function.
  Future<String?> _pickFileFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpeg', 'png', 'jpg', 'mov', 'hevc', 'avi', 'mp4'],
    );
    if (result == null) {
      return null;
    }
    return result.files.single.path;
  }

  static Future<void> writeDataToFireStore(String taskAllocated, String timeSpentOnView, {double? age, double? weight = 0, double? height}) async {
    // Are collections auto generated when writing to firestore?
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    User? loggedInUser = FirebaseAuth.instance.currentUser;
    String? userEmail = loggedInUser?.email ?? "No Email Provided";
    print("LoggedinUser: ${loggedInUser?.email}");

    // Once we have the collection - write the data to it related to a specific user
    return users
        .add({'age': age ?? 0, 'timeSpent': timeSpentOnView, 'taskAllocated': taskAllocated, 'email': userEmail, 'weight': weight ?? 0, 'height': height ?? 0})
        .then((value) => print("Data point added"))
        .catchError((error) => print("Failed to add dataPoint: $error"));
  }

}
