<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Google\Client;
use Exception;

class SetupGoogleAuth extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'google:setup-auth';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Setup Google OAuth2 authentication for Calendar API';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Setting up Google OAuth2 authentication...');

        try {
            $credentialsPath = storage_path('app/google/oauth2_credentials.json');

            if (!file_exists($credentialsPath)) {
                $this->error('OAuth2 credentials file not found at: ' . $credentialsPath);
                $this->info('Please ensure the credentials file is in the correct location.');
                return 1;
            }

            $client = new Client();
            $client->setAuthConfig($credentialsPath);
            $client->addScope([
                'https://www.googleapis.com/auth/calendar',
                'https://www.googleapis.com/auth/calendar.events'
            ]);
            $client->setRedirectUri('http://127.0.0.1:8000/');
            $client->setAccessType('offline');
            $client->setPrompt('select_account consent');

            // Generate authentication URL
            $authUrl = $client->createAuthUrl();

            $this->info('1. Open the following link in your browser:');
            $this->line($authUrl);
            $this->newLine();

            $this->info('2. Complete the authorization process');
            $this->info('3. After granting permission, you will be redirected to http://127.0.0.1:8000/');
            $this->info('4. Copy the "code" parameter from the URL in your browser address bar');
            $this->info('   Example: http://127.0.0.1:8000/?code=AUTHORIZATION_CODE&scope=...');
            $this->info('   Copy only the AUTHORIZATION_CODE part');
            $this->newLine();

            $authCode = $this->ask('Enter the authorization code from the URL');

            if (empty($authCode)) {
                $this->error('Authorization code is required');
                return 1;
            }

            // Exchange authorization code for access token
            $accessToken = $client->fetchAccessTokenWithAuthCode($authCode);

            if (array_key_exists('error', $accessToken)) {
                $this->error('Error fetching access token: ' . $accessToken['error']);
                return 1;
            }

            // Save the token for future use
            $tokenPath = storage_path('app/google/token.json');
            if (!file_put_contents($tokenPath, json_encode($accessToken))) {
                $this->error('Failed to save access token');
                return 1;
            }

            $this->success('Google OAuth2 authentication setup completed successfully!');
            $this->info('Token saved to: ' . $tokenPath);
            $this->newLine();
            $this->info('You can now use the Google Meet integration for appointments.');

            return 0;

        } catch (Exception $e) {
            $this->error('Setup failed: ' . $e->getMessage());
            return 1;
        }
    }
}
