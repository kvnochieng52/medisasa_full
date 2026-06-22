@extends('prescriptions._layout', ['title' => 'Medication Prescription - ' . $rx->prescription_number])

@section('content')
    <div class="section">
        <h2>Prescriber</h2>
        <table class="grid">
            <tr>
                <td style="width:50%"><span class="label">Doctor</span><span class="value">{{ $rx->prescriber_name }}</span></td>
                <td style="width:50%"><span class="label">Licence No.</span><span class="value">{{ $rx->prescriber_licence_number ?: '—' }}</span></td>
            </tr>
            <tr>
                <td><span class="label">Phone</span><span class="value">{{ $rx->prescriber_phone ?: '—' }}</span></td>
                <td><span class="label">Email</span><span class="value">{{ $rx->prescriber_email ?: '—' }}</span></td>
            </tr>
            @if($rx->clinic_name || $rx->clinic_address)
                <tr>
                    <td><span class="label">Clinic</span><span class="value">{{ $rx->clinic_name ?: '—' }}</span></td>
                    <td><span class="label">Clinic Address</span><span class="value">{{ $rx->clinic_address ?: '—' }}</span></td>
                </tr>
            @endif
        </table>
    </div>

    <div class="section">
        <h2>Patient</h2>
        <table class="grid">
            <tr>
                <td style="width:50%"><span class="label">Name</span><span class="value">{{ $rx->patient_name }}</span></td>
                <td style="width:25%"><span class="label">Age</span><span class="value">{{ $rx->patient_age ?: '—' }}</span></td>
                <td style="width:25%"><span class="label">Date of Birth</span><span class="value">{{ $rx->patient_dob ? $rx->patient_dob->format('d M Y') : '—' }}</span></td>
            </tr>
            <tr>
                <td><span class="label">Phone</span><span class="value">{{ $rx->patient_phone ?: '—' }}</span></td>
                <td colspan="2"><span class="label">Email</span><span class="value">{{ $rx->patient_email ?: '—' }}</span></td>
            </tr>
        </table>
    </div>

    @if($rx->diagnosis)
        <div class="section">
            <h2>Diagnosis</h2>
            <div class="value">{{ $rx->diagnosis }}</div>
        </div>
    @endif

    <div class="section">
        <h2>Medications</h2>
        <table class="items">
            <thead>
                <tr>
                    <th style="width:4%">#</th>
                    <th style="width:24%">Drug</th>
                    <th style="width:12%">Form / Strength</th>
                    <th style="width:16%">Sig (frequency &middot; route &middot; duration)</th>
                    <th style="width:14%">Quantity</th>
                    <th style="width:7%">Refills</th>
                    <th style="width:23%">Instructions</th>
                </tr>
            </thead>
            <tbody>
                @foreach($rx->items as $i => $item)
                    <tr>
                        <td>{{ $i + 1 }}</td>
                        <td><strong>{{ $item->drug_name }}</strong></td>
                        <td>{{ trim(($item->dosage_form ?: '') . ' ' . ($item->strength ?: '')) ?: '—' }}</td>
                        <td>
                            {{ $item->frequency ?: '—' }}
                            @if($item->route) &middot; {{ $item->route }} @endif
                            @if($item->duration) &middot; {{ $item->duration }} @endif
                        </td>
                        <td>{{ $item->quantity ?: '—' }}</td>
                        <td>{{ (int) $item->refills }}</td>
                        <td>{{ $item->instructions ?: '—' }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>

    @if($rx->notes)
        <div class="section">
            <h2>Notes</h2>
            <div class="value">{{ $rx->notes }}</div>
        </div>
    @endif

    <div class="signature">
        <div class="line"></div>
        <div class="value">{{ $rx->prescriber_name }}</div>
        @if($rx->prescriber_licence_number)
            <div class="label">Licence No. {{ $rx->prescriber_licence_number }}</div>
        @endif
    </div>
@endsection
