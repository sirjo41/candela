<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\OfferController;
use App\Http\Controllers\Api\V1\QrVerificationController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\MerchantController;
use App\Http\Controllers\Api\V1\QrController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\ProfileController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Candela API v1 Routes
|--------------------------------------------------------------------------
*/
Route::prefix('v1')->group(function () {

    // 1. Authentication (public)
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'registerCustomer']);
        Route::post('login', [AuthController::class, 'login']);
        Route::post('merchant/login', [AuthController::class, 'loginMerchant']);
    });

    // 2. Public Feed Discovery
    Route::get('offers', [OfferController::class, 'index']);
    Route::get('offers/{id}', [OfferController::class, 'show']);
    Route::get('customer/campaigns', [CustomerController::class, 'campaigns']);
    Route::get('customer/coupons', [CustomerController::class, 'coupons']);
    Route::get('customer/stores', [CustomerController::class, 'stores']);
    Route::get('notifications', [NotificationController::class, 'index']);

    // 3. Authenticated Customer Endpoints
    Route::middleware(['auth:sanctum', 'role:customer'])->prefix('customer')->group(function () {
        Route::post('campaigns/{id}/claim', [CustomerController::class, 'claim']);
        Route::post('coupons/{id}/claim', [CustomerController::class, 'claim']);
        Route::get('qr-pass/{couponId}', [CustomerController::class, 'showQrPass']);
        Route::get('rewards', [CustomerController::class, 'rewards']);
        Route::post('rewards/redeem', [CustomerController::class, 'redeemPoints']);
        Route::get('wallet', [CustomerController::class, 'wallet']);
        Route::get('profile', [CustomerController::class, 'profile']);
        Route::post('profile/update', [ProfileController::class, 'update']);
        Route::post('profile/change-password', [ProfileController::class, 'changePassword']);
    });

    // 4. Authenticated Merchant & Staff Operations
    Route::middleware(['auth:sanctum', 'role:merchant'])->prefix('merchant')->group(function () {
        Route::post('offers/create', [OfferController::class, 'create']);
        Route::post('offers/{id}/update', [OfferController::class, 'update']);
        Route::put('offers/{id}', [OfferController::class, 'update']);
        Route::delete('offers/{id}', [OfferController::class, 'destroy']);
        Route::post('offers/{id}/delete', [OfferController::class, 'destroy']);
        Route::post('verify-qr', [QrVerificationController::class, 'verifyQr']);
        Route::get('dashboard', [MerchantController::class, 'dashboard']);
        Route::get('history', [MerchantController::class, 'history']);
        Route::post('profile/update', [ProfileController::class, 'update']);
        Route::post('profile/change-password', [ProfileController::class, 'changePassword']);
    });

    // 5. Authenticated QR Operations
    Route::middleware('auth:sanctum')->prefix('qr')->group(function () {
        Route::post('generate', [QrController::class, 'generate']);
        Route::post('validate', [QrController::class, 'validateQr']);
        Route::post('verify', [QrVerificationController::class, 'verifyQr']);
    });

    // 6. User Profile & Security Settings (Unified)
    Route::middleware('auth:sanctum')->prefix('profile')->group(function () {
        Route::get('/', [ProfileController::class, 'profile']);
        Route::post('update', [ProfileController::class, 'update']);
        Route::put('/', [ProfileController::class, 'update']);
        Route::post('change-password', [ProfileController::class, 'changePassword']);
    });
});
