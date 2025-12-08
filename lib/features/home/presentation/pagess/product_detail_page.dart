import 'package:flutter/material.dart';

import '../../../../core/constants/colour_constants.dart';
import '../../data/model/product_model.dart';

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
        // Action Buttons
        // Row(
        //   children: [
        //     Expanded(
        //       child: ElevatedButton(
        //         onPressed: () {
        //           // Add to cart functionality
        //         },
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: WebColours.buttonColour,
        //           foregroundColor: WebColours.whiteColor,
        //           padding: const EdgeInsets.symmetric(vertical: 20),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(8),
        //           ),
        //           elevation: 4,
        //         ),
        //         child: const Text(
        //           'ADD TO CART',
        //           style: TextStyle(
        //             fontSize: 14,
        //             fontWeight: FontWeight.w600,
        //             letterSpacing: 1.5,
        //           ),
        //         ),
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     Container(
        //       decoration: BoxDecoration(
        //         border: Border.all(
        //           color: isLiked ? Colors.red : WebColours.grayColour300,
        //           width: 2,
        //         ),
        //         borderRadius: BorderRadius.circular(8),
        //         color: isLiked ? Colors.red.withOpacity(0.1) : null,
        //       ),
        //       child: IconButton(
        //         icon: Icon(
        //           isLiked ? Icons.favorite : Icons.favorite_border,
        //           color: isLiked ? Colors.red : WebColours.grayColour600,
        //         ),
        //         onPressed: () {
        //           setState(() {
        //             isLiked = !isLiked;
        //           });
        //         },
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 24),
        // Additional Info
        // Container(
        //   decoration: BoxDecoration(
        //     gradient: const LinearGradient(
        //       colors: [WebColours.gradientStart, WebColours.gradientEnd],
        //       begin: Alignment.centerLeft,
        //       end: Alignment.centerRight,
        //     ),
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   padding: const EdgeInsets.all(16),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: const [
        //       Text(
        //         'Free Shipping',
        //         style: TextStyle(
        //           color: Colors.white,
        //           fontSize: 14,
        //           fontWeight: FontWeight.w600,
        //         ),
        //       ),
        //       SizedBox(height: 4),
        //       Text(
        //         'On orders over \$100. Delivered in 3-5 business days.',
        //         style: TextStyle(
        //           color: Colors.white,
        //           fontSize: 12,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
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
}