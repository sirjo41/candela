<?php

namespace App\Http\Requests\Api\V1\Offer;

use Illuminate\Foundation\Http\FormRequest;

class CreateOfferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() && ($this->user()->isMerchant() || $this->user()->isAdmin());
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'category' => ['required', 'string', 'max:100'],
            'original_price' => ['required', 'numeric', 'min:0.01'],
            'discount_rate' => ['required', 'numeric', 'min:0.01', 'max:100'],
            'creation_fee' => ['nullable', 'numeric', 'min:0'],
            'redemption_fee' => ['nullable', 'numeric', 'min:0'],
            'discount_badge' => ['nullable', 'string', 'max:50'],
            'banner_image' => ['nullable', 'string', 'max:500'],
            'branch_location' => ['nullable', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'valid_until' => ['required', 'date', 'after:now'],
        ];
    }
}
