import 'package:armory/calibrate.dart';
import 'package:armory/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'home.dart';
import 'display.dart';
import 'alert.dart';

class ConnectPage extends StatefulWidget {
  ConnectPage({Key? key, required this.title}) : super(key: key);

  final String title;
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  ConnectPageState createState() => ConnectPageState();
}

class ConnectPageState extends State<ConnectPage> {
  _addDeviceTolist(final BluetoothDevice device) {
    if (mounted && !widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Widget> containers = <Widget>[];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              // the height is 50, the width is full
              minimumSize: const Size.fromHeight(50)),
          onPressed: () async {
            continueCallBack() async {
              // code on continue comes here
              print("next page");
              widget.flutterBlue.stopScan();
              try {
                await device.connect();
              } on PlatformException catch (e) {
                if (e.code != 'already_connected') {
                  print("Exception");
                  rethrow;
                }
              } finally {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CalibratePage(
                          title: "Calibrate", connectedDevice: device)),
                );
              }
            }

            showAlertDialog(context, device, continueCallBack);
          },
          child: Column(
            children: <Widget>[
              Text(device.name == '' ? 'N/A' : device.name),
              Text(device.id.toString()),
            ],
          ),
        ),
      );
      containers.add(const SizedBox(height: 10));
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    String fail = '';
    widget.flutterBlue.isAvailable.then((bool isAvailable) {
      if (isAvailable) {
        widget.flutterBlue.isOn.then((bool isOn) {
          if (!isOn) {
            fail = 'Bluetooth is not turned on';
          }
        });
      } else {
        fail = "Bluetooth LE is not supported by this device";
      }
    });
    if (fail != '') {
      continueCallBack() async {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const HomePage(title: "The Armory")),
        );
      }

      return showAlert(context, fail, continueCallBack);
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: (() {
              widget.flutterBlue.stopScan();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HomePage(title: "The Armory")),
              );
            }),
          ),
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: _buildView(),
      );
}

showAlertDialog(BuildContext context, BluetoothDevice device,
    VoidCallback continueCallBack) {
  BlurryDialog alert = BlurryDialog(
      "Are you sure you want to connect to:",
      Column(
        children: <Widget>[
          Text(device.name == '' ? '(unknown device)' : device.name),
          Text(device.id.toString()),
        ],
      ),
      continueCallBack);

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

showAlert(BuildContext context, String content, VoidCallback continueCallBack) {
  BlurryAlert alert = BlurryAlert("Warning", content, continueCallBack);

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
