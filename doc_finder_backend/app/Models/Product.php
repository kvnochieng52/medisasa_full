<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_name',
        'product_description',
        'product_location',
        'product_price',
        'product_tags',
        'product_featured_image',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'product_price' => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get all images for the product
     */
    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class, 'product_id', 'id');
    }

    /**
     * Get the featured image for the product
     */
    public function featuredImage(): HasMany
    {
        return $this->hasMany(ProductImage::class, 'product_id', 'id')->where('is_featured', true);
    }

    /**
     * Get the user who created the product
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by', 'id');
    }

    /**
     * Get the user who last updated the product
     */
    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by', 'id');
    }

    /**
     * Scope to get products by specific user
     */
    public function scopeByUser($query, $userId)
    {
        return $query->where('created_by', $userId);
    }

    /**
     * Scope to get products with images
     */
    public function scopeWithImages($query)
    {
        return $query->with(['images' => function($query) {
            $query->orderBy('is_featured', 'desc')
                  ->orderBy('created_at', 'asc');
        }]);
    }

    /**
     * Scope to get products within price range
     */
    public function scopeByPriceRange($query, $minPrice = null, $maxPrice = null)
    {
        if ($minPrice !== null) {
            $query->where('product_price', '>=', $minPrice);
        }
        if ($maxPrice !== null) {
            $query->where('product_price', '<=', $maxPrice);
        }
        return $query;
    }

    /**
     * Get formatted price
     */
    public function getFormattedPriceAttribute(): string
    {
        return number_format($this->product_price, 2);
    }

    /**
     * Get the product's featured image URL
     */
    public function getFeaturedImageUrlAttribute(): ?string
    {
        if ($this->product_featured_image) {
            return \Storage::disk('public')->url($this->product_featured_image);
        }
        return null;
    }
}