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

import 'package:flutter/material.dart';
import 'package:flutterfirebase/utils/auth_helper.dart';
import 'package:flutterfirebase/views/home_view.dart';
import 'package:flutterfirebase/views/layout/layout_view.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailField = TextEditingController();
  final TextEditingController _passwordField = TextEditingController();
  bool isLoading = false;
  bool isObscured = true;

  toggleLoadingState(loading) {
    setState(() {
      isLoading = loading;
    });
  }

  toggleObscuredText() {
    setState(() {
      isObscured = !isObscured;
    });
  }

  Future<void> _sendAnalyticsUserLoginEvent() async {
    FirebaseAnalytics analytics = Provider.of<FirebaseAnalytics>(context, listen: false);
    await analytics.logLogin();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Login"),
          TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Email',
              ),
              // focusNode: FocusNode(),
              maxLines: 1,
              controller: _emailField),
          TextField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Password',
              prefixIcon: InkWell(
                child: Icon(Icons.remove_red_eye_rounded, color: isObscured ? const Color(0xFFFF4081) : const Color(0xFF000000)),
                onTap: () => {toggleObscuredText()},
              ),
            ),
            // focusNode: FocusNode(),
            maxLines: 1,
            controller: _passwordField,
            obscureText: true,
          ),
          MaterialButton(
            child: const Text("Sign In"),
            onPressed: () async {
              toggleLoadingState(true);
              bool shouldNavigate = await AuthHelper.signIn(_emailField.text, _passwordField.text);
              _sendAnalyticsUserLoginEvent();
              toggleLoadingState(false);
              if (shouldNavigate) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeView(),
                  ),
                );
              }
            },
          ),
          MaterialButton(
            child: const Text("Register"),
            onPressed: () async {
              toggleLoadingState(true);
              bool shouldNavigate = await AuthHelper.register(_emailField.text, _passwordField.text);
              toggleLoadingState(false);
              if (shouldNavigate) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeView(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
