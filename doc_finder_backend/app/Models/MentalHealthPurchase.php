<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MentalHealthPurchase extends Model
{
    protected $fillable = [
        'user_id', 'material_id', 'purchase_ref',
        'dpo_trans_token', 'amount', 'status',
    ];

    protected $casts = [
        'amount' => 'float',
    ];

    public function material()
    {
        return $this->belongsTo(MentalHealthMaterial::class, 'material_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
