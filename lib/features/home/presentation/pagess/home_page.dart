
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' as Firebase;

import '../../../../core/constants/colour_constants.dart';
import '../../data/model/product_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Remove static products, use Firebase data
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoadingProducts = false;
  String _selectedFilter = 'All Products'; // Add this - filter options: 'All Products', 'This Month', 'This Week'

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  // Add new controllers
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _webImageBytes;   // Web image
  bool _isLoading = false;  // Add loading state
  
  // Scroll controller for navigation
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contactSectionKey = GlobalKey();
  
  // Firebase instances - use getters for lazy initialization
  FirebaseStorage get _storage => FirebaseStorage.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Add small delay to ensure Firebase is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        getAllProducts();
      }
    });
  }

  Future<void> getAllProducts() async {
    if (!mounted) return;
    
    // Check if Firebase is initialized
    if (Firebase.Firebase.apps.isEmpty) {
      print("Firebase not initialized");
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Firebase not initialized. Please check your configuration."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      print("Fetching products from Firestore...");
      final snapshot = await FirebaseFirestore.instance
          .collection("products")
          .get();
      
      print("Products fetched: ${snapshot.docs.length} documents");
      
      if (!mounted) return;
      
      setState(() {
        _allProducts = snapshot.docs.map((doc) {
          try {
            return Product.fromFirestore(doc);
          } catch (e) {
            print("Error parsing product ${doc.id}: $e");
            print("Document data: ${doc.data()}");
            return null;
          }
        }).whereType<Product>().toList();
        
        // Sort products by last update date (newest first)
        _allProducts.sort((a, b) => b.lastUpdate.createdDate.compareTo(a.lastUpdate.createdDate));
        
        _filteredProducts = _filteredProductsByPeriod;
        _isLoadingProducts = false;
        
        print("Successfully loaded ${_allProducts.length} products");
      });
    } catch (e, stackTrace) {
      print("Error fetching products: $e");
      print("Stack trace: $stackTrace");
      
      if (mounted) {
        setState(() {
          _allProducts = [];
          _filteredProducts = [];
          _isLoadingProducts = false;
        });
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load products: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Method to scroll to top
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
  
  // Method to scroll to contact section
  void _scrollToContact() {
    final context = _contactSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Future<void> _pickImage() async {
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     setState(() {
  //       _selectedImage = File(image.path);
  //     });
  //   }
  // }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        _webImageBytes = await picked.readAsBytes();
        _selectedImage = null;
      } else {
        _selectedImage = File(picked.path);
        _webImageBytes = null;
      }
    }

    setState(() {});
  }


  // void _showAddProductDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setDialogState) {
  //           return AlertDialog(
  //             title: const Text('Add New Product'),
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text('Product Image', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
  //                   const SizedBox(height: 8),
  //                   GestureDetector(
  //                     onTap: () async {
  //                       await _pickImage();
  //                       setDialogState(() {});
  //                     },
  //                     child: Container(
  //                       width: double.infinity,
  //                       height: 150,
  //                       decoration: BoxDecoration(
  //                         border: Border.all(color: Colors.grey.shade300, width: 2),
  //                         borderRadius: BorderRadius.circular(8),
  //                         color: Colors.grey.shade100,
  //                       ),
  //                       child: _selectedImage != null
  //                           ? ClipRRect(
  //                         borderRadius: BorderRadius.circular(8),
  //                         child: Image.file(_selectedImage!, fit: BoxFit.cover),
  //                       )
  //                           : Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Icon(Icons.upload, size: 40, color: Colors.grey.shade400),
  //                           const SizedBox(height: 8),
  //                           Text('Click to upload image', style: TextStyle(color: Colors.grey.shade600)),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 16),
  //                   const Text('Product Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
  //                   const SizedBox(height: 8),
  //                   TextField(
  //                     controller: _nameController,
  //                     decoration: InputDecoration(
  //                       hintText: 'Enter product name',
  //                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
  //                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 16),
  //                   const Text('Price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
  //                   const SizedBox(height: 8),
  //                   TextField(
  //                     controller: _priceController,
  //                     decoration: InputDecoration(
  //                       hintText: '\$0.00',
  //                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
  //                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   _nameController.clear();
  //                   _priceController.clear();
  //                   setState(() {
  //                     _selectedImage = null;
  //                   });
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: const Text('CANCEL'),
  //               ),
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: const Color(0xFF2D3748),
  //                 ),
  //                 onPressed: () {
  //                   if (_nameController.text.isNotEmpty &&
  //                       _priceController.text.isNotEmpty &&
  //                       _selectedImage != null) {
  //                     setState(() {
  //                       _products.add(Product(
  //                         id: DateTime.now().millisecondsSinceEpoch.toString(),
  //                         name: _nameController.text.toUpperCase(),
  //                         price: _priceController.text.startsWith('\$')
  //                             ? _priceController.text
  //                             : '\$${_priceController.text}',
  //                         imageFile: _selectedImage,
  //                         isCustom: true,
  //                       ));
  //                     });
  //                     _nameController.clear();
  //                     _priceController.clear();
  //                     setState(() {
  //                       _selectedImage = null;
  //                     });
  //                     Navigator.of(context).pop();
  //                   }
  //                 },
  //                 child: const Text('ADD PRODUCT'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    const Text(
                      'Product Image *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        await _pickImage();
                        setDialogState(() {});
                      },
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: WebColours.grayColour300, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: WebColours.grayColour100,
                        ),
                        child: _webImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
                              )
                            : _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload, size: 40, color: WebColours.grayColour400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Click to upload image',
                                        style: TextStyle(color: WebColours.grayColour600),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
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
                  ],
                ),
              ),
              // BUTTONS
              actions: [
                TextButton(
                  onPressed: () {
                    _clearAllFields();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: WebColours.grayColour700,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebColours.buttonColour,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _isLoading ? null : () => _submitForm(context),
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
                          'ADD PRODUCT',
                          style: TextStyle(
                            color: WebColours.whiteColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _validateFields() {
    return _nameController.text.isNotEmpty &&
        _productCodeController.text.isNotEmpty &&
        _sizeController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _categoryController.text.isNotEmpty &&
        _supplierController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        (_selectedImage != null || _webImageBytes != null);
  }

  void _clearAllFields() {
    _nameController.clear();
    _priceController.clear();
    _productCodeController.clear();
    _sizeController.clear();
    _quantityController.clear();
    _categoryController.clear();
    _supplierController.clear();
    _descriptionController.clear();
    _selectedImage = null;
    _webImageBytes = null;
  }

  // void _removeProduct(String id) {
  //   setState(() {
  //     _products.removeWhere((product) => product.id == id);
  //   });
  // }

  // Helper method to get filtered products based on selected period
  List<Product> get _filteredProductsByPeriod {
    final now = DateTime.now();
    List<Product> periodFiltered;
    switch (_selectedFilter) {
      case 'This Week':
        final oneWeekAgo = now.subtract(const Duration(days: 7));
        periodFiltered = _allProducts
            .where((product) => product.createdDetails.createdDate.isAfter(oneWeekAgo))
            .toList();
        break;
      case 'This Month':
        final oneMonthAgo = now.subtract(const Duration(days: 30));
        periodFiltered = _allProducts
            .where((product) => product.createdDetails.createdDate.isAfter(oneMonthAgo))
            .toList();
        break;
      case 'All Products':
      default:
        periodFiltered = _allProducts;
    }
    
    // Apply search filter if search query exists
    if (_searchQuery.trim().isEmpty) {
      return periodFiltered;
    }
    
    final query = _searchQuery.toLowerCase().trim();
    return periodFiltered.where((product) {
      // Search in product name
      if (product.name.toLowerCase().contains(query)) return true;
      // Search in product code
      if (product.productCode.toLowerCase().contains(query)) return true;
      // Search in category
      if (product.category.toLowerCase().contains(query)) return true;
      // Search in price (exact match or contains)
      if (product.price.toString().contains(query)) return true;
      // Try to parse query as number and match price
      final priceValue = double.tryParse(query);
      if (priceValue != null && product.price == priceValue) return true;
      return false;
    }).toList();
  }
  
  // Method to perform search
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredProducts = _filteredProductsByPeriod;
    });
  }
  
  // Method to clear search
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filteredProducts = _filteredProductsByPeriod;
    });
  }

  // Helper methods for product summary (using filtered products with search)
  int get _totalProductCount => _filteredProductsByPeriod.length;

  double get _totalPrice {
    return _filteredProductsByPeriod.fold(0.0, (sum, product) => sum + product.price);
  }

  double get _oneMonthAddedProductPrice {
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _allProducts
        .where((product) => product.createdDetails.createdDate.isAfter(oneMonthAgo))
        .fold(0.0, (sum, product) => sum + product.price);
  }

  int get _oneMonthAddedProductCount {
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _allProducts
        .where((product) => product.createdDetails.createdDate.isAfter(oneMonthAgo))
        .length;
  }

  // Helper method to get total price of filtered products (with search)
  double _getTotalPrice() {
    return _filteredProductsByPeriod.fold(0.0, (sum, product) => sum + product.price);
  }

  // Helper method to build stat card widget
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebColours.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebColours.grayColour300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: WebColours.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: WebColours.grayColour600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WebColours.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to check if product is new (added within last week)
  bool _isNewProduct(Product product) {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    return product.createdDetails.createdDate.isAfter(oneWeekAgo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            /// Header
            Container(
              color: const Color(0xFF2D3748),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _scrollToTop,
                        child: const Text('Home', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                      const SizedBox(width: 32),
                      TextButton(
                        onPressed: _scrollToContact,
                        child: const Text('Contact', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                      const SizedBox(width: 32),
                      TextButton(
                        onPressed: _showAddProductDialog,
                        child: const Text('Add Product', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                      const SizedBox(width: 32),
                      // Logout Button - only show if user is logged in
                      if (_auth.currentUser != null)
                        TextButton(
                          onPressed: _handleLogout,
                          // icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                          child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'THOTTATHIL SILKS',
                    style: TextStyle(
                      color: WebColours.whiteColor,
                      fontSize: 32,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            /// Hero Image
            Container(
              height: 300,
              width: double.infinity,
              color: const Color(0xFF2D3748),

              child: Image.network(
                'https://images.pexels.com/photos/1072179/pexels-photo-1072179.jpeg?_gl=1*10skvtj*_ga*MjE0NjYzNDI1MS4xNzYzMzAzODA0*_ga_8JE65Q40S6*czE3NjMzMDM4MDQkbzEkZzEkdDE3NjMzMDM4MTgkajQ2JGwwJGgw',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.8),
              ),
            ),

            // Who We Are Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              child: Column(
                children: [
                  const Text(
                    'Product List',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 32),
                  
                  // Statistics Cards - Responsive Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Use Row for larger screens, Column for mobile
                      final isMobile = constraints.maxWidth < 600;
                      
                      if (isMobile) {
                        // Mobile: Stack vertically
                        return Column(
                          children: [
                            _buildStatCard(
                              'Total Products',
                              _totalProductCount.toString(),
                              Icons.inventory_2,
                            ),
                            const SizedBox(height: 16),
                            _buildStatCard(
                              'Total Price',
                              '₹${_getTotalPrice().toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                            const SizedBox(height: 16),
                            _buildStatCard(
                              'Last Month Price',
                              '₹${_oneMonthAddedProductPrice.toStringAsFixed(2)}',
                              Icons.trending_up,
                            ),
                          ],
                        );
                      } else {
                        // Desktop: Arrange horizontally
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Products',
                                _totalProductCount.toString(),
                                Icons.inventory_2,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Total Price',
                                '₹${_getTotalPrice().toStringAsFixed(2)}',
                                Icons.attach_money,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Last Month Price',
                                '₹${_oneMonthAddedProductPrice.toStringAsFixed(2)}',
                                Icons.trending_up,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  // Beautiful Search and Filter Section
                  Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: WebColours.whiteColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        
                        if (isMobile) {
                          // Mobile: Stack vertically
                          return Column(
                            children: [
                              // Search Section
                              Container(
                                decoration: BoxDecoration(
                                  color: WebColours.grayColour100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: WebColours.grayColour300,
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search products by name, code, category...',
                                    hintStyle: TextStyle(
                                      color: WebColours.grayColour600,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: WebColours.primaryColor,
                                      size: 24,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: WebColours.grayColour600,
                                              size: 20,
                                            ),
                                            onPressed: _clearSearch,
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  onSubmitted: (_) => _performSearch(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Search Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _performSearch,
                                  icon: const Icon(Icons.search, size: 20),
                                  label: const Text(
                                    'Search',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WebColours.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Divider(color: WebColours.grayColour300, height: 1),
                              const SizedBox(height: 20),
                              // Filter Section
                              Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: WebColours.primaryColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Filter by:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: WebColours.grayColour700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: WebColours.grayColour100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: WebColours.grayColour300,
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedFilter,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: WebColours.primaryColor,
                                    size: 28,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: WebColours.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items: ['All Products', 'This Month', 'This Week']
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedFilter = newValue;
                                        _filteredProducts = _filteredProductsByPeriod;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Desktop: Arrange horizontally
                          return Row(
                            children: [
                              // Search Field
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: WebColours.grayColour100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: WebColours.grayColour300,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search products by name, code, category, price...',
                                      hintStyle: TextStyle(
                                        color: WebColours.grayColour600,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: WebColours.primaryColor,
                                        size: 24,
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                color: WebColours.grayColour600,
                                                size: 20,
                                              ),
                                              onPressed: _clearSearch,
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    onSubmitted: (_) => _performSearch(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Search Button
                              ElevatedButton.icon(
                                onPressed: _performSearch,
                                icon: const Icon(Icons.search, size: 20),
                                label: const Text(
                                  'Search',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WebColours.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Divider
                              Container(
                                width: 1,
                                height: 40,
                                color: WebColours.grayColour300,
                              ),
                              const SizedBox(width: 20),
                              // Filter Section
                              Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: WebColours.primaryColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Filter:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: WebColours.grayColour700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: WebColours.grayColour100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: WebColours.grayColour300,
                                        width: 1,
                                      ),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _selectedFilter,
                                      underline: const SizedBox(),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: WebColours.primaryColor,
                                        size: 28,
                                      ),
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: WebColours.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: ['All Products', 'This Month', 'This Week']
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedFilter = newValue;
                                            _filteredProducts = _filteredProductsByPeriod;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  // const SizedBox(height: 24),
                  // TextButton(
                  //   onPressed: () {},
                  //   child: const Text(
                  //     'Add Product →',
                  //     style: TextStyle(letterSpacing: 1.5, fontSize: 12),
                  //   ),
                  // ),
                ],
              ),
            ),

            Divider(color: Colors.grey.shade300, thickness: 1, indent: 40, endIndent: 40),

            /// Featured Products Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              child: Column(
                children: [
                  const Text(
                    'Featured Products',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 48),
                  _isLoadingProducts
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _filteredProducts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text(
                                  'No products available',
                                  style: TextStyle(color: WebColours.grayColour600),
                                ),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = constraints.maxWidth > 900
                                    ? 5
                                    : (constraints.maxWidth > 600 ? 2 : 1);
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.65, // Reduced from 0.8 to make images smaller
                                  ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/product',
                                          arguments: {'product': product},
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          // Image - reduced to half size
                                          Expanded(
                                            flex: 2,
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: WebColours.grayColour200,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: buildProductImage(product),
                                                  ),
                                                ),
                                                // New Arrivals Badge
                                                if (_isNewProduct(product))
                                                  Positioned(
                                                    top: 8,
                                                    left: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [
                                                            WebColours.gradientStart,
                                                            WebColours.gradientEnd,
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.2),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Text(
                                                        'NEW',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          // Product Name
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // const SizedBox(height: 4),
                                          // Product Price
                                          Text(
                                            '₹${product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: WebColours.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                  const SizedBox(height: 48),
                  // OutlinedButton.icon(
                  //   onPressed: _showAddProductDialog,
                  //   icon: const Icon(Icons.upload),
                  //   label: const Text('ADD PRODUCT', style: TextStyle(letterSpacing: 1.5)),
                  //   style: OutlinedButton.styleFrom(
                  //     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  //     side: const BorderSide(color: WebColours.buttonColour, width: 2),
                  //     foregroundColor: WebColours.buttonColour,
                  //   ),
                  // ),
                ],
              ),
            ),

            Divider(color: Colors.grey.shade300, thickness: 1, indent: 40, endIndent: 40),

            /// Newsletter Section
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            //   child: Column(
            //     children: [
            //       const Text(
            //         'SIGN UP FOR OUR NEWSLETTER',
            //         style: TextStyle(fontSize: 16, letterSpacing: 1.5),
            //       ),
            //
            //     ],
            //   ),
            // ),

            /// Footer / Contact Section
            Container(
              key: _contactSectionKey,
              color: WebColours.grayColour300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 768) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFooterColumn('ABOUT US', ['HOME', 'OUR STORY', 'CONTACT'], {
                          'HOME': _scrollToTop,
                        }),
                        _buildFooterColumn('SHOP', ['KITCHEN', 'BATHROOM', 'LAUNDRY', 'ALL ITEMS'], {}),
                        _buildFooterColumn('CUSTOMER INFO', ['SHIPPING AND DELIVERY', 'RETURNS & EXCHANGES'], {}),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFooterColumn('ABOUT US', ['HOME', 'OUR STORY', 'CONTACT'], {
                          'HOME': _scrollToTop,
                        }),
                        const SizedBox(height: 24),
                        _buildFooterColumn('SHOP', ['KITCHEN', 'BATHROOM', 'LAUNDRY', 'ALL ITEMS'], {}),
                        const SizedBox(height: 24),
                        _buildFooterColumn('CUSTOMER INFO', ['SHIPPING AND DELIVERY', 'RETURNS & EXCHANGES'], {}),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductImage(Product product) {
    String? imageUrl;
    
    // Use images list from Firebase (preferred)
    if (product.images.isNotEmpty) {
      imageUrl = product.images.first.trim();
    }
    
    // Fallback to imageType (single image URL)
    if ((imageUrl == null || imageUrl.isEmpty) && product.imageType.trim().isNotEmpty) {
      imageUrl = product.imageType.trim();
    }
    
    // Validate URL
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: WebColours.grayColour200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 12,
                color: WebColours.grayColour600,
              ),
            ),
          ],
        ),
      );
    }
    
    // Check if URL is valid
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      print('Invalid image URL format: $imageUrl');
      return Container(
        color: WebColours.grayColour200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Invalid URL',
              style: TextStyle(
                fontSize: 12,
                color: WebColours.grayColour600,
              ),
            ),
          ],
        ),
      );
    }
    
    // Build image widget
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Image load error for $imageUrl: $error');
          return Container(
            color: WebColours.grayColour200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Failed to load',
                  style: TextStyle(
                    fontSize: 12,
                    color: WebColours.grayColour600,
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            color: WebColours.grayColour200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // Mobile/Desktop
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Image load error for $imageUrl: $error');
          return Container(
            color: WebColours.grayColour200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Failed to load',
                  style: TextStyle(
                    fontSize: 12,
                    color: WebColours.grayColour600,
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            color: WebColours.grayColour200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _submitForm(BuildContext dialogContext) async {
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

    String imageUrl = "";

    // Upload image if selected (works for both web and mobile)
    if (_selectedImage != null || _webImageBytes != null) {
      try {
        final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final ref = FirebaseStorage.instance.ref('products/$fileName');

        if (kIsWeb) {
          // Web: Upload from Uint8List using putData
          if (_webImageBytes != null) {
            await ref.putData(_webImageBytes!);
            imageUrl = await ref.getDownloadURL();
            print("Image uploaded successfully. URL: $imageUrl");
          }
        } else {
          // Mobile (Android/iOS): Upload from File using putFile
          if (_selectedImage != null) {
            await ref.putFile(_selectedImage!);
            imageUrl = await ref.getDownloadURL();
            print("Image uploaded successfully. URL: $imageUrl");
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
    
    // Get current user ID (or use "unknown" if not logged in)
    final userId = _auth.currentUser?.uid ?? "unknown";

    // Product fields
    final Map<String, dynamic> productFields = {
      "product_name": _nameController.text.trim(),
      "category": _categoryController.text.trim(),
      "description": _descriptionController.text.trim(),
      "price": double.tryParse(_priceController.text.trim().replaceAll('₹', '').replaceAll('\$', '').replaceAll(',', '')) ?? 0.0,
      "quantity": int.tryParse(_quantityController.text.trim()) ?? 0,
      "supplier": _supplierController.text.trim(),
      "image": imageUrl, // Save only downloadUrl
      "product_code": _productCodeController.text.trim(),
      "size": _sizeController.text.trim(),
    };

    try {
      // Add new product to Firestore
      await _firestore.collection("products").add({
        ...productFields,
        "created_details": {
          "created_date": nowIso,
          "created_by": userId,
        },
        "last_update": {
          "date": nowIso,
          "updated_by": userId,
        },
        "last_delete": {
          "deleted_date": "",
          "deleted_id": "",
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product added successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }

      // Clear fields and close dialog
      _clearAllFields();
      if (mounted && dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
      
      // Refresh products list
      getAllProducts();
    } catch (e) {
      print("Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add product: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Logged out successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  Widget _buildFooterColumn(String title, List<String> items, Map<String, VoidCallback> clickableItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          final hasOnTap = clickableItems.containsKey(item) && clickableItems[item] != null;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: hasOnTap
                ? GestureDetector(
                    onTap: clickableItems[item],
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        item,
                        style: TextStyle(
                          color: WebColours.primaryColor,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: WebColours.primaryColor,
                        ),
                      ),
                    ),
                  )
                : Text(
                    item,
                    style: TextStyle(color: WebColours.grayColour700, fontSize: 13),
                  ),
          );
        }),
      ],
    );
  }
}