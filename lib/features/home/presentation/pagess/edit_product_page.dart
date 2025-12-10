import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/colour_constants.dart';
import '../../data/model/product_model.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  
  const EditProductPage({
    super.key,
    required this.product,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  File? _selectedImage;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  bool _imageChanged = false;
  
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    _nameController.text = widget.product.name;
    _priceController.text = widget.product.price.toStringAsFixed(2);
    _productCodeController.text = widget.product.productCode;
    _sizeController.text = widget.product.size;
    _quantityController.text = widget.product.quantity.toString();
    _categoryController.text = widget.product.category;
    _supplierController.text = widget.product.supplier;
    _descriptionController.text = widget.product.description;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _productCodeController.dispose();
    _sizeController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _supplierController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        if (kIsWeb) {
          _webImageBytes = null; // Will be set after reading
          _selectedImage = null;
        } else {
          _selectedImage = File(picked.path);
          _webImageBytes = null;
        }
        _imageChanged = true;
      });

      if (kIsWeb) {
        _webImageBytes = await picked.readAsBytes();
      }
      
      setState(() {});
    }
  }

  bool _validateFields() {
    return _nameController.text.isNotEmpty &&
        _productCodeController.text.isNotEmpty &&
        _sizeController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _categoryController.text.isNotEmpty &&
        _supplierController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty;
  }

  Future<void> _submitForm() async {
    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() => _isLoading = true);

    String? imageUrl;
    List<String> imageUrls = widget.product.images.isNotEmpty 
        ? List<String>.from(widget.product.images)
        : (widget.product.imageType.isNotEmpty ? [widget.product.imageType] : []);

    // Upload new image if changed
    if (_imageChanged && (_selectedImage != null || _webImageBytes != null)) {
      try {
        final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final ref = FirebaseStorage.instance.ref('products/$fileName');

        if (kIsWeb) {
          if (_webImageBytes != null) {
            await ref.putData(_webImageBytes!);
            imageUrl = await ref.getDownloadURL();
            print("Image uploaded successfully. URL: $imageUrl");
            imageUrls = [imageUrl];
          }
        } else {
          if (_selectedImage != null) {
            await ref.putFile(_selectedImage!);
            imageUrl = await ref.getDownloadURL();
            print("Image uploaded successfully. URL: $imageUrl");
            imageUrls = [imageUrl];
          }
        }
      } catch (e) {
        print("Image upload failed: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Image upload failed: ${e.toString()}"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    // Current timestamp
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final userId = _auth.currentUser?.uid ?? "unknown";

    // Product fields
    final Map<String, dynamic> productFields = {
      "product_name": _nameController.text.trim(),
      "category": _categoryController.text.trim(),
      "description": _descriptionController.text.trim(),
      "price": double.tryParse(_priceController.text.trim().replaceAll('₹', '').replaceAll('\$', '').replaceAll(',', '')) ?? 0.0,
      "quantity": int.tryParse(_quantityController.text.trim()) ?? 0,
      "supplier": _supplierController.text.trim(),
      "product_code": _productCodeController.text.trim(),
      "size": _sizeController.text.trim(),
    };

    // Update image fields if image was changed
    if (_imageChanged && imageUrl != null) {
      productFields["image"] = imageUrl;
      productFields["images"] = imageUrls;
    }

    try {
      // Update product in Firestore
      await _firestore.collection("products").doc(widget.product.id).update({
        ...productFields,
        "last_update": {
          "date": nowIso,
          "updated_by": userId,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product updated successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }

      // Navigate back with success
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update product: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePreview() {
    if (_imageChanged && (_selectedImage != null || _webImageBytes != null)) {
      return kIsWeb && _webImageBytes != null
          ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
          : _selectedImage != null
              ? Image.file(_selectedImage!, fit: BoxFit.cover)
              : const SizedBox();
    }

    // Show existing image
    final existingImageUrl = widget.product.images.isNotEmpty
        ? widget.product.images.first
        : (widget.product.imageType.isNotEmpty ? widget.product.imageType : null);

    if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
      return Image.network(
        existingImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: WebColours.grayColour200,
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    }

    return Container(
      color: WebColours.grayColour200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 40, color: WebColours.grayColour400),
          const SizedBox(height: 8),
          Text(
            'No image',
            style: TextStyle(color: WebColours.grayColour600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebColours.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: WebColours.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                const Text(
                  'Product Image',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: WebColours.grayColour300, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: WebColours.grayColour100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildImagePreview(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Product Name
                const Text(
                  'Product Name *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter product name',
                    filled: true,
                    fillColor: WebColours.grayColour100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebColours.grayColour300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebColours.grayColour300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: WebColours.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Product Code
                const Text(
                  'Product Code *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _productCodeController,
                  decoration: InputDecoration(
                    hintText: 'Enter product code',
                    filled: true,
                    fillColor: WebColours.grayColour100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebColours.grayColour300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebColours.grayColour300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: WebColours.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Size and Quantity Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Size *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _sizeController,
                            decoration: InputDecoration(
                              hintText: 'e.g., S, M, L',
                              filled: true,
                              fillColor: WebColours.grayColour100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WebColours.grayColour300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WebColours.grayColour300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: WebColours.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quantity *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter quantity',
                              filled: true,
                              fillColor: WebColours.grayColour100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WebColours.grayColour300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WebColours.grayColour300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: WebColours.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Price
                const Text(
                  'Price *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '₹0.00',
                    filled: true,
                    fillColor: WebColours.grayColour100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebColours.grayColour300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebColours.grayColour300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: WebColours.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category and Supplier Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _categoryController,
                            decoration: InputDecoration(
                              hintText: 'Select category',
                              filled: true,
                              fillColor: WebColours.grayColour100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WebColours.grayColour300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WebColours.grayColour300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: WebColours.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supplier *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _supplierController,
                            decoration: InputDecoration(
                              hintText: 'Enter supplier name',
                              filled: true,
                              fillColor: WebColours.grayColour100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WebColours.grayColour300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: WebColours.grayColour300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: WebColours.primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description
                const Text(
                  'Description *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter product description',
                    filled: true,
                    fillColor: WebColours.grayColour100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebColours.grayColour300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebColours.grayColour300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: WebColours.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: WebColours.grayColour700,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WebColours.buttonColour,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(WebColours.whiteColor),
                                ),
                              )
                            : const Text(
                                'UPDATE PRODUCT',
                                style: TextStyle(
                                  color: WebColours.whiteColor,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

