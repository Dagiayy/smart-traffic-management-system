from django.urls import path
from .views import VehicleListView

urlpatterns = [
    path('vehicles/', VehicleListView.as_view()),
]
