<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\LabPrescription;
use App\Models\LabPrescriptionItem;
use App\Models\MedicationPrescription;
use App\Models\MedicationPrescriptionItem;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class PrescriptionController extends Controller
{
    // ---------------------------------------------------------------------
    // Medication prescriptions
    // ---------------------------------------------------------------------

    public function storeMedication(Request $request)
    {
        $user = $request->user();
        if (!$user || !$user->isServiceProvider()) {
            return response()->json(['success' => false, 'message' => 'Only service providers can issue prescriptions.'], 403);
        }

        $data = $request->validate([
            'appointment_id' => 'nullable|exists:appointments,id',
            'clinic_name' => 'nullable|string|max:255',
            'clinic_address' => 'nullable|string|max:500',
            'patient_name' => 'required|string|max:255',
            'patient_email' => 'nullable|email|max:255',
            'patient_phone' => 'nullable|string|max:50',
            'patient_dob' => 'nullable|date',
            'patient_age' => 'nullable|integer|min:0|max:150',
            'diagnosis' => 'nullable|string',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.drug_name' => 'required|string|max:255',
            'items.*.dosage_form' => 'nullable|string|max:100',
            'items.*.strength' => 'nullable|string|max:100',
            'items.*.frequency' => 'nullable|string|max:100',
            'items.*.route' => 'nullable|string|max:100',
            'items.*.duration' => 'nullable|string|max:100',
            'items.*.quantity' => 'nullable|string|max:100',
            'items.*.refills' => 'nullable|integer|min:0|max:99',
            'items.*.instructions' => 'nullable|string',
        ]);

        $rx = DB::transaction(function () use ($user, $data) {
            $rx = MedicationPrescription::create([
                'prescription_number' => $this->generateNumber('MRX'),
                'doctor_id' => $user->id,
                'appointment_id' => $data['appointment_id'] ?? null,
                'prescriber_name' => $user->name,
                'prescriber_licence_number' => $user->licence_number,
                'prescriber_phone' => $user->telephone,
                'prescriber_email' => $user->email,
                'clinic_name' => $data['clinic_name'] ?? null,
                'clinic_address' => $data['clinic_address'] ?? null,
                'patient_name' => $data['patient_name'],
                'patient_email' => $data['patient_email'] ?? null,
                'patient_phone' => $data['patient_phone'] ?? null,
                'patient_dob' => $data['patient_dob'] ?? null,
                'patient_age' => $data['patient_age'] ?? null,
                'issued_date' => now()->toDateString(),
                'diagnosis' => $data['diagnosis'] ?? null,
                'notes' => $data['notes'] ?? null,
            ]);

            foreach ($data['items'] as $item) {
                MedicationPrescriptionItem::create(array_merge(
                    $item,
                    ['medication_prescription_id' => $rx->id, 'refills' => $item['refills'] ?? 0]
                ));
            }

            return $rx->load('items');
        });

        return response()->json(['success' => true, 'data' => $rx], 201);
    }

    public function indexMedication(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $query = MedicationPrescription::with('items')->orderByDesc('issued_date');
        $this->scopeToCurrentUser($query, $user);

        $perPage = (int) $request->input('per_page', 20);
        return response()->json([
            'success' => true,
            'data' => $query->paginate($perPage),
        ]);
    }

    public function showMedication(Request $request, $id)
    {
        $user = $request->user();
        $rx = MedicationPrescription::with('items')->findOrFail($id);
        $this->authorizeView($rx, $user);
        return response()->json(['success' => true, 'data' => $rx]);
    }

    public function pdfMedication(Request $request, $id)
    {
        $user = $request->user();
        $rx = MedicationPrescription::with('items')->findOrFail($id);
        $this->authorizeView($rx, $user);

        $pdf = Pdf::loadView('prescriptions.medication_pdf', [
            'rx' => $rx,
            'logoPath' => $this->logoPath(),
        ]);

        return $pdf->download($this->pdfFilename($rx));
    }

    public function emailMedication(Request $request, $id)
    {
        $user = $request->user();
        $rx = MedicationPrescription::with('items')->findOrFail($id);
        $this->authorizeView($rx, $user);

        $request->validate(['email' => 'nullable|email']);
        $to = $request->input('email') ?: $rx->patient_email;
        if (!$to) {
            return response()->json(['success' => false, 'message' => 'No recipient email provided.'], 422);
        }

        return $this->sendPrescriptionEmail($rx, $to, 'medication');
    }

    // ---------------------------------------------------------------------
    // Lab prescriptions
    // ---------------------------------------------------------------------

    public function storeLab(Request $request)
    {
        $user = $request->user();
        if (!$user || !$user->isServiceProvider()) {
            return response()->json(['success' => false, 'message' => 'Only service providers can issue prescriptions.'], 403);
        }

        $data = $request->validate([
            'appointment_id' => 'nullable|exists:appointments,id',
            'clinic_name' => 'nullable|string|max:255',
            'clinic_address' => 'nullable|string|max:500',
            'patient_name' => 'required|string|max:255',
            'patient_email' => 'nullable|email|max:255',
            'patient_phone' => 'nullable|string|max:50',
            'patient_dob' => 'nullable|date',
            'patient_age' => 'nullable|integer|min:0|max:150',
            'clinical_information' => 'nullable|string',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.test_name' => 'required|string|max:255',
            'items.*.specimen_type' => 'nullable|string|max:100',
            'items.*.urgency' => 'nullable|in:routine,urgent,stat',
            'items.*.notes' => 'nullable|string',
        ]);

        $rx = DB::transaction(function () use ($user, $data) {
            $rx = LabPrescription::create([
                'prescription_number' => $this->generateNumber('LRX'),
                'doctor_id' => $user->id,
                'appointment_id' => $data['appointment_id'] ?? null,
                'prescriber_name' => $user->name,
                'prescriber_licence_number' => $user->licence_number,
                'prescriber_phone' => $user->telephone,
                'prescriber_email' => $user->email,
                'clinic_name' => $data['clinic_name'] ?? null,
                'clinic_address' => $data['clinic_address'] ?? null,
                'patient_name' => $data['patient_name'],
                'patient_email' => $data['patient_email'] ?? null,
                'patient_phone' => $data['patient_phone'] ?? null,
                'patient_dob' => $data['patient_dob'] ?? null,
                'patient_age' => $data['patient_age'] ?? null,
                'issued_date' => now()->toDateString(),
                'clinical_information' => $data['clinical_information'] ?? null,
                'notes' => $data['notes'] ?? null,
            ]);

            foreach ($data['items'] as $item) {
                LabPrescriptionItem::create(array_merge(
                    $item,
                    ['lab_prescription_id' => $rx->id, 'urgency' => $item['urgency'] ?? 'routine']
                ));
            }

            return $rx->load('items');
        });

        return response()->json(['success' => true, 'data' => $rx], 201);
    }

    public function indexLab(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $query = LabPrescription::with('items')->orderByDesc('issued_date');
        $this->scopeToCurrentUser($query, $user);

        $perPage = (int) $request->input('per_page', 20);
        return response()->json([
            'success' => true,
            'data' => $query->paginate($perPage),
        ]);
    }

    public function showLab(Request $request, $id)
    {
        $user = $request->user();
        $rx = LabPrescription::with('items')->findOrFail($id);
        $this->authorizeView($rx, $user);
        return response()->json(['success' => true, 'data' => $rx]);
    }

    public function pdfLab(Request $request, $id)
    {
        $user = $request->user();
        $rx = LabPrescription::with('items')->findOrFail($id);
        $this->authorizeView($rx, $user);

        $pdf = Pdf::loadView('prescriptions.lab_pdf', [
            'rx' => $rx,
            'logoPath' => $this->logoPath(),
        ]);

        return $pdf->download($this->pdfFilename($rx));
    }

    public function emailLab(Request $request, $id)
    {
        $user = $request->user();
        $rx = LabPrescription::with('items')->findOrFail($id);
        $this->authorizeView($rx, $user);

        $request->validate(['email' => 'nullable|email']);
        $to = $request->input('email') ?: $rx->patient_email;
        if (!$to) {
            return response()->json(['success' => false, 'message' => 'No recipient email provided.'], 422);
        }

        return $this->sendPrescriptionEmail($rx, $to, 'lab');
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    private function scopeToCurrentUser(Builder $query, $user): void
    {
        if ($user->isServiceProvider()) {
            $query->where('doctor_id', $user->id);
        } else {
            $query->where('patient_email', $user->email);
        }
    }

    private function authorizeView($rx, $user): void
    {
        if (!$user) abort(401, 'Unauthenticated.');
        $isOwnerDoctor = $user->isServiceProvider() && $rx->doctor_id === $user->id;
        $isOwnerPatient = $rx->patient_email && strcasecmp($rx->patient_email, $user->email) === 0;
        if (!$isOwnerDoctor && !$isOwnerPatient && !$user->isAdmin()) {
            abort(403, 'You are not allowed to view this prescription.');
        }
    }

    private function generateNumber(string $prefix): string
    {
        return $prefix . '-' . now()->format('Ymd') . '-' . strtoupper(Str::random(6));
    }

    private function logoPath(): string
    {
        return public_path('medisasa-logo.png');
    }

    private function pdfFilename($rx): string
    {
        return $rx->prescription_number . '.pdf';
    }

    private function sendPrescriptionEmail($rx, string $to, string $type)
    {
        $view = $type === 'medication' ? 'prescriptions.medication_pdf' : 'prescriptions.lab_pdf';
        $pdf = Pdf::loadView($view, ['rx' => $rx, 'logoPath' => $this->logoPath()]);
        $pdfBinary = $pdf->output();

        $subject = ($type === 'medication' ? 'Medication Prescription' : 'Lab Order') . ' from ' . ($rx->prescriber_name ?: 'MediSasa');
        $filename = $this->pdfFilename($rx);

        try {
            Mail::send([], [], function ($message) use ($to, $rx, $subject, $pdfBinary, $filename, $type) {
                $message->from('app@justhomesapp.com', 'MediSasa')
                    ->to($to)
                    ->subject($subject);
                $message->text("Hello {$rx->patient_name},\n\n"
                    . "Please find attached your "
                    . ($type === 'medication' ? 'medication prescription' : 'lab order')
                    . " from {$rx->prescriber_name} (issued {$rx->issued_date->format('d M Y')}).\n\n"
                    . "Reference: {$rx->prescription_number}\n\n"
                    . "If you have any questions, contact us at support@medisasa.co.ke or +254 759 000 652.\n\n"
                    . "MediSasa");
                $message->attachData($pdfBinary, $filename, ['mime' => 'application/pdf']);
            });
        } catch (\Throwable $e) {
            Log::error("Failed to send prescription email: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to send email.'], 500);
        }

        return response()->json(['success' => true, 'message' => "Sent to {$to}."]);
    }
}
