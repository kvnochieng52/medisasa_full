@extends('prescriptions._layout', ['title' => 'Radiology Order - ' . $rx->prescription_number])

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
                <td style="width:40%"><span class="label">Name</span><span class="value">{{ $rx->patient_name }}</span></td>
                <td style="width:20%"><span class="label">Sex</span><span class="value">{{ $rx->patient_sex ? ucfirst($rx->patient_sex) : '—' }}</span></td>
                <td style="width:20%"><span class="label">Age</span><span class="value">{{ $rx->patient_age ?: '—' }}</span></td>
                <td style="width:20%"><span class="label">Date of Birth</span><span class="value">{{ $rx->patient_dob ? $rx->patient_dob->format('d M Y') : '—' }}</span></td>
            </tr>
            <tr>
                <td><span class="label">Phone</span><span class="value">{{ $rx->patient_phone ?: '—' }}</span></td>
                <td colspan="3"><span class="label">Email</span><span class="value">{{ $rx->patient_email ?: '—' }}</span></td>
            </tr>
        </table>
    </div>

    @if($rx->clinical_information)
        <div class="section">
            <h2>Clinical Information</h2>
            <div class="value">{{ $rx->clinical_information }}</div>
        </div>
    @endif

    <div class="section">
        <h2>Studies Ordered</h2>
        <table class="items">
            <thead>
                <tr>
                    <th style="width:4%">#</th>
                    <th style="width:22%">Study</th>
                    <th style="width:11%">Modality</th>
                    <th style="width:17%">Body Part / Side</th>
                    <th style="width:11%">Contrast</th>
                    <th style="width:9%">Urgency</th>
                    <th style="width:26%">Clinical Indication / Notes</th>
                </tr>
            </thead>
            <tbody>
                @foreach($rx->items as $i => $item)
                    <tr>
                        <td>{{ $i + 1 }}</td>
                        <td><strong>{{ $item->study_name }}</strong></td>
                        <td>{{ $item->modality ?: '—' }}</td>
                        <td>
                            {{ $item->body_part ?: '—' }}
                            @if($item->side) &middot; {{ ucfirst($item->side) }} @endif
                        </td>
                        <td>{{ $item->contrast ? ucfirst($item->contrast) : '—' }}</td>
                        <td>
                            <span class="pill pill-{{ $item->urgency }}">{{ ucfirst($item->urgency) }}</span>
                        </td>
                        <td>
                            @if($item->clinical_indication)
                                <em>{{ $item->clinical_indication }}</em>
                                @if($item->notes)<br>@endif
                            @endif
                            {{ $item->notes ?: '' }}
                            @if(!$item->clinical_indication && !$item->notes) — @endif
                        </td>
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
