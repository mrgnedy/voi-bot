import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';

import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
// import './ChatPage.dart';
// import './BackgroundCollectingTask.dart';
// import './BackgroundCollectedPage.dart';

//import './LineChart.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

  BluetoothConnection connection;
  BluetoothDevice selectedDevice;
class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";
  ValueNotifier x;
  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  // BackgroundCollectingTask _collectingTask;
  FlutterBluetoothSerial serial;
  bool _autoAcceptPairingRequests = false;
  bool get isConnected => connection != null && connection.isConnected;
  bool  isBonded =
      selectedDevice != null &&
      selectedDevice.bondState == BluetoothBondState.bonded;
  
  @override
  void initState() {
    super.initState();
    // x = ValueNotifier(selectedDevice.bondState)
    //   ..addListener(() {
    //     setState(() {});
    //   });
    FlutterBluetoothSerial.instance.onStateChanged().listen((s) {
      if (mounted) setState(() {});
    });
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    FlutterBluetoothSerial.instance.setOnDisconnectedHandler(() => print('n'));
    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    // _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: ListView(
        children: <Widget>[
          Divider(),
          ListTile(title: const Text('General')),
          //Important
          SwitchListTile(
            title: const Text('Enable Bluetooth'),
            subtitle: Text(' '),
            value: _bluetoothState.isEnabled,
            onChanged: (bool value) {
              // Do the request and update with the true value then
              future() async {
                // async lambda seems to not working
                if (value)
                  await FlutterBluetoothSerial.instance.requestEnable();
                else
                  await FlutterBluetoothSerial.instance.requestDisable();
              }

              future().then((_) {
                setState(() {});
              });
            },
          ),

          ListTile(
              title: _discoverableTimeoutSecondsLeft == 0
                  ? const Text("Discoverable")
                  : Text(
                      "Discoverable for ${_discoverableTimeoutSecondsLeft}s"),
              subtitle: const Text("PsychoX-Luna"),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Checkbox(
                  value: _discoverableTimeoutSecondsLeft != 0,
                  onChanged: null,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: null,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  //Importamt
                  onPressed: () async {
                    print('Discoverable requested');
                    final int timeout = await FlutterBluetoothSerial.instance
                        .requestDiscoverable(60);
                    if (timeout < 0) {
                      print('Discoverable mode denied');
                    } else {
                      print('Discoverable mode acquired for $timeout seconds');
                    }
                    setState(() {
                      _discoverableTimeoutTimer?.cancel();
                      _discoverableTimeoutSecondsLeft = timeout;
                      _discoverableTimeoutTimer =
                          Timer.periodic(Duration(seconds: 1), (Timer timer) {
                        setState(() {
                          if (_discoverableTimeoutSecondsLeft < 0) {
                            FlutterBluetoothSerial.instance.isDiscoverable
                                .then((isDiscoverable) {
                              if (isDiscoverable) {
                                print(
                                    "Discoverable after timeout... might be infinity timeout :F");
                                _discoverableTimeoutSecondsLeft += 1;
                              }
                            });
                            timer.cancel();
                            _discoverableTimeoutSecondsLeft = 0;
                          } else {
                            _discoverableTimeoutSecondsLeft -= 1;
                          }
                        });
                      });
                    });
                  },
                )
              ])),

          Divider(),
          ListTile(title: const Text('Devices discovery and connection')),
          SwitchListTile(
            title: const Text('Auto-try specific pin when pairing'),
            subtitle: const Text('Pin 1234'),
            value: _autoAcceptPairingRequests,
            onChanged: (bool value) {
              setState(() {
                _autoAcceptPairingRequests = value;
              });
              if (value) {
                FlutterBluetoothSerial.instance.setPairingRequestHandler(
                    (BluetoothPairingRequest request) {
                  print("Trying to auto-pair with Pin 1234");
                  if (request.pairingVariant == PairingVariant.Pin) {
                    return Future.value("1234");
                  }
                  return null;
                });
              } else {
                FlutterBluetoothSerial.instance.setPairingRequestHandler(
                    (s) => Future.sync(() => _pairWithDevice()));
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                height: 60,
                width: 100,
                alignment: Alignment.center,
                child: RaisedButton(
                    child: const Text('Discover',style: TextStyle(color: Colors.white),),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.lightBlue[300],
                    onPressed: () async {
                      selectedDevice = await _showDialogue();
                      // x = ValueNotifier (selectedDevice.bondState)..addListener(()=>setState((){}));
                      if (mounted) setState(() {});
                      if (selectedDevice != null) {
                        print(
                            'Discovery -> selected ' + selectedDevice.address);
                        if (selectedDevice.isBonded) {
                          // BluetoothConnection.toAddress(selectedDevice.address);
                        }
                      } else {
                        print('Discovery -> no device selected');
                      }
                    }),
              ),
              RaisedButton(
                onPressed: () {},
                child: Text('Paired',style: TextStyle(color: Colors.white),),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.lightBlue[300],
              )
            ],
          ),
          

          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              
              children: <Widget>[
                Expanded(
                  // width: 120,
                  flex: 2,
                  child: selectedDevice == null
                      ? ListTile(
                        contentPadding: EdgeInsets.zero,
                          title: Text('No device selected'),
                        )
                      : ListTile(
                        contentPadding: EdgeInsets.zero,
                          title: Text(selectedDevice.name.toString()) ?? ' ',
                          subtitle: Text(isConnected && selectedDevice.isBonded
                              ? 'Device connected'
                              : selectedDevice.isBonded
                                  ? 'Device paired'
                                  : 'Device not connected'),
                        ),
                ),
                Expanded(child: _buildConnectBtn())
              ],
            ),
          ),
          RaisedButton(
            child: null,
            onPressed: () async => BluetoothConnection.toAddress(
              selectedDevice.address,
            ).then((conn) async {
              connection = conn;
              setState(() {});
              print(conn.isConnected);
              conn.output.add(utf8.encode('asdsd'));
              conn.input.listen((s) => print('s')).onDone(() {
                // Example: Detect which side closed the connection
                // There should be `isDisconnecting` flag to show are we are (locally)
                // in middle of disconnecting process, should be set before calling
                // `dispose`, `finish` or `close`, which all causes to disconnect.
                // If we except the disconnection, `onDone` should be fired as result.
                // If we didn't except this (no flag set), it means closing by remote.

                if (this.mounted) {
                  setState(() {});
                }
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectBtn() {
    return Align(
      child: RaisedButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Text(
          isConnected
              ? 'Disconnect'
              : selectedDevice == null
                  ? 'Select Device'
                  : !isBonded ? 'Pair' : 'Connect',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: isConnected
            ? _disConnect
            : selectedDevice == null 
                ? null
                : !isBonded ? _pairWithDevice : _connect,
        color: isConnected
            ? Colors.red
            : selectedDevice == null
                ? Colors.white
                : !isBonded ? Colors.purple : Colors.lightBlue[300],
      ),
    );
  }

  void _connect() {
    BluetoothConnection.toAddress(selectedDevice.address).then((con) {
      connection = con;
      FlutterBluetoothSerial.instance;
      x = ValueNotifier(selectedDevice.isConnected)
        ..addListener(() {
          setState(() {});
        });
      if (mounted) setState(() {});
      connection.input.listen(_onDateRecieved).onDone(() => setState);
    });
  }

  _onDateRecieved(Uint8List data) {
    print('DATA RECIEVED: ${utf8.decode(data)}');
  }

  void _pairWithDevice() {
    FlutterBluetoothSerial.instance
        .bondDeviceAtAddress(selectedDevice.address)
        .then((s) {
          isBonded=s;
      print(s);
      // print(selectedDevice.bondState);
      if (s) print('Connected to ${selectedDevice.name}');
      if (mounted) setState(() {});
    });
  }

  void _disConnect() {
    connection.close();
    if (mounted) setState(() {});
    connection = null;
  }

  // void _startChat(BuildContext context, BluetoothDevice server) {
  //   Navigator.of(context).push(MaterialPageRoute(builder: (context) {
  //     return ChatPage(server: server);
  //   }));
  // }

  // Future<void> _startBackgroundTask(
  //     BuildContext context, BluetoothDevice server) async {
  //   try {
  //     _collectingTask = await BackgroundCollectingTask.connect(server);
  //     await _collectingTask.start();
  //   } catch (ex) {
  //     if (_collectingTask != null) {
  //       _collectingTask.cancel();
  //     }
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: const Text('Error occured while connecting'),
  //           content: Text("${ex.toString()}"),
  //           actions: <Widget>[
  //             new FlatButton(
  //               child: new Text("Close"),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // }

  Future _showDialogue() {
    return showDialog(
        context: context,
        builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Color.fromRGBO(58, 66, 86, 0.8),
              child: DiscoveryPage(),
            ));
  }
}
