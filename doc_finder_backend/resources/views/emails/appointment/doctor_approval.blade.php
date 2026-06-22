<!DOCTYPE html>
<html>
<head>
    <title>New Appointment Scheduled</title>
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
            background-color: #2c3e50;
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
        .patient-details {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
            border: 1px solid #ddd;
        }
        .appointment-details {
            background-color: #e8f4fd;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
            border: 1px solid #bee5eb;
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
        <h1>📅 New Patient Appointment</h1>
    </div>

    <div class="content">
        <p>Dear Dr. {{ $doctor_name }},</p>

        <p>You have a new confirmed appointment scheduled with a patient.</p>

        <div class="patient-details">
            <h3>👤 Patient Information</h3>
            <ul>
                <li><strong>Name:</strong> {{ $patient_name }}</li>
                <li><strong>Email:</strong> {{ $patient_email }}</li>
                <li><strong>Phone:</strong> {{ $patient_telephone }}</li>
                @if($patient_location)
                <li><strong>Location:</strong> {{ $patient_location }}</li>
                @endif
            </ul>
        </div>

        <div class="appointment-details">
            <h3>📅 Appointment Details</h3>
            <ul>
                <li><strong>Date:</strong> {{ $appointment_date }}</li>
                <li><strong>Time:</strong> {{ $appointment_time }}</li>
                <li><strong>Type:</strong> {{ ucfirst(str_replace('_', ' ', $consultation_type)) }} Consultation</li>
            </ul>

            @if($notes)
            <div style="margin-top: 15px;">
                <strong>Patient Notes:</strong>
                <p style="background-color: #fff; padding: 10px; border-radius: 3px; border: 1px solid #ddd;">{{ $notes }}</p>
            </div>
            @endif
        </div>

        @if($meet_link && $consultation_type === 'online')
        <div class="meet-link">
            <h3>🎥 Virtual Consultation Link</h3>
            <p>Use this link to join the consultation:</p>
            <a href="{{ $meet_link }}" target="_blank">Join Google Meet</a>
            <p style="font-size: 12px; margin-top: 10px;">
                <span class="important">Note:</span> The patient will also receive this link.
            </p>
        </div>

        <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border: 1px solid #ffeaa7;">
            <h4>💡 Virtual Consultation Tips:</h4>
            <ul>
                <li>Join the meeting a few minutes early to test your setup</li>
                <li>Ensure good lighting for the video call</li>
                <li>Have the patient's details and any relevant medical records ready</li>
                <li>Consider screen sharing for explaining diagnosis or treatment plans</li>
            </ul>
        </div>
        @endif

        @if($consultation_type === 'in_person')
        <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; border: 1px solid #c3e6c3;">
            <h4>🏥 In-Person Consultation</h4>
            <p>The patient will arrive at your clinic for this appointment.</p>
            <p><strong>Please ensure:</strong></p>
            <ul>
                <li>Your clinic is prepared for the patient's arrival</li>
                <li>All necessary equipment is ready</li>
                <li>Patient records are accessible</li>
            </ul>
        </div>
        @endif

        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #2c3e50;">
            <h4>⚠️ Important Reminders:</h4>
            <ul>
                <li>This appointment has been automatically added to your calendar (if you have a Google account)</li>
                <li>Please arrive/join on time to maintain schedule efficiency</li>
                <li>If you need to reschedule, please notify the patient as soon as possible</li>
                <li>For any technical issues with virtual consultations, contact support immediately</li>
            </ul>
        </div>

        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #008faf;">
            <h4>📞 Need Support?</h4>
            <p>For any questions or technical support, contact us:</p>
            <p>Email: <strong>support@docfinder.com</strong> | Phone: <strong>+254 xxx xxx xxx</strong></p>
        </div>

        <p>Thank you for your commitment to providing excellent patient care.</p>

        <p>Best regards,<br>
        <strong>DocFinder Team</strong></p>
    </div>

    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
        <p>&copy; {{ date('Y') }} DocFinder. All rights reserved.</p>
    </div>
</body>
</html>