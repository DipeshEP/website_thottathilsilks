import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/colour_constants.dart';
import '../../data/model/product_model.dart';
import 'edit_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  
  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int selectedImageIndex = 0;
  bool isLiked = false;
  bool _isDeleting = false;
  
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  List<String> get productImages {
    if (widget.product.images.isNotEmpty) {
      return widget.product.images;
    } else if (widget.product.imageType.isNotEmpty) {
      return [widget.product.imageType];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebColours.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 900;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1400),
                padding: EdgeInsets.all(isDesktop ? 64 : 16),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildImageSection()),
                          const SizedBox(width: 80),
                          Expanded(child: _buildDetailsSection(context)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildImageSection(),
                          const SizedBox(height: 32),
                          _buildDetailsSection(context),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection() {
    if (productImages.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: WebColours.grayColour200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 100),
        ),
      );
    }

    return Column(
      children: [
        // Main Image
        Container(
          decoration: BoxDecoration(
            color: WebColours.whiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                productImages[selectedImageIndex],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: WebColours.grayColour200,
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (productImages.length > 1) ...[
          const SizedBox(height: 16),
          // Thumbnail Images
          Row(
            children: List.generate(productImages.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == productImages.length - 1 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImageIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: WebColours.whiteColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedImageIndex == index
                              ? WebColours.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: selectedImageIndex == index
                            ? [
                                BoxShadow(
                                  color: WebColours.primaryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            productImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: WebColours.grayColour200,
                                child: const Icon(Icons.image_not_supported, size: 30),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Close Button
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
            color: WebColours.grayColour600,
          ),
        ),
        const SizedBox(height: 16),
        // Category & Title
        Text(
          widget.product.category.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: WebColours.grayColour600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: WebColours.primaryColor,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.product.productCode.isNotEmpty)
          Text(
            'Product Code: ${widget.product.productCode}',
            style: TextStyle(
              fontSize: 14,
              color: WebColours.grayColour600,
            ),
          ),
        const SizedBox(height: 32),
        // Specifications
        if (widget.product.size.isNotEmpty)
          _buildSpecRow('SIZE', widget.product.size),
        if (widget.product.supplier.isNotEmpty)
          _buildSpecRow('SUPPLIER', widget.product.supplier),
        if (widget.product.quantity > 0)
          _buildSpecRow('QUANTITY', widget.product.quantity.toString()),
        _buildSpecRow('CATEGORY', widget.product.category),
        const SizedBox(height: 32),
        // Description
        if (widget.product.description.isNotEmpty) ...[
          Text(
            'DESCRIPTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: WebColours.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: TextStyle(
              fontSize: 14,
              color: WebColours.grayColour600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
        ],
        // Price
        Text(
          '\₹${widget.product.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: WebColours.primaryColor,
          ),
        ),
        const SizedBox(height: 32),
        // Action Buttons - Edit and Delete
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToEditPage(context),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text(
                  'EDIT PRODUCT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebColours.buttonColour,
                  foregroundColor: WebColours.whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDeleting ? null : () => _showDeleteConfirmation(context),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.delete, size: 18),
                label: Text(
                  _isDeleting ? 'DELETING...' : 'DELETE PRODUCT',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: WebColours.whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: WebColours.grayColour200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: WebColours.primaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: WebColours.grayColour600,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: widget.product),
      ),
    );

    // If product was updated, refresh the detail page
    if (result == true && mounted) {
      // Optionally refresh the product data or navigate back
      Navigator.pop(context, true); // Pass true to indicate product was updated
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "${widget.product.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteProduct(context);
    }
  }

  Future<void> _deleteProduct(BuildContext context) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Permanently delete the product from Firestore
      await _firestore.collection("products").doc(widget.product.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product deleted successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );

        // Navigate back and indicate product was deleted
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Delete error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting product: $e"),
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
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}