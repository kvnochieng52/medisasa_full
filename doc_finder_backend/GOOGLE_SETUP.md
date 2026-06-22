# Google Meet & Calendar API Setup Guide

This guide explains how to set up Google Calendar API integration for automatic Google Meet creation when appointments are approved.

## Prerequisites

1. Google Cloud Console access
2. A Google Workspace account (for Google Meet functionality)
3. Laravel backend with the Google Meet integration code

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note down your project ID

## Step 2: Enable Required APIs

Enable the following APIs in your Google Cloud project:

1. **Google Calendar API**
   - Go to APIs & Services > Library
   - Search for "Google Calendar API"
   - Click "Enable"

2. **Google Workspace Meet API** (Optional, for advanced features)
   - Search for "Google Meet API"
   - Click "Enable"

## Step 3: Create Service Account

1. Go to APIs & Services > Credentials
2. Click "Create Credentials" > "Service Account"
3. Fill in the details:
   - Service account name: `docfinder-calendar-service`
   - Service account ID: `docfinder-calendar`
   - Description: `Service account for DocFinder appointment calendar integration`
4. Click "Create and Continue"
5. Grant roles:
   - **Calendar API User** (for basic calendar access)
   - **Service Account User** (for service account usage)
6. Click "Continue" and then "Done"

## Step 4: Generate Service Account Key

1. In the Credentials page, find your service account
2. Click on the service account name
3. Go to the "Keys" tab
4. Click "Add Key" > "Create New Key"
5. Choose "JSON" format
6. Download the JSON file

## Step 5: Configure Laravel Application

1. Copy the downloaded JSON file to your Laravel storage directory:
   ```
   storage/app/google/credentials.json
   ```

2. Update your `.env` file (already configured):
   ```
   GOOGLE_CREDENTIALS_PATH=storage/app/google/credentials.json
   GOOGLE_APPLICATION_NAME="DocFinder Appointment System"
   ```

3. Clear Laravel config cache:
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

## Step 6: Grant Calendar Access to Service Account

For the service account to create calendar events, you need to:

### Option A: Use Doctor's Personal Calendars
Each doctor needs to share their Google Calendar with the service account:

1. Doctor opens Google Calendar
2. Go to Calendar Settings > Share with specific people
3. Add the service account email (from credentials.json: `client_email`)
4. Grant "Make changes to events" permission

### Option B: Use a Shared Calendar (Recommended)
Create a shared calendar for the clinic:

1. Create a new calendar in Google Calendar
2. Share it with all doctors (with edit permissions)
3. Share it with the service account (with edit permissions)
4. Update the calendar ID in the GoogleMeetService if needed

## Step 7: Test the Integration

1. Create a test appointment through your API
2. Update the appointment status to "confirmed"
3. Check if:
   - Google Meet link is generated
   - Calendar events are created
   - Email notifications are sent
   - Meet link is accessible

## Step 8: Install Required PHP Packages

Make sure you have the Google Client library installed:

```bash
composer require google/apiclient
```

## Troubleshooting

### Common Issues:

1. **"Service account not found" error**
   - Verify the credentials.json file is in the correct location
   - Check file permissions

2. **"Insufficient permissions" error**
   - Ensure the service account has the correct roles
   - Verify calendar sharing permissions

3. **"Calendar not found" error**
   - Check if the target calendar exists
   - Verify the calendar ID is correct

4. **"Meet link not generated" error**
   - Ensure you have Google Workspace (not personal Google account)
   - Verify Google Meet API is enabled

### Debug Steps:

1. Check Laravel logs in `storage/logs/laravel.log`
2. Enable debug mode in `.env`: `APP_DEBUG=true`
3. Test API credentials:
   ```bash
   php artisan tinker
   $service = new \App\Services\GoogleMeetService();
   $service->testConnection();
   ```

## Security Notes

1. **Never commit credentials.json to version control**
2. **Restrict service account permissions** to only what's needed
3. **Monitor API usage** in Google Cloud Console
4. **Rotate service account keys** periodically
5. **Use environment variables** for sensitive configuration

## API Quotas

Google Calendar API has the following default quotas:
- 1,000,000 requests per day
- 100 requests per 100 seconds per user

Monitor your usage in Google Cloud Console under APIs & Services > Quotas.

## Support

For issues with this integration:
1. Check Laravel logs
2. Verify Google Cloud Console settings
3. Test with a simple calendar event creation
4. Contact the development team with specific error messages

---

**Note**: This setup requires Google Workspace for Google Meet functionality. Personal Google accounts can create calendar events but may not generate Meet links automatically.