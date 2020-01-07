import 'dart:convert';

import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial_example/bloc/speech_reco.dart';
import 'package:flutter_bluetooth_serial_example/main.dart';
import 'package:permission/permission.dart';
import 'package:provider/provider.dart';
import 'package:speech_recognition/speech_recognition.dart';
import 'package:toast/toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'MainPage.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String micState = 'idle';
  String robotState = 'reposo';
  // BluetoothConnection connection;

  @override
  void initState() {
    print(Colors.lightBlue[300]);
    activateSpeechRecognizer();
    requestPermission();

    // connection.output.add(utf8.encode('sds'));
    // connection.input.listen((s){
    //   print(utf8.decode(s));
    // });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    connection.close();
    connection = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: MaterialApp(
        theme: ThemeData(
          canvasColor: Color.fromRGBO(58, 66, 86, 0.7),
          textTheme: TextTheme(
            caption: TextStyle(
              color: Colors.grey,
            ),
            body2: TextStyle(
              color: Colors.white,
            ),
            subhead: TextStyle(
              color: Colors.white,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        home: Scaffold(
          backgroundColor: Color.fromRGBO(58, 66, 86, 1),
          drawer: Drawer(
            child: drawerPage,
          ),
          body: Stack(
            children: <Widget>[
              Align(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      height: 300,
                      width: 300,
                      padding: EdgeInsets.only(left: 18),
                      child: FlareActor(
                        transcription == null
                            ? 'assets/robotSad.flr'
                            : 'assets/robot.flr',
                        fit: BoxFit.cover,
                        animation: robotState,
                      ),
                    ),
                    actors()[0],
                    Container(
                        width: 300,
                        height: 50,
                        child: Container(
                          // width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              actors()[3],
                              Text(textRes),
                              actors()[2],
                            ],
                          ),
                        )),
                    actors()[1],
                    StreamBuilder(builder: (context, snapshot) {
                      return GestureDetector(
                        onLongPressStart: (_) {
                          transcription = null;

                          if (!_speechRecognitionAvailable)
                            activateSpeechRecognizer();

                          if (!_isListening && _speechRecognitionAvailable) {
                            micState = 'record';
                            robotState = 'buscando';
                            start();
                            // Toast.show('Listening...', context);
                            HapticFeedback.vibrate();
                          } else
                            Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Speach Recognition is currently unavailable'),
                              duration: Duration(seconds: 1),
                            ));
                        },
                        onLongPressEnd: (s) {
                          cancel();
                          // _isListening = false;
                          // stop();
                          setState(() {
                            micState = 'idle';
                            robotState = 'reposo';
                          });
                        },
                        // onTapCancel: () {
                        //   micState = 'idle';
                        //   setState(() {});
                        // },
                        child: Container(
                          height: 180,
                          width: 180,
                          child: FlareActor(
                            'assets/listen(4).flr',
                            fit: BoxFit.cover,
                            animation: micState,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Builder(builder: (context) {
                return Align(
                  alignment:
                      Alignment.lerp(Alignment.center, Alignment.topLeft, 0.9),
                  child: CircleAvatar(
                    backgroundColor: Colors.lightBlue[300],
                    child: IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(Icons.menu),
                      color: Colors.white,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  SpeechRecognition _speech;
  bool _isListening = false;
  bool _speechRecognitionAvailable = false;
  String transcription = 'right';

  void activateSpeechRecognizer() {
    print('_MyAppState.activateSpeechRecognizer... ');
    _speech = new SpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    // _speech.setCurrentLocaleHandler(onCurrentLocale);
    _speech.setRmsHandler(onRmsChanged);

    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    // _speech.setErrorHandler(errorHandler);
    _speech
        .activate()
        .then((res) => setState(() => _speechRecognitionAvailable = res));
  }

  onRmsChanged(x) {
    print('SASDSAD $x');
  }

  void start() {
    _speech
        .listen(locale: 'en_GB')
        .then((result) => print('_MyAppState.start => result $result'));
  }

  void cancel() =>
      _speech.cancel().then((result) => setState(() => _isListening = result));

  void stop() => _speech.stop().then((result) {
        setState(() => _isListening = result);
      });

  void onSpeechAvailability(bool result) =>
      setState(() => _speechRecognitionAvailable = result);

  // void onCurrentLocale(String locale) {
  //   print('_MyAppState.onCurrentLocale... $locale');
  //   setState(
  //       () => selectedLang = languages.firstWhere((l) => l.code == locale));
  // }

  void onRecognitionStarted() => setState(() => _isListening = true);
  bool backward = false;
  String textRes = ' ';

  void onRecognitionResult(String text) async {
textRes = text;
    setState(() => transcription = text);
    final res = actorVals.singleWhere(
        (n) => text.toLowerCase().contains(n['name']),
        orElse: () => null);
    if (res != null) transcription = res['name'];
    
    if (transcription != null && connection != null) {
      connection.output.add(utf8.encode(transcription[0]));
      print(transcription[0]);
      await connection.output.allSent;
    }
  }

  List<Map<String, dynamic>> actorVals = [
    {'name': 'forward', 'val': true},
    {'name': 'backward', 'val': true},
    {'name': 'right', 'val': true},
    {'name': 'left', 'val': true},
  ];
  List<Widget> actors() {
    return List.generate(actorVals.length, (index) {
      // if (transcription.toLowerCase().contains(actorVals[index]['name'])) {
      //   actorVals[index]['val'] = false;
      //   if (connection != null) {
      //     connection.output.add(utf8.encode(actorVals[index]['name']));
      //     connection.output.allSent;
      //   }
      // } else {
      //   actorVals[index]['val'] = true;
      // }
      actorVals[index]['val'] =
          actorVals[index]['name'] == transcription ? false : true;
      // actorVals[index]['val'] =
      //     transcription.contains(actorVals[index]['name']) ? false : true;
      return Container(
        width: 100,
        height: 100,
        child: FlareActor(
          'assets/${actorVals[index]['name']}.flr',
          animation: 'focus_arrow',
          fit: BoxFit.cover,
          isPaused: actorVals[index]['val'],
          color: Colors.lightBlue[300],
        ),
      );
    });
  }

  void onRecognitionComplete() => setState(() => _isListening = false);

  void errorHandler() => activateSpeechRecognizer();
  requestPermission() async {
    // final res = await Permission.requestSinglePermission(PermissionName.Microphone);
    final perm = await PermissionHandler()
        .requestPermissions([PermissionGroup.microphone]);
    // print(res);
  }
}
