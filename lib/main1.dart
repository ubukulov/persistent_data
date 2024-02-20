import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RecordAdapter());
  await Hive.openBox('categories');
  await Hive.openBox('records');
  runApp(MyApp());
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 0;

  @override
  Category read(BinaryReader reader) {
    return Category(reader.readString());
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeString(obj.name);
  }
}

class RecordAdapter extends TypeAdapter<Record> {
  @override
  final int typeId = 1;

  @override
  Record read(BinaryReader reader) {
    return Record(reader.readString(), reader.readString(), reader.readString());
  }

  @override
  void write(BinaryWriter writer, Record obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeString(obj.categoryName);
  }
}


class Category {
  String name;

  Category(this.name);
}

class Record {
  String name;
  String description;
  String categoryName;

  Record(this.name, this.description, this.categoryName);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Records App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CategoryListScreen(),
    );
  }
}

class CategoryListScreen extends StatelessWidget {

  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Список категории')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('categories').listenable(),
        builder: (context, Box box, _) {
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              Category category = box.getAt(index);
              return ListTile(
                title: Text(category.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecordListScreen(category: category)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Добавить категорию'),
                content: TextField(
                  controller: _categoryController,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      Hive.box('categories').add(Category(_categoryController.text));
                      Navigator.of(context).pop();
                      _categoryController.text = '';
                    },
                    child: Text('Добавить'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class RecordListScreen extends StatelessWidget {
  final Category category;

  final TextEditingController _recordNameController = TextEditingController();
  final TextEditingController _recordDescController = TextEditingController();

  RecordListScreen({required this.category});

  @override
  void dispose() {
    _recordNameController.dispose();
    _recordDescController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('records').listenable(),
        builder: (context, Box box, _) {
          // List<Record> records = box.values.where((record) => record.category == category.name).toList();
          List<Record> records = List<Record>.from(box.values.where((record) => record.categoryName == category.name));
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              Record record = records[index];
              return ListTile(
                title: Text(record.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecordDetailScreen(record: record)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Добавить запись'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Названия'),
                      controller: _recordNameController,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Описание'),
                      controller: _recordDescController,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      Hive.box('records').add(Record(_recordNameController.text, _recordDescController.text, category.name));
                      Navigator.of(context).pop();
                      _recordDescController.text = '';
                      _recordNameController.text = '';
                    },
                    child: Text('Добавить'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class RecordDetailScreen extends StatelessWidget {
  final Record record;

  RecordDetailScreen({required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(record.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Названия: ${record.name}'),
            SizedBox(height: 8),
            Text('Описание: ${record.description}'),
          ],
        ),
      ),
    );
  }
}