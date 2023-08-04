import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

import 'home_widget.dart';
import 'zen_widget.dart';
import 'levels_widget.dart';
import 'settings_page.dart';

Future<void> main() async {
  runApp(const PerliApp());
}

MaterialColor colorToMaterialColor(Color color) {
  final int red = color.red;
  final int green = color.green;
  final int blue = color.blue;

  final Map<int, Color> shades = {
    50: Color.fromRGBO(red, green, blue, .1),
    100: Color.fromRGBO(red, green, blue, .2),
    200: Color.fromRGBO(red, green, blue, .3),
    300: Color.fromRGBO(red, green, blue, .4),
    400: Color.fromRGBO(red, green, blue, .5),
    500: Color.fromRGBO(red, green, blue, .6),
    600: Color.fromRGBO(red, green, blue, .7),
    700: Color.fromRGBO(red, green, blue, .8),
    800: Color.fromRGBO(red, green, blue, .9),
    900: Color.fromRGBO(red, green, blue, 1),
  };

  return MaterialColor(color.value, shades);
}

class PerliApp extends StatelessWidget {
  const PerliApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Force portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Perli',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: colorToMaterialColor(white),
        colorScheme: ColorScheme.light(
            primary: white,
            secondary: logoGreen,
            background: backgroundColor,
            tertiary: lightGrey,
            onPrimary: black),
        fontFamily: 'Lora',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: colorToMaterialColor(black),
        colorScheme: ColorScheme.dark(
          primary: black,
          secondary: logoGreen,
          background: black,
          tertiary: darkGrey,
          onPrimary: white,
        ),
        fontFamily: 'Lora',
      ),
      themeMode: ThemeMode.system,
      home: const MainPage(title: 'Perli'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget getBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeWidget(key: UniqueKey());
      case 1:
        return ZenWidget(key: UniqueKey());
      case 2:
        return LevelsWidget(key: UniqueKey());
      default:
        return const Text(
            'Something went wrong! It would be great if you could report this to the developers.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Image.asset(
              'assets/images/logo.png',
              width: 30,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 10),
            Text(widget.title),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return const SettingsPage();
                  },
                ),
              ).then((value) {
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: getBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Zen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: 'Levels',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: logoGreen,
        onTap: _onItemTapped,
      ),
    );
  }
}
