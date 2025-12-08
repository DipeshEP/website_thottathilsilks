// import 'dart:io';
// import 'dart:typed_data';

// class Product {
//   final String id;
//   final String name;
//   final String price;
//   final String? imageUrl;
//   final File? imageFile;
//   Uint8List? imageBytes;   // For web
//   final bool isCustom;
  
//   // New fields
//   final String? productCode;
//   final String? size;
//   final String? quantity;
//   final String? category;
//   final String? supplier;
//   final String? description;

//   Product({
//     required this.id,
//     required this.name,
//     required this.price,
//     this.imageUrl,
//     this.imageFile,
//     this.imageBytes,
//     this.isCustom = false,
//     this.productCode,
//     this.size,
//     this.quantity,
//     this.category,
//     this.supplier,
//     this.description,
//   });
// }

//
//
//
// class Product {
//   final String id;
//   final String name;
//   final String category;
//   final CreatedDetails createdDetails;
//   final String description;
//   final String imageType;
//   final List<String> images;
//   final int quantity;
//   final double price;
//   final String productCode;
//   final String size;
//   final LastUpdate lastUpdate;
//   final LastDelete lastDelete;
//   final String supplier;
//
//   Product({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.createdDetails,
//     required this.description,
//     required this.imageType,
//     required this.images,
//     required this.quantity,
//     required this.price,
//     required this.productCode,
//     required this.size,
//     required this.lastUpdate,
//     required this.lastDelete,
//     required this.supplier,
//   });
//
//   // ---------------------------- FROM FIRESTORE ----------------------------
//   factory Product.fromFirestore(doc) {
//     final data = doc.data() as Map<String, dynamic>;
//
//     return Product(
//       id: doc.id,
//       name: data["product_name"]?.toString() ?? "",
//       category: data["category"]?.toString() ?? "",
//       description: data["description"]?.toString() ?? "",
//
//       // SAFE STRING (even if Firestore has list/map)
//       imageType: data["image"]?.toString() ?? "",
//
//       // SAFE LIST
//       images: data["images"] is List
//           ? List<String>.from(data["images"])
//           : [],
//
//       // ensure int
//       quantity: data["quantity"] is int
//           ? data["quantity"]
//           : int.tryParse(data["quantity"]?.toString() ?? "0") ?? 0,
//
//       // ensure double
//       price: (data["price"] is num)
//           ? data["price"].toDouble()
//           : double.tryParse(data["price"]?.toString() ?? "0") ?? 0.0,
//
//       productCode: data["product_code"]?.toString() ?? "",
//       size: data["size"]?.toString() ?? "",
//       supplier: data["supplier"]?.toString() ?? "",
//
//       createdDetails: CreatedDetails(
//         createdDate: data["created_details"]?["created_date"]?.toString() ?? "",
//         createdBy: data["created_details"]?["created_by"]?.toString() ?? "",
//       ),
//
//       // lastUpdate: LastUpdate(
//       //   createdDate: data["last_update"]?["last_updated_date"]?.toString() ?? "",
//       //   createdBy: data["last_update"]?["last_updated_id"]?.toString() ?? "",
//       // ),
//       lastUpdate: LastUpdate(
//         createdDate: data["last_update"]?["date"]?.toString() ?? "",
//         createdBy: data["last_update"]?["updated_by"]?.toString() ?? "",
//       ),
//
//
//       lastDelete: LastDelete(
//         createdDate: data["last_delete"]?["deleted_date"]?.toString() ?? "",
//         createdBy: data["last_delete"]?["deleted_id"]?.toString() ?? "",
//       ),
//     );
//   }
//
//   // ---------------------------- TO FIRESTORE ----------------------------
//   Map<String, dynamic> toFirestore() {
//     return {
//       "product_name": name,
//       "category": category,
//       "description": description,
//       "image": imageType,
//       "images": images,
//       "quantity": quantity,
//       "price": price,
//       "product_code": productCode,
//       "size": size,
//       "supplier": supplier,
//
//       "created_details": {
//         "created_date": createdDetails.createdDate,
//         "created_by": createdDetails.createdBy,
//       },
//
//       // "last_update": {
//       //   "last_updated_date": lastUpdate.createdDate,
//       //   "last_updated_id": lastUpdate.createdBy,
//       // },
//       "last_update": {
//         "date": lastUpdate.createdDate,
//         "updated_by": lastUpdate.createdBy,
//       },
//
//
//
//       "last_delete": {
//         "deleted_date": lastDelete.createdDate,
//         "deleted_id": lastDelete.createdBy,
//       },
//     };
//   }
// }
//
// // -----------------------------------------------------------------------------
// // NESTED MODELS
// // -----------------------------------------------------------------------------
//
// class CreatedDetails {
//   final String createdDate;
//   final String createdBy;
//
//   CreatedDetails({
//     required this.createdDate,
//     required this.createdBy,
//   });
// }
//
// class LastUpdate {
//   final String createdDate;
//   final String createdBy;
//
//   LastUpdate({
//     required this.createdDate,
//     required this.createdBy,
//   });
// }
//
// class LastDelete {
//   final String createdDate;
//   final String createdBy;
//
//   LastDelete({
//     required this.createdDate,
//     required this.createdBy,
//   });
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final CreatedDetails createdDetails;
  final String description;
  final String imageType;
  final List<String> images;
  final int quantity;
  final double price;
  final String productCode;
  final String size;
  final LastUpdate lastUpdate;
  final LastDelete lastDelete;
  final String supplier;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.createdDetails,
    required this.description,
    required this.imageType,
    required this.images,
    required this.quantity,
    required this.price,
    required this.productCode,
    required this.size,
    required this.lastUpdate,
    required this.lastDelete,
    required this.supplier,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper to parse String / Timestamp / null
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime(1970);
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime(1970);
      return DateTime(1970);
    }

    return Product(
      id: doc.id,
      name: data["product_name"]?.toString() ?? "",
      category: data["category"]?.toString() ?? "",
      description: data["description"]?.toString() ?? "",
      imageType: data["image"]?.toString() ?? "",
      images: data["images"] is List ? List<String>.from(data["images"]) : [],
      quantity: data["quantity"] is int
          ? data["quantity"]
          : int.tryParse(data["quantity"]?.toString() ?? "0") ?? 0,
      price: (data["price"] is num)
          ? data["price"].toDouble()
          : double.tryParse(data["price"]?.toString() ?? "0") ?? 0.0,
      productCode: data["product_code"]?.toString() ?? "",
      size: data["size"]?.toString() ?? "",
      supplier: data["supplier"]?.toString() ?? "",

      // ✔ Updated: created_at as DateTime
      createdDetails: CreatedDetails(
        createdDate: parseDate(data["created_details"]?["created_date"]),
        createdBy: data["created_details"]?["created_by"]?.toString() ?? "",
      ),

      // ✔ Already works
      lastUpdate: LastUpdate(
        createdDate: parseDate(data["last_update"]?["date"]),
        createdBy: data["last_update"]?["updated_by"]?.toString() ?? "unknown",
      ),

      // ✔ Updated: deleted_at as DateTime
      lastDelete: LastDelete(
        createdDate: parseDate(data["last_delete"]?["deleted_date"]),
        createdBy: data["last_delete"]?["deleted_id"]?.toString() ?? "",
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "product_name": name,
      "category": category,
      "description": description,
      "image": imageType,
      "images": images,
      "quantity": quantity,
      "price": price,
      "product_code": productCode,
      "size": size,
      "supplier": supplier,

      // ✔ Save as ISO string
      "created_details": {
        "created_date": createdDetails.createdDate.toIso8601String(),
        "created_by": createdDetails.createdBy,
      },

      "last_update": {
        "date": lastUpdate.createdDate.toIso8601String(),
        "updated_by": lastUpdate.createdBy,
      },

      "last_delete": {
        "deleted_date": lastDelete.createdDate.toIso8601String(),
        "deleted_id": lastDelete.createdBy,
      },
    };
  }
}

// ---------------------- Updated nested classes ----------------------

class CreatedDetails {
  final DateTime createdDate;   // Updated to DateTime
  final String createdBy;

  CreatedDetails({
    required this.createdDate,
    required this.createdBy,
  });
}

class LastUpdate {
  final DateTime createdDate;
  final String createdBy;

  LastUpdate({
    required this.createdDate,
    required this.createdBy,
  });
}

class LastDelete {
  final DateTime createdDate;  // Updated to DateTime
  final String createdBy;

  LastDelete({
    required this.createdDate,
    required this.createdBy,
  });
}

// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class Product {
//   final String id;
//   final String name;
//   final String category;
//   final CreatedDetails createdDetails;
//   final String description;
//   final String imageType;
//   final List<String> images;
//   final int quantity;
//   final double price;
//   final String productCode;
//   final String size;
//   final LastUpdate lastUpdate;  // Now uses DateTime!
//   final LastDelete lastDelete;
//   final String supplier;
//
//   Product({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.createdDetails,
//     required this.description,
//     required this.imageType,
//     required this.images,
//     required this.quantity,
//     required this.price,
//     required this.productCode,
//     required this.size,
//     required this.lastUpdate,
//     required this.lastDelete,
//     required this.supplier,
//   });
//
//   factory Product.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//
//     // Helper to safely parse date string or Timestamp
//     DateTime parseDate(dynamic dateValue) {
//       if (dateValue == null) return DateTime(1970);
//       if (dateValue is Timestamp) return dateValue.toDate();
//       if (dateValue is String) {
//         return DateTime.tryParse(dateValue) ?? DateTime(1970);
//       }
//       return DateTime(1970);
//     }
//
//     return Product(
//       id: doc.id,
//       name: data["product_name"]?.toString() ?? "",
//       category: data["category"]?.toString() ?? "",
//       description: data["description"]?.toString() ?? "",
//       imageType: data["image"]?.toString() ?? "",
//       images: data["images"] is List
//           ? List<String>.from(data["images"])
//           : [],
//       quantity: data["quantity"] is int
//           ? data["quantity"]
//           : int.tryParse(data["quantity"]?.toString() ?? "0") ?? 0,
//       price: (data["price"] is num)
//           ? data["price"].toDouble()
//           : double.tryParse(data["price"]?.toString() ?? "0") ?? 0.0,
//       productCode: data["product_code"]?.toString() ?? "",
//       size: data["size"]?.toString() ?? "",
//       supplier: data["supplier"]?.toString() ?? "",
//
//       createdDetails: CreatedDetails(
//         createdDate: data["created_details"]?["created_date"]?.toString() ?? "",
//         createdBy: data["created_details"]?["created_by"]?.toString() ?? "",
//       ),
//
//       lastUpdate: LastUpdate(
//         // This is the key fix: parse string like "2025-11-28T17:30:15.044809"
//         createdDate: parseDate(data["last_update"]?["date"]),
//         createdBy: data["last_update"]?["updated_by"]?.toString() ?? "unknown",
//       ),
//
//       lastDelete: LastDelete(
//         createdDate: data["last_delete"]?["deleted_date"]?.toString() ?? "",
//         createdBy: data["last_delete"]?["deleted_id"]?.toString() ?? "",
//       ),
//     );
//   }
//
//   Map<String, dynamic> toFirestore() {
//     return {
//       "product_name": name,
//       "category": category,
//       "description": description,
//       "image": imageType,
//       "images": images,
//       "quantity": quantity,
//       "price": price,
//       "product_code": productCode,
//       "size": size,
//       "supplier": supplier,
//
//       "created_details": {
//         "created_date": createdDetails.createdDate,
//         "created_by": createdDetails.createdBy,
//       },
//
//       "last_update": {
//         "date": lastUpdate.createdDate.toIso8601String(), // Save as ISO string
//         "updated_by": lastUpdate.createdBy,
//       },
//
//       "last_delete": {
//         "deleted_date": lastDelete.createdDate,
//         "deleted_id": lastDelete.createdBy,
//       },
//     };
//   }
// }
//
// // Updated nested classes
//
// class CreatedDetails {
//   final String createdDate;
//   final String createdBy;
//
//   CreatedDetails({required this.createdDate, required this.createdBy});
// }
//
// class LastUpdate {
//   final DateTime createdDate;  // Now DateTime, not String!
//   final String createdBy;
//
//   LastUpdate({required this.createdDate, required this.createdBy});
// }
//
// class LastDelete {
//   final String createdDate;
//   final String createdBy;
//
//   LastDelete({required this.createdDate, required this.createdBy});
// }