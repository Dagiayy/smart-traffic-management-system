"""
scripts/seed_data.py

Run with: python manage.py shell < scripts/seed_data.py
Or as management command: python manage.py seed_data

Seeds the database with:
- Admin, developer, supervisor, officer, and citizen users
- Intersections (Addis Ababa)
- Violation types with fine rules
- Sample violations and fines
"""
import os
import django
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'itms_backend.settings')
django.setup()

from django.utils import timezone
from datetime import timedelta
from decimal import Decimal

from accounts.models import CustomUser, UserProfile
from vehicles.models import Vehicle, DriverLicense
from intersections.models import Intersection, Lane, TrafficCamera, SignalState
from violations.models import ViolationType, Violation, ViolationEvidence
from fines.models import FineRule, Fine
from ai_brain.models import AISession, RLEpisode, AIAlert, CongestedZone


def run():
    print('🌱 Seeding ITMS database...')

    # ── Users ─────────────────────────────────────────────────────────────
    print('Creating users...')
    admin, _ = CustomUser.objects.get_or_create(
        username='admin',
        defaults={
            'full_name': 'System Administrator', 'email': 'admin@itms.gov.et',
            'role': 'ADMIN', 'is_staff': True, 'is_superuser': True,
        }
    )
    admin.set_password('admin123')
    admin.save()
    UserProfile.objects.get_or_create(user=admin)

    dev, _ = CustomUser.objects.get_or_create(
        username='developer',
        defaults={'full_name': 'AI Developer', 'email': 'dev@itms.gov.et', 'role': 'DEVELOPER'}
    )
    dev.set_password('dev123')
    dev.save()
    UserProfile.objects.get_or_create(user=dev)

    supervisor, _ = CustomUser.objects.get_or_create(
        username='supervisor01',
        defaults={
            'full_name': 'Supervisor Abebe', 'email': 'supervisor@itms.gov.et',
            'role': 'SUPERVISOR', 'badge_number': 'SUP-001',
        }
    )
    supervisor.set_password('super123')
    supervisor.save()
    UserProfile.objects.get_or_create(user=supervisor, defaults={'assigned_zone': 'Bole District'})

    officer, _ = CustomUser.objects.get_or_create(
        username='officer01',
        defaults={
            'full_name': 'Officer Kiros', 'phone_number': '+251911000001',
            'role': 'OFFICER', 'badge_number': 'OFF-001',
        }
    )
    officer.set_password('officer123')
    officer.save()
    UserProfile.objects.get_or_create(user=officer, defaults={'assigned_zone': 'Bole Sub-City', 'supervisor': supervisor})

    citizen, _ = CustomUser.objects.get_or_create(
        username='citizen01',
        defaults={
            'full_name': 'Tigist Haile', 'email': 'citizen@example.com',
            'phone_number': '+251911000010', 'role': 'CITIZEN',
        }
    )
    citizen.set_password('citizen123')
    citizen.save()
    UserProfile.objects.get_or_create(user=citizen)

    # ── Vehicles ───────────────────────────────────────────────────────────
    print('Creating vehicles...')
    v1, _ = Vehicle.objects.get_or_create(
        plate_number='AA-12345',
        defaults={'owner': citizen, 'vehicle_type': 'CAR', 'make': 'Toyota', 'model': 'Corolla', 'color': 'White', 'year': 2020}
    )
    v2, _ = Vehicle.objects.get_or_create(
        plate_number='AA-67890',
        defaults={'vehicle_type': 'CAR', 'make': 'Hyundai', 'model': 'Sonata', 'color': 'Black', 'year': 2019}
    )

    # ── Intersections ──────────────────────────────────────────────────────
    print('Creating intersections...')
    intersections_data = [
        ('Mexico Square', 9.0227, 38.7468, 'MEXICO-1'),
        ('Bole Medhanialem', 8.9961, 38.7871, 'BOLE-1'),
        ('Piassa', 9.0335, 38.7536, 'PIASSA-1'),
        ('Megenagna', 9.0196, 38.8029, 'MEGEN-1'),
        ('Sarbet', 8.9897, 38.7611, 'SARBET-1'),
        ('Gotera', 9.0048, 38.7434, 'GOTERA-1'),
        ('Lideta', 9.0169, 38.7286, 'LIDETA-1'),
        ('CMC', 9.0444, 38.8145, 'CMC-1'),
    ]
    intersection_objs = []
    for name, lat, lng, sumo_id in intersections_data:
        intr, _ = Intersection.objects.get_or_create(
            sumo_node_id=sumo_id,
            defaults={'name': name, 'latitude': lat, 'longitude': lng, 'zone': 'Addis Ababa'}
        )
        intersection_objs.append(intr)
        # Add signal state
        SignalState.objects.get_or_create(
            intersection=intr,
            defaults={'phase': 'NS_GREEN', 'green_duration': 30, 'source': 'FIXED_TIMER'}
        )
        # Add camera
        TrafficCamera.objects.get_or_create(
            camera_code=f'CAM-{sumo_id}',
            defaults={'intersection': intr, 'direction': 'NORTH', 'is_active': True}
        )

    # ── Violation Types ────────────────────────────────────────────────────
    print('Creating violation types and fine rules...')
    vtypes_data = [
        ('RED_LIGHT', 'Red Light Violation', 'CRITICAL', 'Art. 45 TLC'),
        ('SPEEDING', 'Speeding', 'MAJOR', 'Art. 38 TLC'),
        ('WRONG_LANE', 'Wrong Lane Usage', 'MINOR', 'Art. 29 TLC'),
        ('NO_SEATBELT', 'No Seatbelt', 'MINOR', 'Art. 52 TLC'),
        ('PHONE_DRIVING', 'Phone While Driving', 'MAJOR', 'Art. 55 TLC'),
        ('ILLEGAL_PARKING', 'Illegal Parking', 'MINOR', 'Art. 31 TLC'),
        ('DANGEROUS_DRIVING', 'Dangerous Driving', 'CRITICAL', 'Art. 67 TLC'),
        ('NO_INSURANCE', 'No Insurance', 'MAJOR', 'Art. 12 Insurance Act'),
        ('ILLEGAL_TURN', 'Illegal Turn', 'MINOR', 'Art. 33 TLC'),
        ('OVERLOADING', 'Overloading', 'MAJOR', 'Art. 44 TLC'),
    ]
    fine_amounts = {'MINOR': {'MINOR': 200, 'MAJOR': 300, 'CRITICAL': 500},
                    'MAJOR': {'MINOR': 500, 'MAJOR': 750, 'CRITICAL': 1000},
                    'CRITICAL': {'MINOR': 1000, 'MAJOR': 1500, 'CRITICAL': 2000}}

    vtype_objs = []
    for code, name, default_sev, legal_ref in vtypes_data:
        vt, _ = ViolationType.objects.get_or_create(
            code=code,
            defaults={'name': name, 'default_severity': default_sev, 'legal_reference': legal_ref}
        )
        vtype_objs.append(vt)
        for severity in ['MINOR', 'MAJOR', 'CRITICAL']:
            amount = fine_amounts[default_sev][severity]
            FineRule.objects.get_or_create(
                violation_type=vt, severity=severity,
                defaults={'amount': Decimal(str(amount)), 'is_active': True}
            )

    # ── Sample Violations ──────────────────────────────────────────────────
    print('Creating sample violations...')
    for i, (vt, intr) in enumerate(zip(vtype_objs[:5], intersection_objs[:5])):
        v = Violation.objects.create(
            violation_type=vt,
            vehicle=v1,
            intersection=intr,
            officer=officer,
            source='OFFICER_FIELD',
            status='CONFIRMED',
            severity=vt.default_severity,
            detected_at=timezone.now() - timedelta(days=i * 3),
            notes=f'Sample violation {i+1}',
        )
        # Create fine
        rule = FineRule.objects.filter(violation_type=vt, severity=vt.default_severity, is_active=True).first()
        if rule:
            Fine.objects.get_or_create(
                violation=v,
                defaults={
                    'citizen': citizen,
                    'amount': rule.amount,
                    'status': 'UNPAID' if i % 2 == 0 else 'PAID',
                    'due_date': timezone.now().date() + timedelta(days=30),
                }
            )

    # ── AI Session ─────────────────────────────────────────────────────────
    print('Creating AI session data...')
    session, _ = AISession.objects.get_or_create(
        name='Demo Training Session',
        defaults={
            'scenario_id': 'addis_bole',
            'status': 'COMPLETED',
            'rl_params': {'learning_rate': 0.001, 'gamma': 0.99, 'epsilon': 0.1, 'batch_size': 32},
            'started_by': dev,
        }
    )
    for ep_num in range(1, 51):
        import random
        reward = -50 + ep_num * 1.2 + random.uniform(-5, 5)
        RLEpisode.objects.get_or_create(
            session=session, episode_number=ep_num,
            defaults={
                'total_reward': Decimal(str(round(reward, 4))),
                'avg_waiting_time': Decimal(str(round(max(10, 60 - ep_num * 0.8 + random.uniform(-3, 3)), 2))),
                'throughput': random.randint(80, 150),
                'epsilon': Decimal(str(round(max(0.1, 1.0 - ep_num * 0.018), 4))),
            }
        )

    # ── AI Alert ───────────────────────────────────────────────────────────
    AIAlert.objects.get_or_create(
        alert_type='CONGESTION',
        defaults={
            'severity': 'WARNING',
            'message': 'High traffic density detected near Mexico Square',
            'intersection': intersection_objs[0],
        }
    )

    print('\n✅ Seed data created successfully!')
    print('\nTest credentials:')
    print('  Admin:      admin / admin123')
    print('  Developer:  developer / dev123')
    print('  Supervisor: supervisor01 / super123')
    print('  Officer:    officer01 / officer123')
    print('  Citizen:    citizen01 / citizen123')


if __name__ == '__main__':
    run()
