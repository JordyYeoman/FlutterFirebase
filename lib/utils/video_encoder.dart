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
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/media_information_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/session.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:flutterfirebase/utils/app_helper.dart';
import 'package:uuid/uuid.dart';

class EncodingProvider {
  /// Future method to cancel any encoding sessions currently running
  Future<void> cancelVideoEncoding() async {
    // Stop all sessions
    FFmpegKit.cancel();
  }
  // Used for grabbing all information about the media, such as duration and size
  static Future<MediaInformationSession> getMediaInformation(String path) async {
    return await FFprobeKit.getMediaInformation(path);
  }
  /// Encodes videos and provides a callback to monitor progress
  static Future<String?> encodeVideo(videoPath, setEncoding) async {
    setEncoding(0.00001, "Encoding Video", null);
    String encodedVideoPath = '$videoPath.mp4';
    final Directory docDirectory = await AppHelpers.getDir();
    bool encodingSuccess = false;
    if (videoPath == null) {
      return "No video passed in";
    }
    final info = await EncodingProvider.getMediaInformation(videoPath);
    final streamData = info.getMediaInformation()?.getAllProperties();
    final mediaInformation = streamData?['format'];
    final videoDuration = await mediaInformation?['duration'];
    String uuid = const Uuid().v4();
    FFmpegKit.executeAsync('-i $videoPath -c:v mpeg4 $encodedVideoPath', (Session session) {}, (Log log) {}, (Statistics statistics) {
      var time = statistics.getTime() / 1000;
      var duration = double.parse(videoDuration);
      var progressCalc = time / duration;
      var progressAmount = progressCalc > 98 ? 100 : progressCalc;
      setEncoding(progressAmount, "Encoding Video", null);
    });
    /// This method enables us to continue observing progress for the current encoding session
    FFmpegKitConfig.enableFFmpegSessionCompleteCallback((session) async {
      var returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        await File(encodedVideoPath).rename('${docDirectory.path}${uuid}.mp4');
        encodedVideoPath = '${docDirectory.path}${uuid}.mp4';
        setEncoding(0.0, "Encoding Video", true);
        encodingSuccess = true;
      } else if (ReturnCode.isCancel(returnCode)) {
        print("Encoding cancelled");
      } else {
        print("Error while encoding....");
      }
      print('RETURN CODE: $returnCode');
    });

    if (encodingSuccess) {
      return encodedVideoPath;
    }
    return null;
  }
}
