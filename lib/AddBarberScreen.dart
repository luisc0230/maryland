import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddBarberScreen extends StatefulWidget {
  @override
  _AddBarberScreenState createState() => _AddBarberScreenState();
}

class _AddBarberScreenState extends State<AddBarberScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para cada campo
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  File? _imageFile; // Para almacenar la imagen local

  // Método para seleccionar una imagen
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Método para subir la imagen a Firebase Storage, si existe
  Future<String?> _uploadImage(String barberId) async {
    if (_imageFile == null) return null; // Si no seleccionamos una imagen, no subimos nada
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('barber_images')
        .child('$barberId.jpg');
    await storageRef.putFile(_imageFile!);
    return await storageRef.getDownloadURL();
  }

  // Método para guardar el barbero en Firestore
  Future<void> _saveBarber() async {
    if (_formKey.currentState!.validate()) {
      DocumentReference barberRef = FirebaseFirestore.instance.collection('barbers').doc();

      String? imageUrl = await _uploadImage(barberRef.id); // Subir imagen si existe

      await barberRef.set({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'phoneNumber': _phoneNumberController.text,
        'imageUrl': imageUrl ?? '', // Si no hay imagen, dejamos el campo vacío
      });

      Navigator.pop(context); // Volver a la pantalla anterior después de guardar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Barbero'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_imageFile != null) // Mostrar la imagen seleccionada, si existe
                Image.file(
                  _imageFile!,
                  height: 150,
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Seleccionar Imagen (Opcional)'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Número de Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un número de teléfono';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveBarber,
                child: Text('Agregar Barbero'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
