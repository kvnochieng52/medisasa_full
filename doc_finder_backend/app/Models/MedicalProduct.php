<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class MedicalProduct extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'batch_no',
        'category',
        'category_id',
        'subcategory_id',
        'photo',
        'cost',
        'stock_quantity',
        'manufacturer',
        'manufacturing_date',
        'expiry_date',
        'needs_prescription',
        'is_available',
        'dosage_form',
        'strength',
        'side_effects',
        'conditions',
        'ingredients',
        'storage_conditions',
        'usage_instructions',
        'barcode',
        'weight',
        'unit_of_measure',
        'minimum_stock_level',
        'supplier',
        'purchase_price',
        'status'
    ];

    protected $casts = [
        'cost' => 'decimal:2',
        'purchase_price' => 'decimal:2',
        'weight' => 'decimal:3',
        'stock_quantity' => 'integer',
        'minimum_stock_level' => 'integer',
        'needs_prescription' => 'boolean',
        'is_available' => 'boolean',
        'manufacturing_date' => 'date',
        'expiry_date' => 'date',
        'side_effects' => 'array',
        'conditions' => 'array',
        'ingredients' => 'array',
    ];

    // Accessors
    protected function formattedCost(): Attribute
    {
        return Attribute::make(
            get: fn ($value, $attributes) => '₱' . number_format($attributes['cost'], 2),
        );
    }

    protected function imageUrl(): Attribute
    {
        return Attribute::make(
            get: fn ($value, $attributes) => $attributes['photo']
                ? url('storage/medical_products/' . $attributes['photo'])
                : '',
        );
    }

    protected function availabilityStatus(): Attribute
    {
        return Attribute::make(
            get: function ($value, $attributes) {
                if (!$attributes['is_available']) return 'Unavailable';
                if ($attributes['stock_quantity'] <= 0) return 'Out of Stock';
                if ($attributes['stock_quantity'] <= $attributes['minimum_stock_level']) return 'Low Stock';
                return 'In Stock';
            }
        );
    }

    protected function isExpired(): Attribute
    {
        return Attribute::make(
            get: fn ($value, $attributes) => $attributes['expiry_date']
                ? Carbon::parse($attributes['expiry_date'])->isPast()
                : false,
        );
    }

    protected function daysUntilExpiry(): Attribute
    {
        return Attribute::make(
            get: fn ($value, $attributes) => $attributes['expiry_date']
                ? Carbon::now()->diffInDays(Carbon::parse($attributes['expiry_date']), false)
                : null,
        );
    }

    // Scopes
    public function scopeAvailable($query)
    {
        return $query->where('is_available', true)
                    ->where('stock_quantity', '>', 0)
                    ->where(function($q) {
                        $q->whereNull('expiry_date')
                          ->orWhere('expiry_date', '>', now());
                    });
    }

    public function scopeInStock($query)
    {
        return $query->where('stock_quantity', '>', 0);
    }

    public function scopeLowStock($query)
    {
        return $query->whereColumn('stock_quantity', '<=', 'minimum_stock_level');
    }

    public function scopeExpiringSoon($query, $days = 30)
    {
        return $query->whereNotNull('expiry_date')
                    ->whereBetween('expiry_date', [now(), now()->addDays($days)]);
    }

    public function scopeExpired($query)
    {
        return $query->whereNotNull('expiry_date')
                    ->where('expiry_date', '<', now());
    }

    public function scopeByCategory($query, $category)
    {
        return $query->where('category', $category);
    }

    public function scopeSearch($query, $term)
    {
        return $query->where(function($q) use ($term) {
            $q->where('name', 'LIKE', "%{$term}%")
              ->orWhere('description', 'LIKE', "%{$term}%")
              ->orWhere('manufacturer', 'LIKE', "%{$term}%")
              ->orWhere('batch_no', 'LIKE', "%{$term}%")
              ->orWhereJsonContains('conditions', $term)
              ->orWhereJsonContains('ingredients', $term);
        });
    }

    // Methods
    public function reduceStock($quantity)
    {
        if ($this->stock_quantity >= $quantity) {
            $this->decrement('stock_quantity', $quantity);

            // Update availability status if stock becomes zero
            if ($this->stock_quantity <= 0) {
                $this->update(['is_available' => false]);
            }

            return true;
        }

        return false;
    }

    public function increaseStock($quantity)
    {
        $this->increment('stock_quantity', $quantity);

        // Make available if stock is added
        if ($this->stock_quantity > 0 && !$this->is_available) {
            $this->update(['is_available' => true]);
        }

        return true;
    }

    public function getCategories()
    {
        return self::distinct('category')->pluck('category')->sort()->values();
    }

    // Relationships
    public function category(): BelongsTo
    {
        return $this->belongsTo(MedicineCategory::class, 'category_id');
    }

    public function subcategory(): BelongsTo
    {
        return $this->belongsTo(MedicineSubcategory::class, 'subcategory_id');
    }
}
