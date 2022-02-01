import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const MaterialApp(
      home: HomePage(),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  fetchDeviceToken() async {
    String? token = await messaging.getToken();
    print(token);
  }

  @override
  void initState() {
    super.initState();

    fetchDeviceToken();

    FirebaseMessaging.onMessage.listen((msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Notification Arrived!\nData: ${msg.data['my_body']}\nNotification: ${msg.notification!.body}"),
        ),
      );
    });

    // https://fcm.googleapis.com/fcm/send

    var initializationSettingsAndroid =
        const AndroidInitializationSettings('mipmap/ic_launcher');
    var initializationSettingsIOs = const IOSInitializationSettings();
    var initSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOs);

    tz.initializeTimeZones();

    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: onSelectNotification);
  }

  onSelectNotification(String? payload) {
    print("Notification clicked: $payload");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter App"),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Simple Local Notification"),
              onPressed: showSimpleNotification,
            ),
            ElevatedButton(
              child: const Text("Scheduled Local Notification"),
              onPressed: showScheduledNotification,
            ),
            ElevatedButton(
              child: const Text("Big Picture Local Notification"),
              onPressed: showBigPictureNotification,
            ),
            ElevatedButton(
              child: const Text("Media Style Local Notification"),
              onPressed: showNotificationMediaStyle,
            ),
            ElevatedButton(
              child: const Text("Firebase Push Notification"),
              style: ElevatedButton.styleFrom(
                primary: Colors.amber,
                onPrimary: Colors.black,
              ),
              onPressed: sendFCM,
            ),
          ],
        ),
      ),
    );
  }

  void showSimpleNotification() async {
    var android = const AndroidNotificationDetails('id', 'channel ',
        channelDescription: 'description',
        priority: Priority.high,
        importance: Importance.max);
    var iOS = const IOSNotificationDetails();

    var platform = NotificationDetails(android: android, iOS: iOS);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Flutter devs',
      'Flutter Local Notification Demo',
      platform,
      payload: 'Welcome to the Local Notification demo',
    );
  }

  void showScheduledNotification() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'channel id',
      'channel name',
      channelDescription: 'channel description',
      icon: 'mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('mipmap/ic_launcher'),
    );
    var iOSPlatformChannelSpecifics = const IOSNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        "Notification Title",
        "This is the Notification Body!",
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 2)),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> showBigPictureNotification() async {
    var bigPictureStyleInformation = const BigPictureStyleInformation(
      DrawableResourceAndroidBitmap("mipmap/ic_launcher"),
      largeIcon: DrawableResourceAndroidBitmap("mipmap/ic_launcher"),
      contentTitle: 'flutter devs',
      summaryText: 'summaryText',
    );
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id', 'big text channel name',
        channelDescription: 'big text channel description',
        styleInformation: bigPictureStyleInformation);
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: null);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics,
        payload: "big image notifications");
  }

  Future<void> showNotificationMediaStyle() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'media channel id',
      'media channel name',
      channelDescription: 'media channel description',
      color: Colors.red,
      enableLights: true,
      largeIcon: DrawableResourceAndroidBitmap("mipmap/ic_launcher"),
      styleInformation: MediaStyleInformation(),
    );
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: null);
    await flutterLocalNotificationsPlugin.show(
        0, 'notification title', 'notification body', platformChannelSpecifics);
  }

  sendFCM() async {
    var url = Uri.parse("https://fcm.googleapis.com/fcm/send");
    var myBody = {
      "to":
          "caAQBFrNTPKBlMcbZ1mNRR:APA91bFU3lGIt1FiSpZengtkzwzi63GQqpebk71oG1AtB3-XcxCnw6vuZjd30-Pd5kYtSdxd7uR3s_LKKwpdawV_vUghKmXCR00UTD4bub3znEYJqAC9aO6EgzyhMurbuNhIcTnMXemM",
      "notification": {
        "title": "hello",
        "body": "Notification Body",
        "content_available": true,
        "priority": "high"
      },
      "data": {
        "priority": "high",
        "content_available": true,
        "my_body": "Hello FCM",
        "my_content": "Elementary school"
      }
    };
    var myHeaders = {
      'Content-Type': 'application/json',
      'Authorization':
          'key=AAAARKP7i1o:APA91bEdy_AnLYkf3zi52TxeENwYmbTaia7849zW5Tk5Q9dU5U046uAdwnaWFLF7NnsdUL952maeqW_4OaFPSfz2CX6PbA-yfFWWlI-Ib9hkEpiN2Dr5vsaoAgBXuowsbO_MU9HSOrxg'
    };

    var response = await http.post(
      url,
      body: jsonEncode(myBody),
      headers: myHeaders,
    );

    if (response.statusCode == 200) {
      print(response.body);
    }
  }
}
