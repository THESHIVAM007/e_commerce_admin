import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_admin/homescreen.dart';
import 'package:e_commerce_admin/screens/loginpage.dart';
import 'package:e_commerce_admin/screens/otpscreen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthRepo {
  static String verId = "";
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static void verifyPhoneNumber(BuildContext context, String number) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: '+91 $number',
      verificationCompleted: (PhoneAuthCredential credential) {
        signInWithPhoneNumber(
            context, credential.verificationId!, credential.smsCode!);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          print('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        verId = verificationId;
        print("verficationId $verId");
        Navigator.push(context, MaterialPageRoute(builder: (ctx) {
          return  OtpScreen(number: number,);
        }));
        print("code sent");
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  static void logoutApp(BuildContext context) async {
    await _firebaseAuth.signOut();
    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const LoginPage(),
      ),
    );
  }

  static void submitOtp(BuildContext context, String otp) {
    signInWithPhoneNumber(context, verId, otp);
  }

  static Future<void> signInWithPhoneNumber(
    BuildContext context, String verificationId, String smsCode) async {
  try {
    final AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    // Check if the user already exists in Firestore
    DocumentSnapshot userSnapshot = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    if (userSnapshot.exists) {
      // Cast the data to a Map<String, dynamic> to use containsKey
      var userData = userSnapshot.data() as Map<String, dynamic>;
      if (userData.containsKey('type')) {
        // Navigate to HomePage if 'type' field exists
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Show dialog if 'type' field does not exist
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Admin Credentials Required'),
              content: const Text('You need admin credentials to log in.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return const LoginPage();
                    },));
                  },
                ), 
              ],
            );
          },
        );
      }
    } else {
      // User does not exist, navigate to ProfilePage to complete profile
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return const LoginPage();
      }));
    }
  } catch (e) {
    print('Error signing in with phone number: $e');
  }
}
}
