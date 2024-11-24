import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotifications {
//   create an instance of firebase messaging
  final _firebaseMessaging = FirebaseMessaging.instance;

// functions to initialise notifications
  Future<void> initNotifications() async {
  //   check/request permission
    await _firebaseMessaging.requestPermission();

  //   fetch the FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();

  //   print the token (normally would send it to server)
    print("Token: $fcmToken");
  }
// function to handle received messages

// function to handle foreground and background messaging
}