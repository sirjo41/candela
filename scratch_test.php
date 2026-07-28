<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$controller = new App\Http\Controllers\Api\V1\AuthController();

$tests = [
    ['label' => 'Customer Email', 'login' => 'alice@example.com', 'password' => 'password'],
    ['label' => 'Customer Full Phone (+1987654321)', 'login' => '+1987654321', 'password' => 'password'],
    ['label' => 'Customer Raw Digits (1987654321)', 'login' => '1987654321', 'password' => 'password'],
    ['label' => 'Merchant Email', 'login' => 'merchant1@example.com', 'password' => 'password'],
    ['label' => 'Merchant Full Phone (+15550100)', 'login' => '+15550100', 'password' => 'password'],
    ['label' => 'Merchant Raw Digits (15550100)', 'login' => '15550100', 'password' => 'password'],
];

foreach ($tests as $t) {
    $req = Illuminate\Http\Request::create('/api/v1/auth/login', 'POST', ['login' => $t['login'], 'password' => $t['password']]);
    $res = $controller->login($req);
    $data = json_decode($res->getContent(), true);
    $role = $data['user']['role'] ?? 'N/A';
    $isMerc = ($data['user']['is_merchant'] ?? false) ? 'TRUE' : 'FALSE';
    $isCust = ($data['user']['is_customer'] ?? false) ? 'TRUE' : 'FALSE';
    echo "[{$t['label']}] Status: {$res->getStatusCode()} | Role: {$role} | is_merchant: {$isMerc} | is_customer: {$isCust}\n";
}
