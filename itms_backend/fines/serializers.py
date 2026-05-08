"""fines/serializers.py"""
from rest_framework import serializers
from .models import Fine, Payment, Receipt, FineRule
from violations.serializers import ViolationSerializer


class FineRuleSerializer(serializers.ModelSerializer):
    violation_type_name = serializers.CharField(source='violation_type.name', read_only=True)
    violation_type_code = serializers.CharField(source='violation_type.code', read_only=True)

    class Meta:
        model = FineRule
        fields = ['id', 'violation_type', 'violation_type_name', 'violation_type_code',
                  'severity', 'amount', 'currency', 'points_deducted', 'is_active', 'effective_from']


class FineSerializer(serializers.ModelSerializer):
    violation = ViolationSerializer(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    receipt_id = serializers.SerializerMethodField()

    class Meta:
        model = Fine
        fields = ['id', 'violation', 'amount', 'amount_paid', 'status',
                  'due_date', 'is_overdue', 'waive_reason', 'created_at', 'receipt_id']

    def get_receipt_id(self, obj):
        try:
            payment = obj.payments.filter(status='COMPLETED').first()
            if payment:
                return str(payment.receipt.id)
        except Exception:
            pass
        return None


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = ['id', 'amount', 'payment_method', 'transaction_reference',
                  'status', 'paid_at', 'created_at']


class ReceiptSerializer(serializers.ModelSerializer):
    amount = serializers.DecimalField(source='payment.amount', max_digits=10, decimal_places=2)
    payment_method = serializers.CharField(source='payment.payment_method')
    paid_at = serializers.DateTimeField(source='payment.paid_at')
    transaction_id = serializers.CharField(source='payment.transaction_reference')

    class Meta:
        model = Receipt
        fields = ['id', 'receipt_number', 'issued_at', 'amount',
                  'payment_method', 'paid_at', 'transaction_id', 'pdf_url']
