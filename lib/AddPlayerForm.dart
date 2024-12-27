import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import 'package:operatorapp/colors.dart';

class AddPlayerForm extends StatefulWidget {
  final String? playerId; // If null, it's a new player
  const AddPlayerForm({super.key, this.playerId});

  @override
  State<AddPlayerForm> createState() => _AddPlayerFormState();
}

class _AddPlayerFormState extends State<AddPlayerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _scoreController = TextEditingController();
  final _wicketsController = TextEditingController();
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    if (widget.playerId != null) {
      _loadPlayerDetails();
    }
  }

  Future<void> _loadPlayerDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('players')
        .doc(widget.playerId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _nameController.text = data['name'];
          _ageController.text = data['age'].toString();
          _scoreController.text = data['total_score'].toString();
          _wicketsController.text = data['wickets'].toString();
          _imageBase64 = data['image_base64'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = File(pickedFile.path).readAsBytesSync();
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _imageBase64 = base64Encode(bytes);
        });
      }
    }
  }

  Future<void> _savePlayer() async {
    if (!_formKey.currentState!.validate()) return;

    final playerData = {
      'name': _nameController.text,
      'age': int.parse(_ageController.text),
      'total_score': int.parse(_scoreController.text),
      'wickets': int.parse(_wicketsController.text),
      'image_base64': _imageBase64 ?? '',
    };

    try {
      if (widget.playerId == null) {
        await FirebaseFirestore.instance.collection('players').add(playerData);
      } else {
        await FirebaseFirestore.instance
            .collection('players')
            .doc(widget.playerId)
            .update(playerData);
      }
      // Check if the widget is still mounted before popping
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle error, maybe show a snackbar or dialog
      print('Error saving player: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the desired color for the back button
        ),
        backgroundColor: AppColors.backgroundColor,
        title: Text(
          widget.playerId == null ? 'Add Player' : 'Edit Player',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 5,
          color: AppColors.cardBaground,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Name',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter a name' : null,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Number',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        hintText: 'NUmber',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter an age' : null,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Score',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _scoreController,
                      decoration: InputDecoration(
                        hintText: 'Score',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter the total score' : null,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Wickets',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _wicketsController,
                      decoration: InputDecoration(
                        hintText: 'Wickets',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter wickets' : null,
                    ),
                    const SizedBox(height: 16),
                    _imageBase64 != null && _imageBase64!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.memory(
                              base64Decode(_imageBase64!),
                              height: 100,
                              width: 100,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              color: Colors.white,
                              height: 50,
                              width: 50,
                              child: Icon(
                                Icons.person,
                              ),
                            ),
                          ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(
                        Icons.image,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Upload Image',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: MediaQuery.sizeOf(context).width * 0.5,
                      height: 45,
                      decoration: BoxDecoration(
                          color: Color(0xff26278D),
                          borderRadius: BorderRadius.circular(20)),
                      child: ElevatedButton(
                        onPressed: _savePlayer,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save Player',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: StadiumBorder(),
                          backgroundColor: Colors.transparent,
                          disabledForegroundColor:
                              Colors.transparent.withOpacity(0.38),
                          disabledBackgroundColor:
                              Colors.transparent.withOpacity(0.12),
                          shadowColor: Colors.transparent,
                          //make color or elevated button transparent
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
