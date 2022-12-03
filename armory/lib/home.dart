import 'package:flutter/material.dart';

import 'connect.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  ListView _buildHomePage() {
    List<Widget> container = <Widget>[];
    container.add(Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Welcome to the Armory!',
            style: Theme.of(context).textTheme.headline4,
          ),
          const SizedBox(height: 10),
          const Image(image: AssetImage('images/armory_home.png')),
          Text(
            'Optimize your workout using our amazing new device.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text(
            'Setting up the device is simple. First connect to the device\nvia bluetooth by clicking the "CONNECT" button below:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
        ],
      ),
    ));
    container.add(ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ConnectPage(title: "Select your Device")),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('CONNECT'),
    ));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...container,
      ],
    );
  }

  ListView _buildView() {
    return _buildHomePage();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
}
