class MedicationItem {
  final int? id;
  final String drugName;
  final String? dosageForm;
  final String? strength;
  final String? frequency;
  final String? route;
  final String? duration;
  final String? quantity;
  final int refills;
  final String? instructions;

  MedicationItem({
    this.id,
    required this.drugName,
    this.dosageForm,
    this.strength,
    this.frequency,
    this.route,
    this.duration,
    this.quantity,
    this.refills = 0,
    this.instructions,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> j) => MedicationItem(
        id: j['id'],
        drugName: j['drug_name'] ?? '',
        dosageForm: j['dosage_form'],
        strength: j['strength'],
        frequency: j['frequency'],
        route: j['route'],
        duration: j['duration'],
        quantity: j['quantity'],
        refills: (j['refills'] is int) ? j['refills'] : int.tryParse('${j['refills']}') ?? 0,
        instructions: j['instructions'],
      );

  Map<String, dynamic> toJson() => {
        'drug_name': drugName,
        if (dosageForm != null) 'dosage_form': dosageForm,
        if (strength != null) 'strength': strength,
        if (frequency != null) 'frequency': frequency,
        if (route != null) 'route': route,
        if (duration != null) 'duration': duration,
        if (quantity != null) 'quantity': quantity,
        'refills': refills,
        if (instructions != null) 'instructions': instructions,
      };
}

class MedicationPrescription {
  final int id;
  final String prescriptionNumber;
  final String prescriberName;
  final String? prescriberLicenceNumber;
  final String? prescriberPhone;
  final String? prescriberEmail;
  final String? clinicName;
  final String? clinicAddress;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? patientDob;
  final int? patientAge;
  final String issuedDate;
  final String? diagnosis;
  final String? notes;
  final List<MedicationItem> items;

  MedicationPrescription({
    required this.id,
    required this.prescriptionNumber,
    required this.prescriberName,
    this.prescriberLicenceNumber,
    this.prescriberPhone,
    this.prescriberEmail,
    this.clinicName,
    this.clinicAddress,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.patientDob,
    this.patientAge,
    required this.issuedDate,
    this.diagnosis,
    this.notes,
    required this.items,
  });

  factory MedicationPrescription.fromJson(Map<String, dynamic> j) => MedicationPrescription(
        id: j['id'],
        prescriptionNumber: j['prescription_number'] ?? '',
        prescriberName: j['prescriber_name'] ?? '',
        prescriberLicenceNumber: j['prescriber_licence_number'],
        prescriberPhone: j['prescriber_phone'],
        prescriberEmail: j['prescriber_email'],
        clinicName: j['clinic_name'],
        clinicAddress: j['clinic_address'],
        patientName: j['patient_name'] ?? '',
        patientEmail: j['patient_email'],
        patientPhone: j['patient_phone'],
        patientDob: j['patient_dob']?.toString(),
        patientAge: j['patient_age'] is int ? j['patient_age'] : int.tryParse('${j['patient_age'] ?? ''}'),
        issuedDate: j['issued_date']?.toString() ?? '',
        diagnosis: j['diagnosis'],
        notes: j['notes'],
        items: (j['items'] as List? ?? []).map((e) => MedicationItem.fromJson(e)).toList(),
      );
}

class LabItem {
  final int? id;
  final String testName;
  final String? specimenType;
  final String urgency; // routine | urgent | stat
  final String? notes;

  LabItem({
    this.id,
    required this.testName,
    this.specimenType,
    this.urgency = 'routine',
    this.notes,
  });

  factory LabItem.fromJson(Map<String, dynamic> j) => LabItem(
        id: j['id'],
        testName: j['test_name'] ?? '',
        specimenType: j['specimen_type'],
        urgency: j['urgency'] ?? 'routine',
        notes: j['notes'],
      );

  Map<String, dynamic> toJson() => {
        'test_name': testName,
        if (specimenType != null) 'specimen_type': specimenType,
        'urgency': urgency,
        if (notes != null) 'notes': notes,
      };
}

class LabPrescription {
  final int id;
  final String prescriptionNumber;
  final String prescriberName;
  final String? prescriberLicenceNumber;
  final String? prescriberPhone;
  final String? prescriberEmail;
  final String? clinicName;
  final String? clinicAddress;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? patientDob;
  final int? patientAge;
  final String issuedDate;
  final String? clinicalInformation;
  final String? notes;
  final List<LabItem> items;

  LabPrescription({
    required this.id,
    required this.prescriptionNumber,
    required this.prescriberName,
    this.prescriberLicenceNumber,
    this.prescriberPhone,
    this.prescriberEmail,
    this.clinicName,
    this.clinicAddress,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.patientDob,
    this.patientAge,
    required this.issuedDate,
    this.clinicalInformation,
    this.notes,
    required this.items,
  });

  factory LabPrescription.fromJson(Map<String, dynamic> j) => LabPrescription(
        id: j['id'],
        prescriptionNumber: j['prescription_number'] ?? '',
        prescriberName: j['prescriber_name'] ?? '',
        prescriberLicenceNumber: j['prescriber_licence_number'],
        prescriberPhone: j['prescriber_phone'],
        prescriberEmail: j['prescriber_email'],
        clinicName: j['clinic_name'],
        clinicAddress: j['clinic_address'],
        patientName: j['patient_name'] ?? '',
        patientEmail: j['patient_email'],
        patientPhone: j['patient_phone'],
        patientDob: j['patient_dob']?.toString(),
        patientAge: j['patient_age'] is int ? j['patient_age'] : int.tryParse('${j['patient_age'] ?? ''}'),
        issuedDate: j['issued_date']?.toString() ?? '',
        clinicalInformation: j['clinical_information'],
        notes: j['notes'],
        items: (j['items'] as List? ?? []).map((e) => LabItem.fromJson(e)).toList(),
      );
}

class RadiologyItem {
  final int? id;
  final String studyName;
  final String? modality;
  final String? bodyPart;
  final String? side;
  final String contrast; // none | with | without | oral
  final String urgency;  // routine | urgent | stat
  final String? clinicalIndication;
  final String? notes;

  RadiologyItem({
    this.id,
    required this.studyName,
    this.modality,
    this.bodyPart,
    this.side,
    this.contrast = 'none',
    this.urgency = 'routine',
    this.clinicalIndication,
    this.notes,
  });

  factory RadiologyItem.fromJson(Map<String, dynamic> j) => RadiologyItem(
        id: j['id'],
        studyName: j['study_name'] ?? '',
        modality: j['modality'],
        bodyPart: j['body_part'],
        side: j['side'],
        contrast: j['contrast'] ?? 'none',
        urgency: j['urgency'] ?? 'routine',
        clinicalIndication: j['clinical_indication'],
        notes: j['notes'],
      );

  Map<String, dynamic> toJson() => {
        'study_name': studyName,
        if (modality != null) 'modality': modality,
        if (bodyPart != null) 'body_part': bodyPart,
        if (side != null) 'side': side,
        'contrast': contrast,
        'urgency': urgency,
        if (clinicalIndication != null) 'clinical_indication': clinicalIndication,
        if (notes != null) 'notes': notes,
      };
}

class RadiologyPrescription {
  final int id;
  final String prescriptionNumber;
  final String prescriberName;
  final String? prescriberLicenceNumber;
  final String? prescriberPhone;
  final String? prescriberEmail;
  final String? clinicName;
  final String? clinicAddress;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final String? patientDob;
  final int? patientAge;
  final String? patientSex; // male | female | other
  final String issuedDate;
  final String? clinicalInformation;
  final String? notes;
  final List<RadiologyItem> items;

  RadiologyPrescription({
    required this.id,
    required this.prescriptionNumber,
    required this.prescriberName,
    this.prescriberLicenceNumber,
    this.prescriberPhone,
    this.prescriberEmail,
    this.clinicName,
    this.clinicAddress,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.patientDob,
    this.patientAge,
    this.patientSex,
    required this.issuedDate,
    this.clinicalInformation,
    this.notes,
    required this.items,
  });

  factory RadiologyPrescription.fromJson(Map<String, dynamic> j) => RadiologyPrescription(
        id: j['id'],
        prescriptionNumber: j['prescription_number'] ?? '',
        prescriberName: j['prescriber_name'] ?? '',
        prescriberLicenceNumber: j['prescriber_licence_number'],
        prescriberPhone: j['prescriber_phone'],
        prescriberEmail: j['prescriber_email'],
        clinicName: j['clinic_name'],
        clinicAddress: j['clinic_address'],
        patientName: j['patient_name'] ?? '',
        patientEmail: j['patient_email'],
        patientPhone: j['patient_phone'],
        patientDob: j['patient_dob']?.toString(),
        patientAge: j['patient_age'] is int ? j['patient_age'] : int.tryParse('${j['patient_age'] ?? ''}'),
        patientSex: j['patient_sex'],
        issuedDate: j['issued_date']?.toString() ?? '',
        clinicalInformation: j['clinical_information'],
        notes: j['notes'],
        items: (j['items'] as List? ?? []).map((e) => RadiologyItem.fromJson(e)).toList(),
      );
}
