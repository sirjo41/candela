<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\MerchantController;
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
        Route::get('stores', [CustomerController::class, 'stores']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('campaigns/{id}/claim', [CustomerController::class, 'claim']);
            Route::post('coupons/{id}/claim', [CustomerController::class, 'claim']);
            Route::get('wallet', [CustomerController::class, 'wallet']);
            Route::get('profile', [CustomerController::class, 'profile']);
        });
    });

    // 3. Merchant / Store Owner Operations
    Route::prefix('merchant')->middleware(['auth:sanctum', 'abilities:role:merchant'])->group(function () {
        Route::get('dashboard', [MerchantController::class, 'dashboard']);
        Route::post('qr/validate', [QrController::class, 'validateQr']);
        Route::get('history', [MerchantController::class, 'history']);
    });

    // 4. Dynamic QR Code Engine & Validation
    Route::prefix('qr')->middleware('auth:sanctum')->group(function () {
        Route::post('generate', [QrController::class, 'generate']);
        Route::post('validate', [QrController::class, 'validateQr']);
    });
});
