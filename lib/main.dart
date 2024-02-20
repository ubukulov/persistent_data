import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:http/http.dart' as http;

part 'main.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  runApp(MyApp(database));
}

@entity
class User {
  @PrimaryKey(autoGenerate: true)
  final int id;

  final String firstName;
  final String lastName;
  final int age;
  final Uint8List image;
  final String phone;
  final String cardData;

  User(this.id, this.firstName, this.lastName, this.age, this.image, this.phone, this.cardData);
}

@dao
abstract class UserDao {
  @Query('SELECT * FROM User')
  Future<List<User>> findAllUsers();

  @insert
  Future<void> insertUser(User user);

  @delete
  Future<void> deleteUser(User user);

  @update
  Future<void> updateUser(User user);
}

@Database(version: 1, entities: [User])
abstract class AppDatabase extends FloorDatabase {
  UserDao get userDao;
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  MyApp(this.database);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'База пользователей',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserListScreen(database.userDao),
    );
  }
}

class UserListScreen extends StatefulWidget {
  final UserDao userDao;

  UserListScreen(this.userDao);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {

  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await widget.userDao.findAllUsers();
    setState(() {
      _users = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список пользователей'),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: user.image != null ? Image.memory(user.image) : Icon(Icons.person),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Text('Age: ${user.age}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                await widget.userDao.deleteUser(user);
                _fetchUsers();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddUserScreen(widget.userDao)),
          ).then((_) => _fetchUsers());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddUserScreen extends StatefulWidget {
  final UserDao userDao;

  AddUserScreen(this.userDao);

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardDataController = TextEditingController();

  Uint8List? _imageBytes;

  Future<void> _loadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        _imageBytes = response.bodyBytes;
      });
    } else {
      print('Failed to load image: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить пользователя'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'Имя'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Фамилия'),
            ),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Возраст'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Телефон'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _cardDataController,
              decoration: InputDecoration(labelText: 'Карта'),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                //_loadImage('https://paywin.kz/images/1.jpg');
                _loadImage('https://paywin.kz/images/2.jpg');
                final firstName = _firstNameController.text;
                final lastName = _lastNameController.text;
                final age = int.tryParse(_ageController.text) ?? 0;
                final phone = _phoneController.text;
                final cardData = _cardDataController.text;
                final newUser = User(2, firstName, lastName, age, _imageBytes!, phone, cardData);
                await widget.userDao.insertUser(newUser);
                Navigator.pop(context);
              },
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
