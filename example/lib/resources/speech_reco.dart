import 'package:permission_handler/permission_handler.dart';
import 'package:speech_recognition/speech_recognition.dart';

class SpeechReco {
  SpeechRecognition _speech;
  // bool _speechRecognitionAvailable = false;
  // bool _isListening = false;
  // bool get isListening => _isListening;
  // bool get speechRecognitionAvailable => _speechRecognitionAvailable;
  // String get transcription => _transcription;
  // String _transcription;
  Function onResult;
  Function onSpeechAvailability;
  Function onRecognitionStarted;
  Function onRecognitionComplete;

  SpeechReco.init(
      {this.onResult,
      this.onRecognitionComplete,
      this.onRecognitionStarted,
      this.onSpeechAvailability}) {
    requestPermission();
    activateSpeechRecognizer();
  }

  Future activateSpeechRecognizer() {
    print('_MyAppState.activateSpeechRecognizer... ');
    _speech = new SpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    // _speech.setCurrentLocaleHandler(onCurrentLocale);
    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);

    // _speech.setErrorHandler(errorHandler);
    return _speech.activate();
  }

  requestPermission() async {
    // final res = await Permission.requestSinglePermission(PermissionName.Microphone);'
    PermissionStatus check = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.microphone);
    if (check == PermissionStatus.granted) return null;
    final perm = await PermissionHandler()
        .requestPermissions([PermissionGroup.microphone]);
    // print(res);
  }

  void start() => _speech
      .listen(locale: 'en_GB')
      .then((result) => print('_MyAppState.start => result $result'));

  Future cancel() => _speech.cancel();

  Future stop() => _speech.stop();
}
