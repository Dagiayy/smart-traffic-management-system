"""fines/admin_views.py"""
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from itms_backend.permissions import IsAdmin, IsAdminOrDeveloper
from .models import Fine, FineRule
from .serializers import FineSerializer, FineRuleSerializer


class AdminFinesListView(generics.ListAPIView):
    permission_classes = [IsAdminOrDeveloper]
    serializer_class = FineSerializer

    def get_queryset(self):
        qs = Fine.objects.select_related('violation', 'citizen').order_by('-created_at')
        status_f = self.request.query_params.get('status')
        if status_f:
            qs = qs.filter(status=status_f)
        return qs


class AdminFineDetailView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request, pk):
        try:
            fine = Fine.objects.select_related('violation', 'citizen').get(pk=pk)
        except Fine.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)
        return Response(FineSerializer(fine).data)

    def patch(self, request, pk):
        try:
            fine = Fine.objects.get(pk=pk)
        except Fine.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)

        if 'status' in request.data:
            fine.status = request.data['status']
        if 'waive_reason' in request.data:
            fine.waive_reason = request.data['waive_reason']
            fine.status = 'WAIVED'
        if 'amount' in request.data:
            fine.amount = request.data['amount']
        fine.save()
        return Response(FineSerializer(fine).data)


class AdminFineRulesView(generics.ListCreateAPIView):
    permission_classes = [IsAdmin]
    serializer_class = FineRuleSerializer
    queryset = FineRule.objects.filter(is_active=True).order_by('violation_type__name', 'severity')


class AdminFineRuleDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAdmin]
    serializer_class = FineRuleSerializer
    queryset = FineRule.objects.all()

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        return Response(status=status.HTTP_204_NO_CONTENT)
