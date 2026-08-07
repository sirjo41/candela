<?php

namespace App\Http\Requests\Api\V1\Offer;

use Illuminate\Foundation\Http\FormRequest;

class CreateOfferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'campaign_id' => ['nullable', 'integer', 'exists:campaigns,id'],
            'description' => ['nullable', 'string'],
            'category' => ['required', 'string', 'max:100'],
            'original_price' => ['nullable', 'numeric', 'min:0'],
            'discount_rate' => ['nullable', 'numeric', 'min:0', 'max:100'],
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
