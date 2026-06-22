<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TestController extends Controller
{
    /**
     * Simple health check endpoint
     */
    public function healthCheck()
    {
        return response()->json([
            'status' => 'success',
            'message' => 'API is working correctly!',
            'timestamp' => now()->toISOString(),
            'server_info' => [
                'php_version' => PHP_VERSION,
                'laravel_version' => app()->version(),
                'environment' => app()->environment(),
            ]
        ]);
    }

    /**
     * Echo endpoint for testing requests
     */
    public function echo(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'message' => 'Echo endpoint working',
            'request_data' => $request->all(),
            'headers' => $request->headers->all(),
            'method' => $request->method(),
            'timestamp' => now()->toISOString(),
        ]);
    }
}