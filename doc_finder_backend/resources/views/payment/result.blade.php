<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment {{ ucfirst($status) }} - Doc Finder</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #f5f5f5;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 20px;
        }
        .card {
            background: #fff;
            border-radius: 16px;
            padding: 40px 32px;
            max-width: 420px;
            width: 100%;
            text-align: center;
            box-shadow: 0 4px 24px rgba(0,0,0,0.08);
        }
        .icon {
            width: 72px; height: 72px;
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 24px;
            font-size: 32px;
        }
        .icon.success   { background: #e6f9f0; color: #22c55e; }
        .icon.failed    { background: #fef2f2; color: #ef4444; }
        .icon.cancelled { background: #fef9ec; color: #f59e0b; }
        .icon.error     { background: #f5f5f5; color: #6b7280; }
        h1 { font-size: 22px; color: #111; margin-bottom: 12px; }
        p  { font-size: 15px; color: #555; line-height: 1.6; }
        .btn {
            display: inline-block;
            margin-top: 28px;
            padding: 14px 32px;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 600;
            text-decoration: none;
            color: #fff;
            cursor: pointer;
            border: none;
            width: 100%;
        }
        .btn.success   { background: #22c55e; }
        .btn.failed    { background: #ef4444; }
        .btn.cancelled { background: #f59e0b; }
        .btn.error     { background: #6b7280; }
        .note {
            margin-top: 16px;
            font-size: 12px;
            color: #aaa;
        }
        .countdown {
            margin-top: 12px;
            font-size: 13px;
            color: #888;
        }
    </style>
</head>
<body>
<div class="card">
    <div class="icon {{ $status }}">
        @if($status === 'success')   ✓
        @elseif($status === 'failed')    ✕
        @elseif($status === 'cancelled') ⚠
        @else                            !
        @endif
    </div>

    <h1>
        @if($status === 'success')   Payment Successful
        @elseif($status === 'failed')    Payment Failed
        @elseif($status === 'cancelled') Payment Cancelled
        @else                            Something Went Wrong
        @endif
    </h1>

    <p>{{ $message }}</p>

    @php
        $isMobile    = isset($_SERVER['HTTP_USER_AGENT']) && preg_match('/android|iphone|ipad|mobile/i', $_SERVER['HTTP_USER_AGENT']);
        $tokenParam  = $transToken ? '?token=' . urlencode($transToken) : '';
        $deepLink    = match($status) {
            'success'   => 'xyvrahealth:///payment/success' . $tokenParam,
            'failed'    => 'xyvrahealth:///payment/failed'  . $tokenParam,
            default     => 'xyvrahealth:///payment/cancel',
        };
        $intentToken = $transToken ? urlencode($transToken) : '';
        $intentPath  = match($status) {
            'success'   => '/payment/success' . ($transToken ? '%3Ftoken%3D' . $intentToken : ''),
            'failed'    => '/payment/failed'  . ($transToken ? '%3Ftoken%3D' . $intentToken : ''),
            default     => '/payment/cancel',
        };
        $intentLink = 'intent://' . $intentPath . '#Intent;scheme=xyvrahealth;package=com.xyvrahealth.app;end';
    @endphp

    @if($isMobile)
        {{-- Mobile: deep-link back to the app --}}
        <button class="btn {{ $status }}" onclick="openApp()">Return to App</button>
        <p class="note">If the button doesn't work, switch back to the Doc Finder app manually.</p>
    @else
        {{-- Web: close the tab; the opener tab detects payment via polling --}}
        <button class="btn {{ $status }}" onclick="window.close()">
            @if($status === 'success') Close This Tab
            @else Close & Return
            @endif
        </button>
        @if($status === 'success')
            <p class="countdown" id="countdown">Closing in <span id="timer">3</span>s…</p>
        @endif
        <p class="note">Switch back to the Doc Finder tab — your subscription will be confirmed automatically.</p>
    @endif
</div>

<script>
    var isAndroid  = /android/i.test(navigator.userAgent);
    var appOpened  = false;

    document.addEventListener('visibilitychange', function() {
        if (document.hidden) appOpened = true;
    });

    function openApp() {
        var deepLink   = '{{ $deepLink }}';
        var intentLink = '{{ $intentLink }}';
        if (isAndroid) {
            window.location.href = deepLink;
            setTimeout(function() {
                if (!appOpened) window.location.href = intentLink;
            }, 600);
        } else {
            window.location.href = deepLink;
        }
    }

    @if($status === 'success')
    // Auto-close (web) or auto-deep-link (mobile) after 3 seconds
    var seconds = 3;
    var timerEl = document.getElementById('timer');
    var interval = setInterval(function() {
        seconds--;
        if (timerEl) timerEl.textContent = seconds;
        if (seconds <= 0) {
            clearInterval(interval);
            var isMobileUA = /android|iphone|ipad|mobile/i.test(navigator.userAgent);
            if (isMobileUA) {
                openApp();
            } else {
                window.close();
            }
        }
    }, 1000);
    @endif
</script>
</body>
</html>
