import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'connect.dart';
import 'dialog.dart';
import 'display.dart';

class CalibratePage extends StatefulWidget {
  CalibratePage({Key? key, required this.title, required this.connectedDevice})
      : super(key: key);

  final String title;
  final BluetoothDevice connectedDevice;
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final List<BluetoothService> services = <BluetoothService>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  CalibratePageState createState() => CalibratePageState();
}

class CalibratePageState extends State<CalibratePage> {
  final _writeController = TextEditingController();
  Timer? timer;
  List<_ChartData>? chartData;
  late int count;
  ChartSeriesController? _chartSeriesControllerA;
  ChartSeriesController? _chartSeriesControllerB;
  ChartSeriesController? _chartSeriesControllerC;

  _addServiceTolist(final BluetoothService service) {
    if (mounted && !widget.services.contains(service)) {
      setState(() {
        widget.services.add(service);
      });
    }
  }

  @override
  initState() {
    super.initState();
    widget.connectedDevice
        .discoverServices()
        .asStream()
        .listen((List<BluetoothService> services) {
          for (BluetoothService service in services) {
            _addServiceTolist(service);
            for (BluetoothCharacteristic characteristic in service.characteristics) {
              if (characteristic.uuid.toString().substring(0, 8) == '00005678') {
                characteristic.setNotifyValue(true);
                characteristic.value.listen((value) {
                  setState(() {
                    var real_value = List.generate(3, (int i) => fromBytesToInt32(value[4*i], value[4*i+1], value[4*i+2], value[4*i+3]), growable: false);
                    widget.readValues[characteristic.uuid] = real_value;
                  });
                  _updateDataSource(characteristic);
                });
              }
            }
          }
    });
    count = 19;
    chartData = <_ChartData>[
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
      _ChartData(0, 0, 0, 0),
    ];
  }

  void dispose() {
    chartData!.clear();
    _chartSeriesControllerA = null;
    _chartSeriesControllerB = null;
    _chartSeriesControllerC = null;
    super.dispose();
  }

  void _updateDataSource(BluetoothCharacteristic characteristic) {
    chartData!.add(_ChartData(count, widget.readValues[characteristic.uuid]![0],
        widget.readValues[characteristic.uuid]![1], widget.readValues[characteristic.uuid]![2]));
    if (chartData!.length == 20) {
      chartData!.removeAt(0);
      _chartSeriesControllerA?.updateDataSource(
        addedDataIndexes: <int>[chartData!.length - 1],
        removedDataIndexes: <int>[0],
      );
      _chartSeriesControllerB?.updateDataSource(
        addedDataIndexes: <int>[chartData!.length - 1],
        removedDataIndexes: <int>[0],
      );
      _chartSeriesControllerC?.updateDataSource(
        addedDataIndexes: <int>[chartData!.length - 1],
        removedDataIndexes: <int>[0],
      );
    } else {
      _chartSeriesControllerA?.updateDataSource(
        addedDataIndexes: <int>[chartData!.length - 1],
      );
      _chartSeriesControllerB?.updateDataSource(
        addedDataIndexes: <int>[chartData!.length - 1],
      );
      _chartSeriesControllerC?.updateDataSource(
        addedDataIndexes: <int>[chartData!.length - 1],
      );
    }
    count = count + 1;
  }

  Container _buildLiveLineChart() {
    return Container(
        height: 250,
        child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis:
                NumericAxis(majorGridLines: const MajorGridLines(width: 0)),
            primaryYAxis: NumericAxis(
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0)),
            series: <ChartSeries>[
              LineSeries<_ChartData, int>(
                onRendererCreated: (ChartSeriesController controller) {
                  _chartSeriesControllerA = controller;
                },
                dataSource: chartData!,
                color: Colors.green,
                xValueMapper: (_ChartData sales, _) => sales.time,
                yValueMapper: (_ChartData sales, _) => sales.bicept,
                animationDuration: 0,
              ),
              LineSeries<_ChartData, int>(
                onRendererCreated: (ChartSeriesController controller) {
                  _chartSeriesControllerB = controller;
                },
                dataSource: chartData!,
                color: Colors.red,
                xValueMapper: (_ChartData sales, _) => sales.time,
                yValueMapper: (_ChartData sales, _) => sales.tricept,
                animationDuration: 0,
              ),
              LineSeries<_ChartData, int>(
                onRendererCreated: (ChartSeriesController controller) {
                  _chartSeriesControllerC = controller;
                },
                dataSource: chartData!,
                color: Colors.purple,
                xValueMapper: (_ChartData sales, _) => sales.time,
                yValueMapper: (_ChartData sales, _) => sales.forearm,
                animationDuration: 0,
              ),
            ]));
  }

  ListView _buildConnectDeviceView() {
    List<Widget> containers = <Widget>[];
    containers.add(Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Time to Calibrate!',
            style: Theme.of(context).textTheme.headline4,
          ),
          const SizedBox(height: 10),
          Text(
            'Verify that the three lines below 100 on the y-axis.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 30),
          const Text(
            'Tips for calibration:',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ));

    containers.add( Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '     1) Apply hand sanitizer to the skin below each sensor',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
          Text(
            '     2) Adjust the locations of each sensor on the arm',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
          Text(
            '     3) Wait a while :)',
            style: Theme.of(context).textTheme.bodyLarge,
            
          ),
          const SizedBox(height: 20),
        ],
    ));

    containers.add(_buildLiveLineChart());

    containers.add(Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 10),
          Text(
            'Click the following button once the device is calibrated:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
        ],
      ),
    ));

    containers.add(ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DisplayPage(
                title: "Data Dashboard", connectedDevice: widget.connectedDevice)),
        );
      },
      child: const Text('CONTINUE'),
    ));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    return _buildConnectDeviceView();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: (() {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ConnectPage(title: "Select your Device")),
              );
            }),
          ),
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: _buildView(),
      );
}

Color getColor(int percentage) {
  percentage = 100 - percentage;
  int r, g, b = 0;
  if (percentage < 50) {
    r = 255;
    g = (5.1 * percentage).toInt();
  } else {
    g = 255;
    r = (510 - 5.1 * percentage).toInt();
  }
  return Color.fromARGB(255, r, g, b);
}

int fromBytesToInt32(int b3, int b2, int b1, int b0) {
  return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
}

class _ChartData {
  _ChartData(this.time, this.tricept, this.bicept, this.forearm);
  final int time;
  final int tricept;
  final int bicept;
  final int forearm;

  List<String> getPercentages() {
    int sum = tricept + bicept + forearm;
    if (sum == 0) {
      return ["33%", "33%", "33%"];
    }
    int div1 = (tricept / sum * 100).toInt();
    int div2 = (bicept / sum * 100).toInt();
    int div3 = (forearm / sum * 100).toInt();
    return ["$div1%", "$div2%", "$div3%"];
  }
}

showAlertDialog(BuildContext context,
    VoidCallback continueCallBack) {
  BlurryDialog alert = BlurryDialog(
      "Are you sure you want to restart the workout?",
      Column(
        children: const <Widget>[
          Text('This will reset all of the data on the page.'),
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
