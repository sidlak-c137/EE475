import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'connect.dart';
import 'dialog.dart';

class DisplayPage extends StatefulWidget {
  DisplayPage({Key? key, required this.title, required this.connectedDevice})
      : super(key: key);

  final String title;
  final BluetoothDevice connectedDevice;
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final List<BluetoothService> services = <BluetoothService>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  DisplayPageState createState() => DisplayPageState();
}

class DisplayPageState extends State<DisplayPage> {
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
                    var real_value = List.generate(3, (int i) => fromBytesToInt32(value[4*i], value[4*i+1], value[4*i+2], value[4*i+3]), growable: true);
                    real_value.add(value[4*3+3]);
                    real_value.add(value[4*3+1]);
                    real_value.add(value[4*3+2]);
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
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
      _ChartData(0, 0, 0, 0, 0, 0, 0),
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
    print(widget.readValues[characteristic.uuid]);
    chartData!.add(_ChartData(count, widget.readValues[characteristic.uuid]![0],
        widget.readValues[characteristic.uuid]![1], widget.readValues[characteristic.uuid]![2], widget.readValues[characteristic.uuid]![3], widget.readValues[characteristic.uuid]![4], widget.readValues[characteristic.uuid]![5]));
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
    List<String> percentages = chartData![18].getPercentages();
    List<String> counts = chartData![18].getCounts();
    containers.add(Container(
      margin: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset('images/armory.png', scale: 1.5),
          Column(children: [
            // const Text(
            //   "Relative Usage",
            //   style: TextStyle(fontSize: 20.0),
            // ),
            Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(10.0),
                width: 125,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red,
                    width: 5.0,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Tricept",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.all(0.0),
                        padding: const EdgeInsets.all(0.0),
                        height: 50,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            percentages[0],
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              counts[0],
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              "reps",
                              style: TextStyle(fontSize: 15),
                            ),
                          ])
                    ])),
            Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(10.0),
                width: 125,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green,
                    width: 5.0,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Bicept",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.all(0.0),
                        padding: const EdgeInsets.all(0.0),
                        height: 50,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            percentages[1],
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              counts[1],
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              "reps",
                              style: TextStyle(fontSize: 15),
                            ),
                          ])
                    ])),
            Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(10.0),
                width: 125,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.purple,
                    width: 5.0,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Forearm",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.all(0.0),
                        padding: const EdgeInsets.all(0.0),
                        height: 50,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            percentages[2],
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              counts[2],
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              "reps",
                              style: TextStyle(fontSize: 15),
                            ),
                          ])
                    ])),
          ]),
        ],
      ),
    ));

    containers.add(_buildLiveLineChart());

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
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.loop),
              tooltip: 'Restart Workout',
              onPressed: () {
                continueCallBack() async {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DisplayPage(
                            title: "Data Dashboard", connectedDevice: widget.connectedDevice)),
                  );
                }

              showAlertDialog(context, continueCallBack);
              },
            ),
          ],
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
  _ChartData(this.time, this.tricept, this.bicept, this.forearm, this.tc, this.bc, this.fc);
  final int time;
  final int tricept;
  final int bicept;
  final int forearm;
  final int tc;
  final int bc;
  final int fc;

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

  List<String> getCounts() {
    return ["$tc", "$fc", "$bc"];
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
