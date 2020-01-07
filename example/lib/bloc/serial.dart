import 'dart:async';

import 'package:flutter_bluetooth_serial_example/MainPage.dart';
import 'package:flutter_bluetooth_serial_example/resources/serial.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:rxdart/rxdart.dart';

class SerialBloC {
  SerialBloC() {
    serial = SerialRepo();
  }

  SerialRepo serial;
  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;
  bool _connected = false;
  List<BluetoothDiscoveryResult> result = [];
  StreamSubscription x;

  PublishSubject discoverySubject = PublishSubject();
  PublishSubject connectionBtn = PublishSubject();
  PublishSubject selectDeviceSubject = PublishSubject();

  Observable get discoveryStream => discoverySubject.stream;
  // Observable get connectionBtnStream => Observable.combineLatest(streams, combiner);

  final streamTransformer = StreamTransformer<BluetoothDevice,String>.fromHandlers(
    handleData: (device, sink){

    }
  );

  discover() {
    _isDiscovering = true;
    x = serial.startDiscovery().listen((device) {
      result.add(device);
      discoverySubject.sink.add(result);
    });

    x.onDone(() {
      _isDiscovering = false;
      result = [];
    });
  }
  selectDevice(BluetoothDevice device)
  {
    selectDeviceSubject.sink.add(device);
  }


  dispose() {
    x?.cancel();
    discoverySubject?.close();
    connectionBtn?.close();
    selectDeviceSubject?.close();
  }
}
