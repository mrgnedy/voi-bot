import 'package:flutter_bluetooth_serial_example/bloc/serial.dart';
import 'package:flutter_bluetooth_serial_example/bloc/speech_reco.dart';

class BaseBloC {
  final _serial = SerialBloC();
  final _speech = SpeechBloC();

  SerialBloC get serialBloc => _serial;
  SpeechBloC get speechBloC => _speech;
}
