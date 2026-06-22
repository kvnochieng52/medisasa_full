import 'medicine_category_model.dart';
import '../api_config.dart';

class Medicine {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String medicineNumber;
  final double cost;
  final String? image;
  final int categoryId;
  final int? subcategoryId;
  final List<String>? conditions;
  final String? manufacturer;
  final String? strength;
  final String? form;
  final int quantityAvailable;
  final bool isActive;
  final bool requiresPrescription;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MedicineCategory? category;
  final MedicineSubcategory? subcategory;

  Medicine({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.medicineNumber,
    required this.cost,
    this.image,
    required this.categoryId,
    this.subcategoryId,
    this.conditions,
    this.manufacturer,
    this.strength,
    this.form,
    required this.quantityAvailable,
    required this.isActive,
    required this.requiresPrescription,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.subcategory,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      medicineNumber: json['medicine_number'],
      cost: double.parse(json['cost'].toString()),
      image: json['image_url'] ?? json['image'], // Use image_url if available, fallback to image
      categoryId: json['category_id'],
      subcategoryId: json['subcategory_id'],
      conditions: json['conditions'] != null
          ? List<String>.from(json['conditions'])
          : null,
      manufacturer: json['manufacturer'],
      strength: json['strength'],
      form: json['form'],
      quantityAvailable: json['quantity_available'] ?? 0,
      isActive: json['is_active'] ?? true,
      requiresPrescription: json['requires_prescription'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      category: json['category'] != null
          ? MedicineCategory.fromJson(json['category'])
          : null,
      subcategory: json['subcategory'] != null
          ? MedicineSubcategory.fromJson(json['subcategory'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'medicine_number': medicineNumber,
      'cost': cost,
      'image': image,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'conditions': conditions,
      'manufacturer': manufacturer,
      'strength': strength,
      'form': form,
      'quantity_available': quantityAvailable,
      'is_active': isActive,
      'requires_prescription': requiresPrescription,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category?.toJson(),
      'subcategory': subcategory?.toJson(),
    };
  }

  // Helper getter for formatted cost
  String get formattedCost => 'KSh ${cost.toStringAsFixed(2)}';

  // Helper getter for availability status
  String get availabilityStatus {
    if (quantityAvailable <= 0) return 'Out of Stock';
    if (quantityAvailable <= 5) return 'Low Stock';
    return 'In Stock';
  }

  // Helper getter for image URL
  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http')) {
      return image!;
    }
    
    String cleanPath = image!;
    if (cleanPath.startsWith('/storage/')) {
      cleanPath = cleanPath.substring(9);
      return '${ApiConfig.webUrl}/storage/$cleanPath';
    } else if (cleanPath.startsWith('storage/')) {
      cleanPath = cleanPath.substring(8);
      return '${ApiConfig.webUrl}/storage/$cleanPath';
    } else {
      return '${ApiConfig.webUrl}/storage/$cleanPath';
    }
  }

  // Helper method to check if medicine is available
  bool get isAvailable => isActive && quantityAvailable > 0;

  // Helper method to check if prescription is needed
  bool get needsPrescription => requiresPrescription;
}

// Response model for paginated medicines
class MedicineResponse {
  final List<Medicine> medicines;
  final MedicinePagination? pagination;

  MedicineResponse({
    required this.medicines,
    this.pagination,
  });

  factory MedicineResponse.fromJson(Map<String, dynamic> json) {
    return MedicineResponse(
      medicines: (json['medicines'] as List)
          .map((medicine) => Medicine.fromJson(medicine))
          .toList(),
      pagination: json['pagination'] != null
          ? MedicinePagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class MedicinePagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  MedicinePagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory MedicinePagination.fromJson(Map<String, dynamic> json) {
    return MedicinePagination(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }
}