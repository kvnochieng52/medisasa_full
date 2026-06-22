<!DOCTYPE html>
<html>
<head>
    <title>Appointment Confirmed</title>
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
        .meet-link {
            background-color: #4CAF50;
            color: white;
            padding: 15px;
            text-align: center;
            border-radius: 5px;
            margin: 20px 0;
        }
        .meet-link a {
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
        <h1>✅ Appointment Confirmed</h1>
    </div>

    <div class="content">
        <p>Dear {{ $patient_name }},</p>

        <p>Great news! Your appointment with <strong>Dr. {{ $doctor_name }}</strong> has been confirmed.</p>

        <div class="appointment-details">
            <h3>📅 Appointment Details</h3>
            <ul>
                <li><strong>Doctor:</strong> Dr. {{ $doctor_name }}</li>
                <li><strong>Date:</strong> {{ $appointment_date }}</li>
                <li><strong>Time:</strong> {{ $appointment_time }}</li>
                <li><strong>Type:</strong> {{ ucfirst(str_replace('_', ' ', $consultation_type)) }} Consultation</li>
            </ul>

            @if($notes)
            <p><strong>Notes:</strong> {{ $notes }}</p>
            @endif
        </div>

        @if($meet_link && $consultation_type === 'online')
        <div class="meet-link">
            <h3>🎥 Join Your Virtual Consultation</h3>
            <p>Click the button below to join your appointment:</p>
            <a href="{{ $meet_link }}" target="_blank">Join Google Meet</a>
            <p style="font-size: 12px; margin-top: 10px;">
                <span class="important">Important:</span> Please join the meeting 5 minutes before your scheduled time.
            </p>
        </div>

        <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border: 1px solid #ffeaa7;">
            <h4>📱 How to Prepare for Your Virtual Consultation:</h4>
            <ul>
                <li>Ensure you have a stable internet connection</li>
                <li>Test your camera and microphone beforehand</li>
                <li>Find a quiet, well-lit space for the consultation</li>
                <li>Have your medical history and current medications ready</li>
                <li>Prepare any questions you want to ask the doctor</li>
            </ul>
        </div>
        @endif

        @if($consultation_type === 'in_person')
        <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; border: 1px solid #c3e6c3;">
            <h4>🏥 In-Person Consultation</h4>
            <p>Please arrive at the clinic 15 minutes before your scheduled appointment time.</p>
            <p><strong>What to bring:</strong></p>
            <ul>
                <li>Valid identification document</li>
                <li>Insurance card (if applicable)</li>
                <li>List of current medications</li>
                <li>Any previous medical reports or test results</li>
            </ul>
        </div>
        @endif

        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #008faf;">
            <h4>📞 Need to Reschedule or Cancel?</h4>
            <p>If you need to make any changes to your appointment, please contact us at least 24 hours in advance.</p>
            <p>Contact: <strong>support@docfinder.com</strong> | Phone: <strong>+254 xxx xxx xxx</strong></p>
        </div>

        <p>We look forward to providing you with excellent medical care!</p>

        <p>Best regards,<br>
        <strong>DocFinder Medical Team</strong></p>
    </div>

    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
        <p>&copy; {{ date('Y') }} DocFinder. All rights reserved.</p>
    </div>
</body>
</html>