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
        <p>Dear {{ $patient_name }},</p>

        <p>We regret to inform you that your appointment with <strong>Dr. {{ $doctor_name }}</strong> has been cancelled.</p>

        <div class="appointment-details">
            <h3>📅 Cancelled Appointment Details</h3>
            <ul>
                <li><strong>Doctor:</strong> Dr. {{ $doctor_name }}</li>
                <li><strong>Date:</strong> {{ $appointment_date }}</li>
                <li><strong>Time:</strong> {{ $appointment_time }}</li>
            </ul>
        </div>

        <div class="info-box">
            <h4>📞 Need to Reschedule?</h4>
            <p>We apologize for any inconvenience caused. If you would like to schedule a new appointment, please contact us:</p>
            <p>
                <strong>Email:</strong> support@docfinder.com<br>
                <strong>Phone:</strong> +254 xxx xxx xxx
            </p>
            <p>Our team will be happy to help you find an alternative appointment time that works for you.</p>
        </div>

        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #008faf;">
            <h4>ℹ️ What Happens Next?</h4>
            <ul>
                <li>Any calendar events related to this appointment have been cancelled</li>
                <li>If this was an online consultation, the Google Meet link is no longer valid</li>
                <li>No charges have been applied to your account for this cancellation</li>
                <li>You can book a new appointment at any time through our platform</li>
            </ul>
        </div>

        <p>Thank you for your understanding, and we look forward to serving you in the future.</p>

        <p>Best regards,<br>
        <strong>DocFinder Medical Team</strong></p>
    </div>

    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
        <p>&copy; {{ date('Y') }} DocFinder. All rights reserved.</p>
    </div>
</body>
</html>