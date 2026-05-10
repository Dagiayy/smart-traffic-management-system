import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_format.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../tickets/data/ticket_data.dart';
import '../../dashboard/data/dashboard_data.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});
  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  int _step = 0;
  static const _totalSteps = 5;
  final _pageController = PageController();
  bool _submitting = false;

  final _plateCtrl      = TextEditingController();
  final _vehicleTypeCtrl= TextEditingController();
  final _colorCtrl      = TextEditingController();
  final _regCtrl        = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _licenseCtrl    = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _contactCtrl    = TextEditingController();
  final _notesCtrl      = TextEditingController();
  final _roadCtrl       = TextEditingController();

  final _vehicleFormKey    = GlobalKey<FormState>();
  final _driverFormKey     = GlobalKey<FormState>();
  final _violationFormKey  = GlobalKey<FormState>();
  final _locationFormKey   = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [_plateCtrl, _vehicleTypeCtrl, _colorCtrl, _regCtrl,
      _driverNameCtrl, _licenseCtrl, _nationalIdCtrl, _contactCtrl,
      _notesCtrl, _roadCtrl]) { c.dispose(); }
    super.dispose();
  }

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    }
  }

  bool _validateCurrent() {
    final keys = [_vehicleFormKey, _driverFormKey, _violationFormKey, _locationFormKey];
    if (_step < keys.length) return keys[_step].currentState?.validate() ?? true;
    return true;
  }

  Future<void> _submit({bool asDraft = false}) async {
    final draft = ref.read(ticketDraftProvider);
    setState(() => _submitting = true);
    try {
      final repo = ref.read(ticketsRepositoryProvider);
      FieldTicket? ticket;

      // Try to create ticket on backend
      try {
        ticket = await repo.createTicket(draft);
      } catch (_) {
        // Truly offline — save to local queue and exit
        await AppStorage.instance.addToOfflineQueue(draft.toOfflineJson());
        ref.read(offlineQueueProvider.notifier).state = AppStorage.instance.getOfflineQueue();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved offline. Will sync when connected.')));
          context.pop();
        }
        return;
      }

      // Ticket created on backend — now optionally submit it
      if (!asDraft) {
        try {
          await repo.submitTicket(ticket.id);
        } catch (_) {
          // Ticket exists as DRAFT on server — navigate there so officer can submit manually
        }
      }

      ref.invalidate(ticketsListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.read(ticketDraftProvider.notifier).state = TicketDraft();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(asDraft ? 'Saved as draft' : 'Ticket submitted successfully')));
        context.go('/tickets/${ticket.id}');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static const _stepTitles = ['Vehicle Info', 'Driver Info', 'Violation', 'Location & Evidence', 'Review'];
  static const _stepIcons  = [
    Icons.directions_car_outlined, Icons.person_outline, Icons.gavel_outlined,
    Icons.location_on_outlined, Icons.fact_check_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_stepTitles[_step]),
        leading: _step == 0
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop())
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep),
        actions: [
          TextButton(
            onPressed: () => _submit(asDraft: true),
            child: Text('Save Draft', style: AppTypography.button.copyWith(color: AppColors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _step, totalSteps: _totalSteps,
              stepTitles: _stepTitles, stepIcons: _stepIcons),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _VehicleStep(formKey: _vehicleFormKey, plateCtrl: _plateCtrl,
                    typeCtrl: _vehicleTypeCtrl, colorCtrl: _colorCtrl, regCtrl: _regCtrl),
                _DriverStep(formKey: _driverFormKey, nameCtrl: _driverNameCtrl,
                    licenseCtrl: _licenseCtrl, nationalIdCtrl: _nationalIdCtrl, contactCtrl: _contactCtrl),
                _ViolationStep(formKey: _violationFormKey, notesCtrl: _notesCtrl),
                _LocationEvidenceStep(formKey: _locationFormKey, roadCtrl: _roadCtrl),
                _ReviewStep(
                  plateCtrl: _plateCtrl, driverNameCtrl: _driverNameCtrl,
                  notesCtrl: _notesCtrl, submitting: _submitting, onSubmit: () => _submit(),
                ),
              ],
            ),
          ),

          // Bottom navigation
          if (_step < _totalSteps - 1)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: AppButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: () {
                  if (_validateCurrent()) _nextStep();
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps, required this.stepTitles, required this.stepIcons});
  final int currentStep, totalSteps;
  final List<String> stepTitles;
  final List<IconData> stepIcons;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        children: [
          // Progress bar
          Row(children: List.generate(totalSteps, (i) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 3 : 0),
              decoration: BoxDecoration(
                color: i <= currentStep ? AppColors.primary : AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ))),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (i) => Column(
              children: [
                Icon(stepIcons[i], size: 16,
                    color: i == currentStep ? AppColors.primary : i < currentStep ? AppColors.success : AppColors.gray400),
                Text('${i + 1}', style: AppTypography.caption.copyWith(
                    color: i == currentStep ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: i == currentStep ? FontWeight.w700 : FontWeight.w400)),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Vehicle Information ───────────────────────────────────────────
class _VehicleStep extends ConsumerWidget {
  const _VehicleStep({required this.formKey, required this.plateCtrl, required this.typeCtrl, required this.colorCtrl, required this.regCtrl});
  final GlobalKey<FormState> formKey;
  final TextEditingController plateCtrl, typeCtrl, colorCtrl, regCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          AppTextField(
            controller: plateCtrl,
            label: 'License Plate Number *',
            hint: 'e.g. AA-12345',
            prefixIcon: Icons.confirmation_number_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a valid plate number' : null,
            onChanged: (v) {
              ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(plateNumber: v.trim().toUpperCase()));
            },
            suffix: IconButton(
              icon: const Icon(Icons.search, color: AppColors.primary),
              onPressed: () => _lookupPlate(context, ref, plateCtrl.text.trim()),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Tap 🔍 to auto-fetch vehicle info from the database',
              style: AppTypography.caption),

          // Lookup result card
          Consumer(builder: (ctx, ref, _) {
            final lookup = ref.watch(ticketDraftProvider).lookupResult;
            if (lookup == null) return const SizedBox(height: AppSpacing.md);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: AppCard(
                color: AppColors.primarySurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.verified_outlined, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text('Vehicle Found', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                    ]),
                    const Divider(height: AppSpacing.md),
                    if (lookup.ownerName != null) _InfoRow('Owner', lookup.ownerName!),
                    if (lookup.vehicleType != null) _InfoRow('Type', lookup.vehicleType!),
                    if (lookup.vehicleMake != null) _InfoRow('Make/Model', '${lookup.vehicleMake} ${lookup.vehicleModel ?? ''}'),
                    if (lookup.violationHistoryCount > 0)
                      _InfoRow('Prior Violations', '${lookup.violationHistoryCount}',
                          valueColor: lookup.violationHistoryCount > 3 ? AppColors.danger : AppColors.textPrimary),
                    if (lookup.outstandingFines > 0)
                      _InfoRow('Outstanding Fines', AppFormat.currency(lookup.outstandingFines), valueColor: AppColors.danger),
                  ],
                ),
              ),
            );
          }),

          AppTextField(
            controller: typeCtrl,
            label: 'Vehicle Type',
            hint: 'Car / Motorcycle / Truck / Bus',
            prefixIcon: Icons.directions_car_outlined,
            textInputAction: TextInputAction.next,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(vehicleType: v)),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: colorCtrl,
            label: 'Vehicle Color',
            hint: 'e.g. White, Black, Red',
            prefixIcon: Icons.palette_outlined,
            textInputAction: TextInputAction.next,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(vehicleColor: v)),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: regCtrl,
            label: 'Registration Number (optional)',
            hint: 'Vehicle registration document number',
            prefixIcon: Icons.article_outlined,
            textInputAction: TextInputAction.done,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(registrationNumber: v)),
          ),
        ],
      ),
    );
  }

  Future<void> _lookupPlate(BuildContext context, WidgetRef ref, String plate) async {
    if (plate.isEmpty) return;
    try {
      final result = await ref.read(ticketsRepositoryProvider).plateLookup(plate);
      ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(lookupResult: result));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plate not found: $e')));
      }
    }
  }
}

// ── Step 2: Driver Information ────────────────────────────────────────────
class _DriverStep extends ConsumerWidget {
  const _DriverStep({required this.formKey, required this.nameCtrl, required this.licenseCtrl, required this.nationalIdCtrl, required this.contactCtrl});
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, licenseCtrl, nationalIdCtrl, contactCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          AppTextField(
            controller: nameCtrl, label: 'Driver Full Name',
            hint: 'As shown on license', prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(driverName: v)),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: licenseCtrl, label: 'Driver License Number',
            hint: 'Enter license ID', prefixIcon: Icons.card_membership_outlined,
            textInputAction: TextInputAction.next,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(driverLicense: v)),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: nationalIdCtrl, label: 'National ID (optional)',
            hint: 'National ID number', prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(nationalId: v)),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: contactCtrl, label: 'Contact Number (optional)',
            hint: 'Driver phone number', prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(contactNumber: v)),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Violation Details ─────────────────────────────────────────────
class _ViolationStep extends ConsumerStatefulWidget {
  const _ViolationStep({required this.formKey, required this.notesCtrl});
  final GlobalKey<FormState> formKey;
  final TextEditingController notesCtrl;

  @override
  ConsumerState<_ViolationStep> createState() => _ViolationStepState();
}

class _ViolationStepState extends ConsumerState<_ViolationStep> {
  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(ticketDraftProvider);
    final typesAsync = ref.watch(violationTypesProvider);

    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text('Violation Type *', style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          typesAsync.when(
            loading: () => const SkeletonBox(height: 52),
            error: (e, _) => Text('Could not load violation types: $e', style: AppTypography.bodySmall),
            data: (types) => DropdownButtonFormField<ViolationType>(
              value: draft.selectedViolationType,
              hint: const Text('Select violation type'),
              items: types.map((t) => DropdownMenuItem(
                value: t,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.name, style: AppTypography.bodyMedium),
                    Text(t.code, style: AppTypography.caption),
                  ],
                ),
              )).toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(
                    violationTypeId: v.id,
                    violationTypeName: v.name,
                    legalCode: v.legalReference,
                    estimatedFine: v.defaultFine,
                    severity: v.defaultSeverity,
                    selectedViolationType: v,
                  ));
                }
              },
              validator: (v) => v == null ? 'Select a violation type' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Severity Level *', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: ['MINOR', 'MAJOR', 'CRITICAL'].map((s) {
              final color = switch (s) {
                'CRITICAL' => AppColors.danger, 'MAJOR' => AppColors.warning, _ => AppColors.info,
              };
              final selected = draft.severity == s;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: s != 'CRITICAL' ? 8 : 0),
                  child: InkWell(
                    borderRadius: AppRadius.radiusMd,
                    onTap: () => ref.read(ticketDraftProvider.notifier).update((d) => d.copyWith(severity: s)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? color.withValues(alpha: 0.15) : AppColors.surface,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
                      ),
                      child: Column(
                        children: [
                          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: selected ? color : AppColors.gray400),
                          const SizedBox(height: 4),
                          Text(s[0] + s.substring(1).toLowerCase(),
                              style: AppTypography.labelSmall.copyWith(color: selected ? color : AppColors.textSecondary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (draft.estimatedFine != null && draft.estimatedFine! > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              color: AppColors.warningSurface,
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_outlined, color: AppColors.warning, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text('Estimated Fine: ', style: AppTypography.labelMedium.copyWith(color: AppColors.warningText)),
                Text(AppFormat.currency(draft.estimatedFine!),
                    style: AppTypography.numeric(16, FontWeight.w700, color: AppColors.warning)),
              ]),
            ),
          ],
          if (draft.legalCode != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              color: AppColors.infoSurface,
              child: Row(children: [
                const Icon(Icons.book_outlined, color: AppColors.info, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text('Legal Ref: ${draft.legalCode}', style: AppTypography.labelSmall.copyWith(color: AppColors.infoText)),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: widget.notesCtrl,
            label: 'Officer Notes',
            hint: 'Additional incident details, context, observations...',
            prefixIcon: Icons.notes_outlined,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(notes: v)),
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Location & Evidence ───────────────────────────────────────────
class _LocationEvidenceStep extends ConsumerStatefulWidget {
  const _LocationEvidenceStep({required this.formKey, required this.roadCtrl});
  final GlobalKey<FormState> formKey;
  final TextEditingController roadCtrl;
  @override
  ConsumerState<_LocationEvidenceStep> createState() => _LocationEvidenceState();
}

class _LocationEvidenceState extends ConsumerState<_LocationEvidenceStep> {
  bool _gettingLocation = false;
  final _picker = ImagePicker();

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition();
      ref.read(ticketDraftProvider.notifier).update((s) =>
          s.copyWith(locationLat: pos.latitude, locationLng: pos.longitude));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
    } finally { if (mounted) setState(() => _gettingLocation = false); }
  }

  Future<void> _addPhoto() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isEmpty) return;
    final files = imgs.map((x) => File(x.path)).toList();
    ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(
        evidenceFiles: [...s.evidenceFiles, ...files]));
  }

  Future<void> _takePhoto() async {
    final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (img == null) return;
    ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(
        evidenceFiles: [...s.evidenceFiles, File(img.path)]));
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(ticketDraftProvider);
    final intersectionsAsync = ref.watch(intersectionsProvider);

    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // GPS
          Text('Location', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: draft.locationLat != null
                          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('GPS Detected', style: AppTypography.labelMedium.copyWith(color: AppColors.success)),
                              Text('${draft.locationLat!.toStringAsFixed(5)}, ${draft.locationLng!.toStringAsFixed(5)}',
                                  style: AppTypography.bodySmall),
                            ])
                          : Text('GPS not set', style: AppTypography.bodySmall),
                    ),
                    AppButton(
                      label: _gettingLocation ? 'Getting...' : 'Auto-Detect',
                      icon: Icons.gps_fixed_outlined,
                      variant: AppButtonVariant.secondary,
                      fullWidth: false,
                      compact: true,
                      loading: _gettingLocation,
                      onPressed: _gettingLocation ? null : _getLocation,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Intersection
          Text('Intersection', style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          intersectionsAsync.when(
            loading: () => const SkeletonBox(height: 52),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) => DropdownButtonFormField<Intersection>(
              hint: const Text('Select intersection'),
              value: draft.intersectionId != null
                  ? list.cast<Intersection?>().firstWhere((i) => i?.id == draft.intersectionId, orElse: () => null)
                  : null,
              items: list.map((i) => DropdownMenuItem(value: i, child: Text(i.name))).toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(
                      intersectionId: v.id, intersectionName: v.name, locationLat: v.lat, locationLng: v.lng));
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: widget.roadCtrl,
            label: 'Road Name',
            hint: 'e.g. Bole Road, Ring Road',
            prefixIcon: Icons.near_me_outlined,
            onChanged: (v) => ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(roadName: v)),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Evidence
          Text('Evidence', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.xs),
          Text('Captured photos are timestamped and geotagged automatically.',
              style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Take Photo',
                  icon: Icons.camera_alt_outlined,
                  variant: AppButtonVariant.primary,
                  onPressed: _takePhoto,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'From Gallery',
                  icon: Icons.photo_library_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _addPhoto,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (draft.evidenceFiles.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: draft.evidenceFiles.length,
              itemBuilder: (ctx, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(draft.evidenceFiles[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  ),
                  Positioned(top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () {
                        final files = [...draft.evidenceFiles]..removeAt(i);
                        ref.read(ticketDraftProvider.notifier).update((s) => s.copyWith(evidenceFiles: files));
                      },
                      child: Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Step 5: Review & Submit ───────────────────────────────────────────────
class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.plateCtrl, required this.driverNameCtrl, required this.notesCtrl, required this.submitting, required this.onSubmit});
  final TextEditingController plateCtrl, driverNameCtrl, notesCtrl;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(ticketDraftProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text('Review & Submit', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.xs),
        Text('Verify all details before submitting. Submitted tickets are forwarded for supervisor review.',
            style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.lg),

        _ReviewSection('Vehicle', [
          ('Plate Number', draft.plateNumber),
          if (draft.vehicleType != null) ('Type', draft.vehicleType!),
          if (draft.vehicleColor != null) ('Color', draft.vehicleColor!),
          if (draft.lookupResult?.ownerName != null) ('Owner', draft.lookupResult!.ownerName!),
        ]),
        const SizedBox(height: AppSpacing.md),

        _ReviewSection('Driver', [
          if (draft.driverName != null) ('Name', draft.driverName!),
          if (draft.driverLicense != null) ('License', draft.driverLicense!),
        ]),
        const SizedBox(height: AppSpacing.md),

        _ReviewSection('Violation', [
          if (draft.violationTypeName != null) ('Type', draft.violationTypeName!),
          ('Severity', draft.severity),
          if (draft.legalCode != null) ('Legal Code', draft.legalCode!),
          if (draft.estimatedFine != null) ('Estimated Fine', AppFormat.currency(draft.estimatedFine!)),
        ]),
        const SizedBox(height: AppSpacing.md),

        _ReviewSection('Location', [
          if (draft.intersectionName != null) ('Intersection', draft.intersectionName!),
          if (draft.roadName != null) ('Road', draft.roadName!),
          if (draft.locationLat != null) ('GPS', '${draft.locationLat!.toStringAsFixed(4)}, ${draft.locationLng!.toStringAsFixed(4)}'),
        ]),
        if (draft.evidenceFiles.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(children: [
              const Icon(Icons.photo_library_outlined, color: AppColors.success, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('${draft.evidenceFiles.length} evidence photo${draft.evidenceFiles.length == 1 ? '' : 's'} attached',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.success)),
            ]),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Submit Ticket',
          icon: Icons.send_outlined,
          variant: AppButtonVariant.success,
          loading: submitting,
          onPressed: submitting ? null : onSubmit,
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection(this.title, this.rows);
  final String title;
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          const Divider(height: AppSpacing.md),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 110, child: Text(r.$1, style: AppTypography.labelSmall)),
              Expanded(child: Text(r.$2, style: AppTypography.bodyMedium)),
            ]),
          )),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueColor});
  final String label, value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: AppTypography.labelSmall)),
        Expanded(child: Text(value, style: AppTypography.bodyMedium.copyWith(color: valueColor))),
      ]),
    );
  }
}
