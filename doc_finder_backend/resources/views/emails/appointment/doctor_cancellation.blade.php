<!DOCTYPE html>
<html>
<head>
    <title>Appointment Cancelled</title>
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
            background-color: #e74c3c;
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
        .footer {
            text-align: center;
            color: #666;
            font-size: 12px;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
        }
        .info-box {
            background-color: #fff3cd;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            border: 1px solid #ffeaa7;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>❌ Appointment Cancelled</h1>
    </div>

    <div class="content">
        <p>Dear Dr. {{ $doctor_name }},</p>

        <p>This is to notify you that the appointment with <strong>{{ $patient_name }}</strong> has been cancelled.</p>

        <div class="appointment-details">
            <h3>📅 Cancelled Appointment Details</h3>
            <ul>
                <li><strong>Patient:</strong> {{ $patient_name }}</li>
                <li><strong>Date:</strong> {{ $appointment_date }}</li>
                <li><strong>Time:</strong> {{ $appointment_time }}</li>
            </ul>
        </div>

        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #008faf;">
            <h4>ℹ️ What Has Been Done:</h4>
            <ul>
                <li>The appointment has been removed from your schedule</li>
                <li>Any calendar events have been cancelled automatically</li>
                <li>If this was an online consultation, the Google Meet link has been deactivated</li>
                <li>The patient has been notified of the cancellation</li>
                <li>This time slot is now available for new bookings</li>
            </ul>
        </div>

        <div class="info-box">
            <h4>📞 Need Support?</h4>
            <p>If you have any questions about this cancellation or need assistance with your schedule, please contact us:</p>
            <p>
                <strong>Email:</strong> support@docfinder.com<br>
                <strong>Phone:</strong> +254 xxx xxx xxx
            </p>
        </div>

        <p>Thank you for your understanding.</p>

        <p>Best regards,<br>
        <strong>DocFinder Team</strong></p>
    </div>

    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
        <p>&copy; {{ date('Y') }} DocFinder. All rights reserved.</p>
    </div>
</body>
</html>