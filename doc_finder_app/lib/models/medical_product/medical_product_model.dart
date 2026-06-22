class MedicalProduct {
  final int id;
  final String name;
  final String? description;
  final String batchNo;
  final String category;
  final String? photo;
  final double cost;
  final String formattedCost;
  final int stockQuantity;
  final String? manufacturer;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final bool needsPrescription;
  final bool isAvailable;
  final String? dosageForm;
  final String? strength;
  final List<String>? sideEffects;
  final List<String>? conditions;
  final List<String>? ingredients;
  final String? storageConditions;
  final String? usageInstructions;
  final String? barcode;
  final double? weight;
  final String unitOfMeasure;
  final int minimumStockLevel;
  final String? supplier;
  final double? purchasePrice;
  final String status;
  final String imageUrl;
  final String availabilityStatus;
  final bool isExpired;
  final int? daysUntilExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalProduct({
    required this.id,
    required this.name,
    this.description,
    required this.batchNo,
    required this.category,
    this.photo,
    required this.cost,
    required this.formattedCost,
    required this.stockQuantity,
    this.manufacturer,
    this.manufacturingDate,
    this.expiryDate,
    required this.needsPrescription,
    required this.isAvailable,
    this.dosageForm,
    this.strength,
    this.sideEffects,
    this.conditions,
    this.ingredients,
    this.storageConditions,
    this.usageInstructions,
    this.barcode,
    this.weight,
    required this.unitOfMeasure,
    required this.minimumStockLevel,
    this.supplier,
    this.purchasePrice,
    required this.status,
    required this.imageUrl,
    required this.availabilityStatus,
    required this.isExpired,
    this.daysUntilExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicalProduct.fromJson(Map<String, dynamic> json) {
    return MedicalProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      batchNo: json['batch_no'] ?? '',
      category: json['category'] ?? '',
      photo: json['photo'],
      cost: double.tryParse(json['cost']?.toString() ?? '0') ?? 0.0,
      formattedCost: json['formatted_cost'] ?? '₱0.00',
      stockQuantity: json['stock_quantity'] ?? 0,
      manufacturer: json['manufacturer'],
      manufacturingDate: json['manufacturing_date'] != null
          ? DateTime.tryParse(json['manufacturing_date'])
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'])
          : null,
      needsPrescription: json['needs_prescription'] ?? false,
      isAvailable: json['is_available'] ?? false,
      dosageForm: json['dosage_form'],
      strength: json['strength'],
      sideEffects: json['side_effects'] != null
          ? List<String>.from(json['side_effects'])
          : null,
      conditions: json['conditions'] != null
          ? List<String>.from(json['conditions'])
          : null,
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : null,
      storageConditions: json['storage_conditions'],
      usageInstructions: json['usage_instructions'],
      barcode: json['barcode'],
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,
      unitOfMeasure: json['unit_of_measure'] ?? 'pieces',
      minimumStockLevel: json['minimum_stock_level'] ?? 10,
      supplier: json['supplier'],
      purchasePrice: json['purchase_price'] != null
          ? double.tryParse(json['purchase_price'].toString())
          : null,
      status: json['status'] ?? 'active',
      imageUrl: json['image_url'] ?? '',
      availabilityStatus: json['availability_status'] ?? 'Unavailable',
      isExpired: json['is_expired'] ?? false,
      daysUntilExpiry: json['days_until_expiry'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'batch_no': batchNo,
      'category': category,
      'photo': photo,
      'cost': cost,
      'formatted_cost': formattedCost,
      'stock_quantity': stockQuantity,
      'manufacturer': manufacturer,
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'needs_prescription': needsPrescription,
      'is_available': isAvailable,
      'dosage_form': dosageForm,
      'strength': strength,
      'side_effects': sideEffects,
      'conditions': conditions,
      'ingredients': ingredients,
      'storage_conditions': storageConditions,
      'usage_instructions': usageInstructions,
      'barcode': barcode,
      'weight': weight,
      'unit_of_measure': unitOfMeasure,
      'minimum_stock_level': minimumStockLevel,
      'supplier': supplier,
      'purchase_price': purchasePrice,
      'status': status,
      'image_url': imageUrl,
      'availability_status': availabilityStatus,
      'is_expired': isExpired,
      'days_until_expiry': daysUntilExpiry,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isLowStock => stockQuantity <= minimumStockLevel;

  bool get isInStock => stockQuantity > 0;

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;
    return daysLeft <= 30 && daysLeft > 0;
  }

  String get stockStatus {
    if (!isAvailable) return 'Unavailable';
    if (stockQuantity <= 0) return 'Out of Stock';
    if (stockQuantity <= minimumStockLevel) return 'Low Stock';
    return 'In Stock';
  }

  String get expiryStatus {
    if (expiryDate == null) return 'No Expiry';
    if (isExpired) return 'Expired';
    if (isExpiringSoon) return 'Expiring Soon';
    return 'Valid';
  }

  // Copy with method for updating
  MedicalProduct copyWith({
    int? id,
    String? name,
    String? description,
    String? batchNo,
    String? category,
    String? photo,
    double? cost,
    String? formattedCost,
    int? stockQuantity,
    String? manufacturer,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    bool? needsPrescription,
    bool? isAvailable,
    String? dosageForm,
    String? strength,
    List<String>? sideEffects,
    List<String>? conditions,
    List<String>? ingredients,
    String? storageConditions,
    String? usageInstructions,
    String? barcode,
    double? weight,
    String? unitOfMeasure,
    int? minimumStockLevel,
    String? supplier,
    double? purchasePrice,
    String? status,
    String? imageUrl,
    String? availabilityStatus,
    bool? isExpired,
    int? daysUntilExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      batchNo: batchNo ?? this.batchNo,
      category: category ?? this.category,
      photo: photo ?? this.photo,
      cost: cost ?? this.cost,
      formattedCost: formattedCost ?? this.formattedCost,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      manufacturer: manufacturer ?? this.manufacturer,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      needsPrescription: needsPrescription ?? this.needsPrescription,
      isAvailable: isAvailable ?? this.isAvailable,
      dosageForm: dosageForm ?? this.dosageForm,
      strength: strength ?? this.strength,
      sideEffects: sideEffects ?? this.sideEffects,
      conditions: conditions ?? this.conditions,
      ingredients: ingredients ?? this.ingredients,
      storageConditions: storageConditions ?? this.storageConditions,
      usageInstructions: usageInstructions ?? this.usageInstructions,
      barcode: barcode ?? this.barcode,
      weight: weight ?? this.weight,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
      supplier: supplier ?? this.supplier,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      isExpired: isExpired ?? this.isExpired,
      daysUntilExpiry: daysUntilExpiry ?? this.daysUntilExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MedicalProduct(id: $id, name: $name, batchNo: $batchNo, category: $category, cost: $cost, stockQuantity: $stockQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicalProduct &&
        other.id == id &&
        other.name == name &&
        other.batchNo == batchNo;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ batchNo.hashCode;
}

// Response model for API calls
class MedicalProductResponse {
  final bool success;
  final String message;
  final MedicalProductData? data;
  final String? error;

  MedicalProductResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory MedicalProductResponse.fromJson(Map<String, dynamic> json) {
    return MedicalProductResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? MedicalProductData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class MedicalProductData {
  final List<MedicalProduct> products;
  final Pagination? pagination;

  MedicalProductData({
    required this.products,
    this.pagination,
  });

  factory MedicalProductData.fromJson(Map<String, dynamic> json) {
    return MedicalProductData(
      products: json['products'] != null
          ? (json['products'] as List)
              .map((item) => MedicalProduct.fromJson(item))
              .toList()
          : [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 15,
      total: json['total'] ?? 0,
      from: json['from'],
      to: json['to'],
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}