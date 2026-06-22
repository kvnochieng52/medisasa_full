{{-- Shared head + header partial. Include from individual prescription templates. --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{{ $title ?? 'MediSasa Prescription' }}</title>
    <style>
        @page { margin: 24px 28px; }
        body { font-family: DejaVu Sans, sans-serif; font-size: 11px; color: #1a202c; }
        .header { border-bottom: 2px solid #008faf; padding-bottom: 12px; margin-bottom: 14px; }
        .header table { width: 100%; }
        .brand-cell { width: 70%; vertical-align: middle; }
        .brand-cell .logo { width: 56px; height: 56px; float: left; margin-right: 10px; }
        .brand-cell .brand-name { font-size: 20px; font-weight: bold; color: #008faf; }
        .brand-cell .tagline { font-size: 10px; color: #4a5568; }
        .meta-cell { width: 30%; text-align: right; vertical-align: middle; font-size: 10px; color: #4a5568; }
        .meta-cell .rx-no { font-weight: bold; color: #1a202c; font-size: 12px; }
        .section { margin-bottom: 14px; }
        .section h2 { font-size: 12px; color: #008faf; text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid #e2e8f0; padding-bottom: 3px; margin: 0 0 6px; }
        .grid { width: 100%; }
        .grid td { vertical-align: top; padding-right: 12px; padding-bottom: 4px; }
        .label { color: #718096; font-size: 9px; text-transform: uppercase; letter-spacing: 0.4px; display: block; margin-bottom: 1px; }
        .value { font-size: 11px; color: #1a202c; }
        table.items { width: 100%; border-collapse: collapse; margin-top: 4px; }
        table.items th { background: #008faf; color: #fff; text-align: left; padding: 6px 8px; font-size: 10px; font-weight: bold; text-transform: uppercase; }
        table.items td { padding: 7px 8px; border-bottom: 1px solid #e2e8f0; font-size: 10.5px; vertical-align: top; }
        table.items tr:nth-child(even) td { background: #f7fafc; }
        .pill { display: inline-block; padding: 1px 7px; border-radius: 10px; font-size: 9px; font-weight: bold; text-transform: uppercase; }
        .pill-routine { background: #e6fffa; color: #234e52; }
        .pill-urgent { background: #fefcbf; color: #744210; }
        .pill-stat { background: #fed7d7; color: #742a2a; }
        .signature { margin-top: 28px; }
        .signature .line { border-top: 1px solid #4a5568; width: 220px; margin-bottom: 4px; }
        .footer { position: fixed; bottom: -10px; left: 0; right: 0; text-align: center; font-size: 9px; color: #718096; border-top: 1px solid #e2e8f0; padding-top: 6px; }
    </style>
</head>
<body>
    <div class="header">
        <table>
            <tr>
                <td class="brand-cell">
                    @if($logoPath && file_exists($logoPath))
                        <img src="{{ $logoPath }}" class="logo" alt="MediSasa">
                    @endif
                    <div class="brand-name">MediSasa</div>
                    <div class="tagline">Your Health, Our Priority</div>
                </td>
                <td class="meta-cell">
                    <div class="rx-no">Rx No.</div>
                    <div>{{ $rx->prescription_number }}</div>
                    <div style="margin-top:6px;">Issued: {{ $rx->issued_date->format('d M Y') }}</div>
                </td>
            </tr>
        </table>
    </div>

    {{ $slot ?? '' }}
    @yield('content')

    <div class="footer">
        MediSasa &middot; Nairobi, Kenya &middot; support@medisasa.co.ke &middot; +254 759 000 652
    </div>
</body>
</html>
