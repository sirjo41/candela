<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    /**
     * Fetch broadcast notifications sent from Filament Admin to Flutter app.
     */
    public function index(Request $request): JsonResponse
    {
        $role = $request->query('role', 'customer');

        $notifications = DB::table('broadcast_ads')
            ->whereIn('target_role', ['all', $role])
            ->orderBy('created_at', 'desc')
            ->limit(20)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $notifications,
        ]);
    }
}
