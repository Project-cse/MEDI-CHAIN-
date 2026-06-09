import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/patient_booking_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_state_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/healthcare/premium_booking_flow_widgets.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../../widgets/healthcare/premium_patient_form_field.dart';

const _kGenders = ['Male', 'Female', 'Other'];
const _kRelationships = [
  'Father', 'Mother', 'Brother', 'Sister', 'Wife', 'Husband', 'Child', 'Friend', 'Other',
];

/// Patient selection + details — premium booking flow (Screen 1).
class BookingPatientSelectorScreen extends ConsumerStatefulWidget {
  const BookingPatientSelectorScreen({super.key, required this.doctorId, this.preferOnline = false});

  final String doctorId;
  final bool preferOnline;

  @override
  ConsumerState<BookingPatientSelectorScreen> createState() => _BookingPatientSelectorScreenState();
}

class _BookingPatientSelectorScreenState extends ConsumerState<BookingPatientSelectorScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  String _gender = 'Male';
  String _relationship = 'Father';
  bool _showPatientForm = false;

  @override
  void initState() {
    super.initState();
    final mode = widget.preferOnline ? 'online' : 'offline';
    Future.microtask(() => prefetchDoctorSchedule(ref, widget.doctorId, mode: mode));
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    super.dispose();
  }

  String get _bookingPath {
    final q = widget.preferOnline ? '?visit=online' : '';
    return '/booking/${widget.doctorId}$q';
  }

  void _bookForMe() {
    final auth = ref.read(authProvider).user;
    final profile = ref.read(patientProfileProvider).valueOrNull;
    final name = profile?.name ?? auth?.name ?? '';
    if (name.isEmpty) {
      AppSnackbar.show(context, 'Please complete your profile first');
      return;
    }
    String? age;
    final dob = profile?.dob;
    if (dob != null && dob.isNotEmpty) {
      final parsed = DateTime.tryParse(dob);
      if (parsed != null) {
        final now = DateTime.now();
        var years = now.year - parsed.year;
        if (now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) {
          years--;
        }
        age = '$years';
      }
    }
    final patient = PatientBookingInfo.self(
      name: name,
      phone: profile?.phone ?? auth?.phone,
      gender: profile?.gender,
      age: age,
    );
    ref.read(bookingPatientProvider.notifier).state = patient;
    context.push(_bookingPath);
  }

  void _bookForOthers() {
    if (_name.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Please enter patient name');
      return;
    }
    if (_age.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Please enter patient age');
      return;
    }
    final patient = PatientBookingInfo(
      name: _name.text.trim(),
      age: _age.text.trim(),
      gender: _gender,
      phone: _phone.text.trim(),
      relationship: _relationship,
      isSelf: false,
    );
    ref.read(bookingPatientProvider.notifier).state = patient;
    context.push(_bookingPath);
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));
    final doctorName = doctorAsync.valueOrNull?.name ?? 'Doctor';

    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              PremiumBookingHeroHeader(
                doctorName: doctorName,
                onClose: () => context.pop(),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          Positioned(
            top: 130 + MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: PremiumHealthcareTheme.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(PremiumHealthcareTheme.sheetTopRadius)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: doctorAsync.isLoading
                  ? const Center(child: AppLoader())
                  : _showPatientForm
                      ? _PatientDetailsForm(
                          name: _name,
                          age: _age,
                          phone: _phone,
                          gender: _gender,
                          relationship: _relationship,
                          onGenderChanged: (v) => setState(() => _gender = v),
                          onRelationshipChanged: (v) => setState(() => _relationship = v),
                          onBack: () => setState(() => _showPatientForm = false),
                          onContinue: _bookForOthers,
                        )
                      : _WhoIsItFor(
                          onMyself: _bookForMe,
                          onSomeoneElse: () => setState(() => _showPatientForm = true),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhoIsItFor extends StatelessWidget {
  const _WhoIsItFor({required this.onMyself, required this.onSomeoneElse});

  final VoidCallback onMyself;
  final VoidCallback onSomeoneElse;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        PremiumHealthcareTheme.horizontalPadding,
        28,
        PremiumHealthcareTheme.horizontalPadding,
        32,
      ),
      child: Column(
        children: [
          const PremiumSectionTitleRow(
            title: 'Who is this for?',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 8),
          Text(
            'Select an option to continue booking',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: PremiumHealthcareTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          PremiumWhoOptionCard(
            icon: Icons.person_rounded,
            title: 'Book for Myself',
            subtitle: 'Use my profile details',
            accentColor: PremiumHealthcareTheme.primaryBlue,
            onTap: onMyself,
          ),
          const SizedBox(height: 14),
          PremiumWhoOptionCard(
            icon: Icons.people_outline_rounded,
            title: 'Book for Someone Else',
            subtitle: 'Enter patient details',
            accentColor: PremiumHealthcareTheme.secondaryBlue,
            onTap: onSomeoneElse,
          ),
        ],
      ),
    );
  }
}

class _PatientDetailsForm extends StatelessWidget {
  const _PatientDetailsForm({
    required this.name,
    required this.age,
    required this.phone,
    required this.gender,
    required this.relationship,
    required this.onGenderChanged,
    required this.onRelationshipChanged,
    required this.onBack,
    required this.onContinue,
  });

  final TextEditingController name;
  final TextEditingController age;
  final TextEditingController phone;
  final String gender;
  final String relationship;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onRelationshipChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              PremiumHealthcareTheme.horizontalPadding,
              24,
              PremiumHealthcareTheme.horizontalPadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumFlowBackButton(onTap: onBack),
                const SizedBox(height: 20),
                const PremiumSectionTitleRow(
                  title: 'Patient Details',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 28),
                PremiumPatientFormField(
                  label: 'Patient Name',
                  controller: name,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                PremiumPatientFormField(
                  label: 'Age',
                  controller: age,
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                PremiumPatientDropdownField(
                  label: 'Gender',
                  value: gender,
                  items: _kGenders,
                  icon: Icons.wc_outlined,
                  onChanged: onGenderChanged,
                ),
                const SizedBox(height: 20),
                PremiumPatientFormField(
                  label: 'Contact Number',
                  controller: phone,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                PremiumPatientDropdownField(
                  label: 'Relationship',
                  value: relationship,
                  items: _kRelationships,
                  icon: Icons.family_restroom_outlined,
                  onChanged: onRelationshipChanged,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PremiumHealthcareTheme.horizontalPadding,
            8,
            PremiumHealthcareTheme.horizontalPadding,
            24,
          ),
          child: PremiumContinueButton(label: 'Continue', onPressed: onContinue),
        ),
      ],
    );
  }
}
