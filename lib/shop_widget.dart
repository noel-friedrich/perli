import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:perli/colors.dart';

import 'shop.dart';
import 'settings.dart';
import 'audiomanager.dart';

class ShopWidget extends StatefulWidget {
  final AudioManager audioManager;

  const ShopWidget({Key? key, required this.audioManager}) : super(key: key);

  @override
  State createState() => _ShopWidgetState();
}

class _ShopWidgetState extends State<ShopWidget> {
  ShopItem? selectedItem;

  Future<void> loadSettings() async {
    await Settings.load();
    await Shop.load();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  void openItemPage(ShopItem item) {
    setState(() {
      selectedItem = item;
    });
  }

  void tellUser(String text) {
    // remove any existing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget makeItemPage(ShopItem item) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      shrinkWrap: true,
      children: <Widget>[
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          color: item.active
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: item.active
                        ? Theme.of(context).colorScheme.background
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.shortDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: item.active
                        ? Theme.of(context).colorScheme.background
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.longDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: item.active
                        ? Theme.of(context).colorScheme.background
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(item.coverImagePath()),
                ),
                const SizedBox(height: 10),
                if (item.active)
                  Text(
                    "You own this item and have activated it.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: item.active
                          ? Theme.of(context).colorScheme.background
                          : null,
                    ),
                  ),
                if (item.isBought && !item.active)
                  const Text(
                    "You own this item.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                if (!item.isBought)
                  Text(
                    "You don't this item yet. It costs ${item.price} coins.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (item.active)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            onPressed: () {
              setState(() {
                item.deactivate().then((_) {
                  loadSettings();
                });
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                'Deactivate',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          ),
        if (item.isBought && !item.active)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            onPressed: () {
              setState(() {
                Shop.activateItem(item.uid).then((_) {
                  loadSettings();
                });
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                'Activate',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          ),
        if (!item.isBought)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            onPressed: () async {
              await item.buy();
              loadSettings();
            },
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                'Buy for ${item.price} coins',
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          onPressed: () {
            setState(() {
              selectedItem = null;
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              'Continue Shopping',
              style: TextStyle(
                fontSize: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> makeItemCards(BuildContext context, ShopItemType shopItemType) {
    List<ShopItem> items = Shop.getItemsFromType(shopItemType);
    return items.map((item) {
      return Container(
        width: 200,
        padding: const EdgeInsets.all(3),
        child: GestureDetector(
          onTap: () {
            openItemPage(item);
          },
          child: Card(
            color: item.active
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  Image.asset(item.coverImagePath()),
                  const SizedBox(height: 10),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: item.active
                          ? Theme.of(context).colorScheme.background
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.shortDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: item.active
                          ? Theme.of(context).colorScheme.background
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedItem != null) {
      return makeItemPage(selectedItem!);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      shrinkWrap: true,
      children: <Widget>[
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                const Text(
                  'Welcome to the Shop!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This is the place to spend all of your coins! '
                  'You can earn coins by completing the levels.\nYour budget:\n',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineSmall,
                    children: [
                      TextSpan(
                        text: Settings.getSetting('coins')
                            .integerValue
                            .toString(),
                      ),
                      const TextSpan(text: ' Coins'),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: makeItemCards(context, ShopItemType.skin),
          ),
        ),
      ],
    );
  }
}
