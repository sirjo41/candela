<?php

namespace App\Http\Requests\Api\V1\Qr;

use Illuminate\Foundation\Http\FormRequest;

class VerifyQrRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'qr_token' => ['required_without_all:coupon_code,qr_code_hash', 'nullable', 'string'],
            'coupon_code' => ['required_without_all:qr_token,qr_code_hash', 'nullable', 'string'],
            'qr_code_hash' => ['required_without_all:qr_token,coupon_code', 'nullable', 'string'],
        ];
    }
}
