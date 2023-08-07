import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';

enum ShopItemType { skin, music }

class ShopItem {
  String name;
  String shortDescription;
  String longDescription;
  int price;
  ShopItemType type;
  String imagePath;
  String uid;
  bool isBought;
  bool active;

  ShopItem({
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.price,
    required this.type,
    required this.imagePath,
    required this.uid,
    this.isBought = false,
    this.active = false,
  });

  String coverImagePath() {
    return "$imagePath-cover.png";
  }

  String greenImagePath() {
    return "$imagePath-green.png";
  }

  String yellowImagePath() {
    return "$imagePath-yellow.png";
  }

  String redImagePath() {
    return "$imagePath-red.png";
  }

  String whiteImagePath() {
    return "$imagePath-white.png";
  }

  String _prefKeyBought() {
    return "shop-b-$uid";
  }

  String _prefKeyActivated() {
    return "shop-a-$uid";
  }

  Future<void> load() async {
    if (isBought) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    isBought = prefs.getBool(_prefKeyBought()) == true;
    active = prefs.getBool(_prefKeyActivated()) == true;
  }

  Future<String> buy() async {
    await Settings.load();
    await load();

    if (isBought) {
      return "You have already bought this item!";
    }

    Setting coins = Settings.getSetting("coins");
    if (coins.integerValue < price) {
      return "You don't have enough coins to buy $name";
    } else {
      coins.setValue(coins.integerValue - price);
      await coins.save();
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefKeyBought(), true);
    isBought = true;

    return "Successfully bought $name";
  }

  Future<void> activate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefKeyActivated(), true);
    active = true;
  }

  Future<void> deactivate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefKeyActivated(), false);
    active = false;
  }
}

class Shop {
  static ShopItem? selectedItem = null;

  static List<ShopItem> items = <ShopItem>[
    ShopItem(
      name: "Black n' White",
      shortDescription: "A skin for your game that's only black and white.",
      longDescription: "This skin is a good alternative and is wonderful "
          "for people that don't like too much color in their life. Who needs "
          "rainbows when you can have black... and white!",
      price: 100,
      type: ShopItemType.skin,
      imagePath: "assets/images/skins/blackwhite",
      uid: "blackwhite-0",
    ),
    ShopItem(
      name: "Darkmode",
      shortDescription: "A skin that shows everyone you're cool.",
      longDescription: "If other skins are types of glasses, this one "
          "represents sunglasses. This is the skin to choose "
          "when you have trouble sleeping. This is the sleekest. "
          "The most beautiful. The best!",
      price: 200,
      type: ShopItemType.skin,
      imagePath: "assets/images/skins/darkmode",
      uid: "darkmode-0",
    ),
    ShopItem(
      name: "RGB-Circles",
      shortDescription: "A color and minimal skin for your game.",
      longDescription: "What is better than circles? Colors! You get "
          "both with this awesome skin. It's bright and minimalistic design "
          "will definitely keep you awake :)",
      price: 300,
      type: ShopItemType.skin,
      imagePath: "assets/images/skins/rgb",
      uid: "rgb-0",
    ),
    ShopItem(
      name: "Numbers",
      shortDescription: "Numbers are better than colors, right?",
      longDescription: "In the digital age, everything gets translated "
          "into numbers. So why bother converting it to colors? It may "
          "be a bit impractical but it's definitely worth trying.",
      price: 400,
      type: ShopItemType.skin,
      imagePath: "assets/images/skins/numbers",
      uid: "numbers-0",
    ),
    ShopItem(
      name: "Hardcore",
      shortDescription: "Life's Tough. So is this skin.",
      longDescription: "When life gives you lemons, you create "
          "a skin that's not very helpful to anyone. "
          "If you're already trying to train your brain, "
          "why not train harder?",
      price: 500,
      type: ShopItemType.skin,
      imagePath: "assets/images/skins/hardcore",
      uid: "hardcore-0",
    ),
  ];

  static List<ShopItem> getItemsFromType(ShopItemType type) {
    return items.where((element) => element.type == type).toList();
  }

  static Future<void> load() async {
    for (ShopItem item in items) {
      await item.load();
    }
  }

  static ShopItem itemFromUid(String uid) {
    return items.firstWhere((element) => element.uid == uid, orElse: () {
      return items[0];
    });
  }

  static ShopItem? getActive(ShopItemType type) {
    for (ShopItem item in items) {
      if (item.type == type && item.active) {
        return item;
      }
    }
    return null;
  }

  static Future<void> activateItem(String uid) async {
    ShopItem newlyActiveItem = itemFromUid(uid);
    for (ShopItem item in items) {
      if (item.type == newlyActiveItem.type && item.active) {
        await item.deactivate();
      }
    }
    await newlyActiveItem.activate();
  }
}
