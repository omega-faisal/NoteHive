import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('demo_database');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<Map<String, dynamic>> _items = [];

  final _testBox = Hive.box('demo_database');

  @override
  void initState() {
    _displayData();
    super.initState();
  }

  void _displayData() {
    // This one retrieves data from database and it stores it into the list _items..

    // This function works like a loop, it will take each entry from database and return a list of _items
    // containing data in map form...
    final data = _testBox.keys.map((key) {
      final item = _testBox.get(key);
      return {"key": key, "name": item['name'], "quantity": item['quantity']};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      if (kDebugMode) {
        print(_items.length);
      }
    });
  }

  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _testBox.add(
        newItem); // This add method will automatically provide the key to each item .. we can also
    // randomly give the key to each item using put method. used in update method..

    _displayData(); // To fetch UI and load database data into our list(_items) and hence UI..
  }

  Future<void> _updateItem(int itemKey, Map<String, dynamic> oldItem) async {
    await _testBox.put(
        itemKey, oldItem); // We are using put method to update the item.
    _displayData(); // To fetch UI and load database data into our list(_items) and hence UI..
  }

  Future<void> _deleteItem(int itemKey) async {
    await _testBox.delete(itemKey);
    _displayData();

    if (!mounted) return; // since we are using buildContext inside async
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Durations.short2,
      content: Text("An item has been deleted"),
    ));
  }

  void _showForm(BuildContext ctx, int? itemKey) {
    // If we are coming from the edit button
    if (itemKey != null) {
      final existingElement =
          _items.firstWhere((element) => element['key'] == itemKey);
      _nameController.text = existingElement['name'];
      _quantityController.text = existingElement['quantity'];
    }

    // If we are coming from the floating action button..
    showModalBottomSheet(
        context: ctx,
        builder: (_) => Container(
              padding: EdgeInsets.fromLTRB(
                  15, 15, 15, MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'quantity'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        if (itemKey == null) {
                          _createItem({
                            "name": _nameController.text,
                            "quantity": _quantityController.text
                          });
                        }
                        if (itemKey != null) {
                          _updateItem(itemKey, {
                            "name": _nameController.text.trim(),
                            // To remove extra space from string
                            "quantity": _quantityController.text.trim()
                          });
                        }
                        _nameController.text = '';
                        _quantityController.text = '';
                        Navigator.of(ctx).pop();
                      },
                      child: Text((itemKey == null) ? 'Create new' : 'Update')),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            ),
        elevation: 5,
        isScrollControlled: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Test App",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 10,
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        // Ensure ListView gets full available size
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _items.length,
          scrollDirection: Axis.vertical,
          itemBuilder: (_, index) {
            final currentItem = _items[index];
            return Card(
              margin: const EdgeInsets.all(10),
              color: Colors.lightBlueAccent,
              elevation: 10,
              child: ListTile(
                title: Text(currentItem['name']),
                subtitle: Text(currentItem['quantity'].toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min, // Constrain Row size
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showForm(context, currentItem['key']);
                      },
                      child: const Icon(Icons.edit),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    GestureDetector(
                      onTap: () {
                        _deleteItem(currentItem['key']);
                      },
                      child: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showForm(context, null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
