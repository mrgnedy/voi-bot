import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial_example/resources/speech_reco.dart';
import 'package:rxdart/rxdart.dart';

class SpeechBloC {
  static final List<String> _directions = ['forward, backward, left, right'];

  bool _speechRecognitionAvailable = false;
  String _transcription;
  bool _isListening = false;
  bool get isListening => _isListening;
  bool get speechRecognitionAvailable => _speechRecognitionAvailable;
  String get transcription => _transcription;
  SpeechReco _speechRepo;
  SpeechBloC() {
    _speechRepo = SpeechReco.init(
        onResult: onResult,
        onRecognitionComplete: onRecognitionComplete,
        onRecognitionStarted: onRecognitionStarted,
        onSpeechAvailability: onSpeechAvailability);
  }
  PublishSubject micSubject = PublishSubject();
  PublishSubject arrowSubject = PublishSubject();
  PublishSubject robotSubject = PublishSubject();

  Observable get micStream => micSubject.stream;
  Observable get arrowStream => arrowSubject.stream;
  Observable get robotStream => robotSubject.stream;

  startListening(s) {
    HapticFeedback.vibrate();
    if (!_speechRecognitionAvailable)
      _speechRepo.activateSpeechRecognizer().then((s) {
        if (!_isListening) {
          micSubject.sink.add('record');
          robotSubject.sink.add('buscando');
          _speechRepo.start();
        }
      });
  }

  stop(s) {
    robotSubject.sink.add('Cargando');
    micSubject.sink.add('idle');
  }

  onResult(String result) {
    final String direct = _directions.firstWhere(
        (direct) => result.toLowerCase().contains(direct),
        orElse: () => null);
    // robotSubject.sink.add(direct);
    arrowSubject.add(direct);
    micSubject.sink.add('idle');
    robotSubject.add('reposo');
  }

  final streamTransformer =
      StreamTransformer<String, String>.fromHandlers(handleData: (res, sink) {
    final result = _directions.firstWhere(
        (direct) => res.toLowerCase().contains(direct),
        orElse: () => null);
    if (res.toLowerCase().contains('forward'))
      sink.add('forward');
    else if (res.toLowerCase().contains('backward'))
      sink.add('backward');
    else if (res.toLowerCase().contains('left'))
      sink.add('left');
    else if (res.toLowerCase().contains('right'))
      sink.add('right');
    else
      sink.addError('Speach doesn\'t contain a vaild command!');
  });

  void onSpeechAvailability(bool result) =>
      _speechRecognitionAvailable = result;

  // void onCurrentLocale(String locale) {
  //   print('_MyAppState.onCurrentLocale... $locale');
  //   setState(
  //       () => selectedLang = languages.firstWhere((l) => l.code == locale));
  // }
  // void onRecognitionResult(String text) => (() => _transcription = text);

  void onRecognitionStarted() {
    _isListening = true;
    // robotSubject.sink.add('reposo');
  }

  void onRecognitionComplete(String ewa) {
    _isListening = false;

    
  }

  void errorHandler() => _speechRepo.activateSpeechRecognizer();

  dispose() {
    micSubject?.close();
    arrowSubject?.close();
    robotSubject?.close();
  }
}
