import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class SerialRepo {
  Future<List<BluetoothDevice>> getBondedDevices() async{
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Stream<BluetoothDiscoveryResult> startDiscovery() {
    return FlutterBluetoothSerial.instance.startDiscovery();
  }

  Future<bool> pairdWithDevice(String address) async {
    return await FlutterBluetoothSerial.instance.bondDeviceAtAddress(address);
  }

  Future<bool> checkIfEnabled() async {
    return await FlutterBluetoothSerial.instance.isEnabled;
  }

  Future requestEnable() async {
    return await FlutterBluetoothSerial.instance.requestEnable();
  }

  Future requestDisable() async {
    return await FlutterBluetoothSerial.instance.requestDisable();
  }

  Future<BluetoothConnection> connectAtAdress(address) async {
    return await BluetoothConnection.toAddress(address);
  }
  

}
