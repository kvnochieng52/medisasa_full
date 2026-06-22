<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MedicalProduct;
use App\Models\MedicineCategory;
use App\Models\MedicineSubcategory;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class MedicalProductController extends Controller
{
    /**
     * Display a listing of medical products with filtering and pagination
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = MedicalProduct::query();

            // Search functionality
            if ($request->filled('search')) {
                $query->search($request->search);
            }

            // Category filter
            if ($request->filled('category')) {
                $query->byCategory($request->category);
            }

            // Availability filter
            if ($request->filled('in_stock') && $request->boolean('in_stock')) {
                $query->available();
            }

            // Status filter
            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }

            // Low stock filter
            if ($request->filled('low_stock') && $request->boolean('low_stock')) {
                $query->lowStock();
            }

            // Expiring soon filter
            if ($request->filled('expiring_soon') && $request->boolean('expiring_soon')) {
                $query->expiringSoon($request->get('expiring_days', 30));
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'name');
            $sortOrder = $request->get('sort_order', 'asc');

            $allowedSortFields = ['name', 'cost', 'stock_quantity', 'expiry_date', 'created_at'];
            if (in_array($sortBy, $allowedSortFields)) {
                $query->orderBy($sortBy, $sortOrder);
            }

            // Pagination
            $perPage = min($request->get('per_page', 15), 50);
            $products = $query->paginate($perPage);

            // Add computed attributes to each product
            $products->getCollection()->transform(function ($product) {
                return [
                    'id' => $product->id,
                    'name' => $product->name,
                    'description' => $product->description,
                    'batch_no' => $product->batch_no,
                    'category' => $product->category,
                    'photo' => $product->photo,
                    'cost' => $product->cost,
                    'formatted_cost' => $product->formatted_cost,
                    'stock_quantity' => $product->stock_quantity,
                    'manufacturer' => $product->manufacturer,
                    'manufacturing_date' => $product->manufacturing_date,
                    'expiry_date' => $product->expiry_date,
                    'needs_prescription' => $product->needs_prescription,
                    'is_available' => $product->is_available,
                    'dosage_form' => $product->dosage_form,
                    'strength' => $product->strength,
                    'side_effects' => $product->side_effects,
                    'conditions' => $product->conditions,
                    'ingredients' => $product->ingredients,
                    'storage_conditions' => $product->storage_conditions,
                    'usage_instructions' => $product->usage_instructions,
                    'barcode' => $product->barcode,
                    'weight' => $product->weight,
                    'unit_of_measure' => $product->unit_of_measure,
                    'minimum_stock_level' => $product->minimum_stock_level,
                    'supplier' => $product->supplier,
                    'purchase_price' => $product->purchase_price,
                    'status' => $product->status,
                    'image_url' => $product->image_url,
                    'availability_status' => $product->availability_status,
                    'is_expired' => $product->is_expired,
                    'days_until_expiry' => $product->days_until_expiry,
                    'created_at' => $product->created_at,
                    'updated_at' => $product->updated_at,
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Medical products retrieved successfully',
                'data' => [
                    'products' => $products->items(),
                    'pagination' => [
                        'current_page' => $products->currentPage(),
                        'last_page' => $products->lastPage(),
                        'per_page' => $products->perPage(),
                        'total' => $products->total(),
                        'from' => $products->firstItem(),
                        'to' => $products->lastItem(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve medical products',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created medical product
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'batch_no' => 'required|string|max:255',
                'category' => 'nullable|string|max:255',
                'category_id' => 'required|integer|exists:medicine_categories,id',
                'subcategory_id' => 'nullable|integer|exists:medicine_subcategories,id',
                'photo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
                'cost' => 'required|numeric|min:0',
                'stock_quantity' => 'required|integer|min:0',
                'manufacturer' => 'nullable|string|max:255',
                'manufacturing_date' => 'nullable|date',
                'expiry_date' => 'nullable|date|after:manufacturing_date',
                'needs_prescription' => 'boolean',
                'is_available' => 'boolean',
                'dosage_form' => 'nullable|string|max:255',
                'strength' => 'nullable|string|max:255',
                'side_effects' => 'nullable|array',
                'conditions' => 'nullable|array',
                'ingredients' => 'nullable|array',
                'storage_conditions' => 'nullable|string|max:255',
                'usage_instructions' => 'nullable|string',
                'barcode' => 'nullable|string|max:255',
                'weight' => 'nullable|numeric|min:0',
                'unit_of_measure' => 'nullable|string|max:255',
                'minimum_stock_level' => 'nullable|integer|min:0',
                'supplier' => 'nullable|string|max:255',
                'purchase_price' => 'nullable|numeric|min:0',
                'status' => 'nullable|in:active,discontinued,out_of_stock',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $data = $validator->validated();

            // Type casting for proper data types
            $data['category_id'] = (int) $data['category_id'];
            if (isset($data['subcategory_id'])) {
                $data['subcategory_id'] = (int) $data['subcategory_id'];
            }
            $data['cost'] = (float) $data['cost'];
            $data['stock_quantity'] = (int) $data['stock_quantity'];

            // Handle photo upload
            if ($request->hasFile('photo')) {
                $photoPath = $request->file('photo')->store('medical_products', 'public');
                $data['photo'] = $photoPath;
            }

            // Check for unique batch number and name combination
            $existingProduct = MedicalProduct::where('batch_no', $data['batch_no'])
                                           ->where('name', $data['name'])
                                           ->first();

            if ($existingProduct) {
                return response()->json([
                    'success' => false,
                    'message' => 'A product with this name and batch number already exists'
                ], 422);
            }

            $product = MedicalProduct::create($data);

            return response()->json([
                'success' => true,
                'message' => 'Medical product created successfully',
                'data' => $product
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create medical product',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified medical product
     */
    public function show(string $id): JsonResponse
    {
        try {
            $product = MedicalProduct::findOrFail($id);

            $productData = [
                'id' => $product->id,
                'name' => $product->name,
                'description' => $product->description,
                'batch_no' => $product->batch_no,
                'category' => $product->category,
                'photo' => $product->photo,
                'cost' => $product->cost,
                'formatted_cost' => $product->formatted_cost,
                'stock_quantity' => $product->stock_quantity,
                'manufacturer' => $product->manufacturer,
                'manufacturing_date' => $product->manufacturing_date,
                'expiry_date' => $product->expiry_date,
                'needs_prescription' => $product->needs_prescription,
                'is_available' => $product->is_available,
                'dosage_form' => $product->dosage_form,
                'strength' => $product->strength,
                'side_effects' => $product->side_effects,
                'conditions' => $product->conditions,
                'ingredients' => $product->ingredients,
                'storage_conditions' => $product->storage_conditions,
                'usage_instructions' => $product->usage_instructions,
                'barcode' => $product->barcode,
                'weight' => $product->weight,
                'unit_of_measure' => $product->unit_of_measure,
                'minimum_stock_level' => $product->minimum_stock_level,
                'supplier' => $product->supplier,
                'purchase_price' => $product->purchase_price,
                'status' => $product->status,
                'image_url' => $product->image_url,
                'availability_status' => $product->availability_status,
                'is_expired' => $product->is_expired,
                'days_until_expiry' => $product->days_until_expiry,
                'created_at' => $product->created_at,
                'updated_at' => $product->updated_at,
            ];

            return response()->json([
                'success' => true,
                'message' => 'Medical product retrieved successfully',
                'data' => $productData
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Medical product not found',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Update the specified medical product
     */
    public function update(Request $request, string $id): JsonResponse
    {
        try {
            $product = MedicalProduct::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'name' => 'sometimes|string|max:255',
                'description' => 'nullable|string',
                'batch_no' => 'sometimes|string|max:255',
                'category' => 'nullable|string|max:255',
                'category_id' => 'sometimes|integer|exists:medicine_categories,id',
                'subcategory_id' => 'nullable|integer|exists:medicine_subcategories,id',
                'photo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
                'cost' => 'sometimes|numeric|min:0',
                'stock_quantity' => 'sometimes|integer|min:0',
                'manufacturer' => 'nullable|string|max:255',
                'manufacturing_date' => 'nullable|date',
                'expiry_date' => 'nullable|date|after:manufacturing_date',
                'needs_prescription' => 'boolean',
                'is_available' => 'boolean',
                'dosage_form' => 'nullable|string|max:255',
                'strength' => 'nullable|string|max:255',
                'side_effects' => 'nullable|array',
                'conditions' => 'nullable|array',
                'ingredients' => 'nullable|array',
                'storage_conditions' => 'nullable|string|max:255',
                'usage_instructions' => 'nullable|string',
                'barcode' => 'nullable|string|max:255',
                'weight' => 'nullable|numeric|min:0',
                'unit_of_measure' => 'nullable|string|max:255',
                'minimum_stock_level' => 'nullable|integer|min:0',
                'supplier' => 'nullable|string|max:255',
                'purchase_price' => 'nullable|numeric|min:0',
                'status' => 'nullable|in:active,discontinued,out_of_stock',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $data = $validator->validated();

            // Type casting for proper data types
            if (isset($data['category_id'])) {
                $data['category_id'] = (int) $data['category_id'];
            }
            if (isset($data['subcategory_id'])) {
                $data['subcategory_id'] = (int) $data['subcategory_id'];
            }
            if (isset($data['cost'])) {
                $data['cost'] = (float) $data['cost'];
            }
            if (isset($data['stock_quantity'])) {
                $data['stock_quantity'] = (int) $data['stock_quantity'];
            }

            // Handle photo upload
            if ($request->hasFile('photo')) {
                // Delete old photo if exists
                if ($product->photo) {
                    Storage::disk('public')->delete($product->photo);
                }

                $photoPath = $request->file('photo')->store('medical_products', 'public');
                $data['photo'] = $photoPath;
            }

            // Check for unique batch number and name combination (excluding current product)
            if (isset($data['batch_no']) || isset($data['name'])) {
                $batchNo = $data['batch_no'] ?? $product->batch_no;
                $name = $data['name'] ?? $product->name;

                $existingProduct = MedicalProduct::where('batch_no', $batchNo)
                                               ->where('name', $name)
                                               ->where('id', '!=', $id)
                                               ->first();

                if ($existingProduct) {
                    return response()->json([
                        'success' => false,
                        'message' => 'A product with this name and batch number already exists'
                    ], 422);
                }
            }

            $product->update($data);

            return response()->json([
                'success' => true,
                'message' => 'Medical product updated successfully',
                'data' => $product->fresh()
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update medical product',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified medical product
     */
    public function destroy(string $id): JsonResponse
    {
        try {
            $product = MedicalProduct::findOrFail($id);

            // Delete photo if exists
            if ($product->photo) {
                Storage::delete('public/medical_products/' . $product->photo);
            }

            $product->delete();

            return response()->json([
                'success' => true,
                'message' => 'Medical product deleted successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete medical product',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get product categories (only those visible for products)
     */
    public function getCategories(): JsonResponse
    {
        try {
            $categories = MedicineCategory::where('visible_for_products', true)
                                         ->where('is_active', true)
                                         ->orderBy('name')
                                         ->get(['id', 'name', 'description']);

            return response()->json([
                'success' => true,
                'message' => 'Product categories retrieved successfully',
                'data' => $categories
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve categories',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get product subcategories by category (only those visible for products)
     */
    public function getSubcategories(Request $request): JsonResponse
    {
        try {
            $query = MedicineSubcategory::where('visible_for_products', true)
                                       ->where('is_active', true);

            if ($request->filled('category_id')) {
                $query->where('category_id', $request->category_id);
            }

            $subcategories = $query->orderBy('name')
                                   ->get(['id', 'category_id', 'name', 'description']);

            return response()->json([
                'success' => true,
                'message' => 'Product subcategories retrieved successfully',
                'data' => $subcategories
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve subcategories',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update stock quantity
     */
    public function updateStock(Request $request, string $id): JsonResponse
    {
        try {
            $product = MedicalProduct::findOrFail($id);

            $validator = Validator::make($request->all(), [
                'action' => 'required|in:increase,decrease,set',
                'quantity' => 'required|integer|min:0',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $action = $request->action;
            $quantity = $request->quantity;

            switch ($action) {
                case 'increase':
                    $product->increaseStock($quantity);
                    break;
                case 'decrease':
                    if (!$product->reduceStock($quantity)) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Insufficient stock quantity'
                        ], 422);
                    }
                    break;
                case 'set':
                    $product->update(['stock_quantity' => $quantity]);
                    if ($quantity > 0 && !$product->is_available) {
                        $product->update(['is_available' => true]);
                    } elseif ($quantity <= 0) {
                        $product->update(['is_available' => false]);
                    }
                    break;
            }

            return response()->json([
                'success' => true,
                'message' => 'Stock updated successfully',
                'data' => $product->fresh()
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update stock',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
