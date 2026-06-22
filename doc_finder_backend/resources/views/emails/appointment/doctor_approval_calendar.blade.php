<!DOCTYPE html>
<html>
<head>
    <title>New Appointment Confirmed</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background-color: #008faf;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px 5px 0 0;
        }
        .content {
            background-color: #f9f9f9;
            padding: 30px;
            border-radius: 0 0 5px 5px;
        }
        .appointment-details {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
            border: 1px solid #ddd;
        }
        .calendar-link {
            background-color: #4CAF50;
            color: white;
            padding: 15px;
            text-align: center;
            border-radius: 5px;
            margin: 20px 0;
        }
        .calendar-link a {
            color: white;
            text-decoration: none;
            font-weight: bold;
            font-size: 16px;
        }
        .footer {
            text-align: center;
            color: #666;
            font-size: 12px;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
        }
        .important {
            color: #e74c3c;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📋 New Appointment Confirmed</h1>
    </div>

    <div class="content">
        <p>Dear Dr. {{ $doctor_name }},</p>

        <p>You have a new confirmed appointment with <strong>{{ $patient_name }}</strong>.</p>

        <div class="appointment-details">
            <h3>📅 Appointment Details</h3>
            <ul>
                <li><strong>Patient:</strong> {{ $patient_name }}</li>
                <li><strong>Date:</strong> {{ $appointment_date }}</li>
                <li><strong>Time:</strong> {{ $appointment_time }}</li>
                <li><strong>Type:</strong> {{ ucfirst(str_replace('_', ' ', $consultation_type)) }} Consultation</li>
            </ul>

            @if($notes)
            <p><strong>Patient Notes:</strong> {{ $notes }}</p>
            @endif
        </div>

        <div class="calendar-link">
            <h3>📅 Add to Your Calendar</h3>
            <p>{{ $is_gmail ? 'Click the button below to add this appointment to your Google Calendar:' : 'Click the button below to download a calendar file:' }}</p>
            <a href="{{ $calendar_link }}" target="_blank">
                {{ $is_gmail ? 'Add to Google Calendar' : 'Download Calendar Event' }}
            </a>
        </div>

        @if($consultation_type === 'online')
        <div style="background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 20px 0; border: 1px solid #b3d9e8;">
            <h4>💻 Online Consultation Preparation:</h4>
            <ul>
                <li>Ensure your device has a stable internet connection</li>
                <li>Test your camera and microphone beforehand</li>
                <li>Choose a quiet, private location for the consultation</li>
                <li>Have the patient's medical history readily available</li>
                <li>Prepare any relevant forms or documentation</li>
            </ul>
            <p><span class="important">Note:</span> Virtual consultation platform details will be provided closer to the appointment time.</p>
        </div>
        @endif

        @if($consultation_type === 'in_person')
        <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; border: 1px solid #c3e6c3;">
            <h4>🏥 In-Person Consultation</h4>
            <p>This is an in-person consultation at your clinic.</p>
            <p><strong>Preparation reminders:</strong></p>
            <ul>
                <li>Ensure the consultation room is prepared</li>
                <li>Review the patient's medical history if available</li>
                <li>Have necessary medical equipment ready</li>
                <li>Allocate appropriate time for the consultation</li>
            </ul>
        </div>
        @endif

        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #008faf;">
            <h4>📞 Need Support?</h4>
            <p>If you have any questions about this appointment or need assistance, please contact us:</p>
            <p>
                <strong>Email:</strong> support@docfinder.com<br>
                <strong>Phone:</strong> +254 xxx xxx xxx
            </p>
        </div>

        <p>Thank you for providing excellent medical care through our platform!</p>

        <p>Best regards,<br>
        <strong>DocFinder Team</strong></p>
    </div>

    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
        <p>&copy; {{ date('Y') }} DocFinder. All rights reserved.</p>
    </div>
</body>
</html>