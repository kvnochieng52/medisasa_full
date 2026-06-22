<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'dpo' => [
        'company_token' => env('DPO_COMPANY_TOKEN'),
        'service_type'  => env('DPO_SERVICE_TYPE', '85325'),
        'api_url'       => env('DPO_API_URL', 'https://secure.3gdirectpay.com/API/v6/'),
        'payment_url'   => env('DPO_PAYMENT_URL', 'https://secure.3gdirectpay.com/payv2.php'),
    ],

    'google' => [
        'calendar' => [
            'credentials_path' => env('GOOGLE_CREDENTIALS_PATH', storage_path('app/google/credentials.json')),
            'application_name' => env('GOOGLE_APPLICATION_NAME', 'DocFinder Appointment System'),
            'scopes' => [
                'https://www.googleapis.com/auth/calendar',
                'https://www.googleapis.com/auth/calendar.events',
            ],
        ],
    ],

];
