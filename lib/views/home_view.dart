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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'home_view.dart';
import 'package:flutterfirebase/views/layout/layout_view.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isLoading = false;
  final stopwatch = Stopwatch();

  void toggleLoadingState(loading) {
    setState(() {
      isLoading = loading;
    });
  }

  // Future<void> logTimeSpentOnHomeView(BuildContext context, Stopwatch stopwatch) async {
  //   stopwatch.stop();
  //   // NetworkManager.sendTimeSpentAnalyticsEvent("TimeSpent_HomeView", context, stopwatch);
  // }

  @override
  Widget build(BuildContext context) {
    // AppHelpers.startTimer("CircleFit_Started", context, stopwatch);
    return LayoutView(
      child: ListView(
        children: [
          Text("Home view welcome"),
          Text("Welcome big dog: ${FirebaseAuth.instance.currentUser?.email}"),
          Text("Welcome big dog: ${FirebaseAuth.instance.currentUser?.displayName}")
          ],
      ),
    );
  }
}
