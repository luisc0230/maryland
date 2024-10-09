import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditBarberScreen extends StatefulWidget {
  final String barberId; // El ID del barbero que estamos editando

  EditBarberScreen({required this.barberId});

  @override
  _EditBarberScreenState createState() => _EditBarberScreenState();
}

class _EditBarberScreenState extends State<EditBarberScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para cada campo
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  String? _imageUrl; // Para almacenar la URL de la imagen
  File? _imageFile; // Para almacenar la imagen local

  @override
  void initState() {
    super.initState();
    _loadBarberData(); // Cargar los datos del barbero al inicializar
  }

  // Método para cargar los datos del barbero desde Firestore
  Future<void> _loadBarberData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('barbers')
        .doc(widget.barberId)
        .get();
    if (doc.exists) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _phoneNumberController.text = data['phoneNumber'] ?? '';
        setState(() {
          _imageUrl = data['imageUrl'];
        });
      }
    }
  }

  // Método para seleccionar una imagen
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Método para subir la imagen a Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl; // Si no seleccionamos una imagen, mantenemos la existente
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('barber_images')
        .child('${widget.barberId}.jpg');
    await storageRef.putFile(_imageFile!);
    return await storageRef.getDownloadURL();
  }

  // Método para actualizar los datos del barbero en Firestore
  Future<void> _saveBarber() async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl = await _uploadImage();

      await FirebaseFirestore.instance
          .collection('barbers')
          .doc(widget.barberId)
          .update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'phoneNumber': _phoneNumberController.text,
        'imageUrl': imageUrl ?? '',
      });

      Navigator.pop(context); // Volver a la pantalla anterior después de guardar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Barbero'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Mostrar la imagen si existe, si no, mostrar "Sin foto"
              if (_imageUrl != null && _imageUrl!.isNotEmpty)
                Image.network(
                  _imageUrl!,
                  height: 150,
                )
              else if (_imageFile != null) // Si se seleccionó una nueva imagen, mostrarla
                Image.file(
                  _imageFile!,
                  height: 150,
                )
              else
                Center(
                  child: Text(
                    'Sin foto',
                    style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                  ),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Seleccionar Imagen'),
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
                child: Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
