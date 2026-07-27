<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\QrController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // 1. API Authentication & Token Setup
    Route::prefix('auth')->group(function () {
        Route::post('customer/register', [AuthController::class, 'registerCustomer']);
        Route::post('customer/login', [AuthController::class, 'loginCustomer']);
        Route::post('merchant/login', [AuthController::class, 'loginMerchant']);
    });

    // 2. Customer Offer & Discovery Endpoints
    Route::prefix('customer')->group(function () {
        Route::get('campaigns', [CustomerController::class, 'campaigns']);
        Route::get('coupons', [CustomerController::class, 'coupons']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('coupons/{id}/claim', [CustomerController::class, 'claim']);
            Route::get('profile', [CustomerController::class, 'profile']);
        });
    });

    // 3. Dynamic QR Code Engine & Validation
    Route::prefix('qr')->middleware('auth:sanctum')->group(function () {
        Route::post('generate', [QrController::class, 'generate']);
        Route::post('validate', [QrController::class, 'validateQr']);
    });
});
