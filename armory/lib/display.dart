import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'connect.dart';

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
      }
    });
    count = 0;
    chartData = <_ChartData>[
      _ChartData(0, 0, 0, 0),
    ];
    timer =
        Timer.periodic(const Duration(milliseconds: 100), _updateDataSource);
  }

  void dispose() {
    timer?.cancel();
    chartData!.clear();
    _chartSeriesControllerA = null;
    _chartSeriesControllerB = null;
    _chartSeriesControllerC = null;
    super.dispose();
  }

  int _getRandomInt(int min, int max) {
    final math.Random random = math.Random();
    return min + random.nextInt(max - min);
  }

  void _updateDataSource(Timer timer) {
    chartData!.add(_ChartData(count, _getRandomInt(10, 10000),
        _getRandomInt(10000, 30000), _getRandomInt(40000, 50000)));
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

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              child: const Text('READ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("Send"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(_writeController.value.text));
                            },
                          ),
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child:
                  const Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  ListView _buildConnectDeviceView() {
    print("In connect device view");
    List<Widget> containers = <Widget>[];

    // for (BluetoothService service in widget.services) {
    //   List<Widget> characteristicsWidget = <Widget>[];

    //   for (BluetoothCharacteristic characteristic in service.characteristics) {
    //     characteristicsWidget.add(
    //       Align(
    //         alignment: Alignment.centerLeft,
    //         child: Column(
    //           children: <Widget>[
    //             Row(
    //               children: <Widget>[
    //                 Text(characteristic.uuid.toString(),
    //                     style: const TextStyle(fontWeight: FontWeight.bold)),
    //               ],
    //             ),
    //             Row(
    //               children: <Widget>[
    //                 ..._buildReadWriteNotifyButton(characteristic),
    //               ],
    //             ),
    //             Row(
    //               children: <Widget>[
    //                 Text('Value: ${widget.readValues[characteristic.uuid]}'),
    //               ],
    //             ),
    //             const Divider(),
    //           ],
    //         ),
    //       ),
    //     );
    //   }
    //   containers.add(
    //     ExpansionTile(
    //         title: Text(service.uuid.toString()),
    //         children: characteristicsWidget),
    //   );
    // }
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
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "10%",
                            style: TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              "0",
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(width: 3),
                            Text(
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
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "10%",
                            style: TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              "0",
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(width: 3),
                            Text(
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
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "10%",
                            style: TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              "0",
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(width: 3),
                            Text(
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

class _ChartData {
  _ChartData(this.time, this.tricept, this.bicept, this.forearm);
  final int time;
  final num tricept;
  final num bicept;
  final num forearm;
}
