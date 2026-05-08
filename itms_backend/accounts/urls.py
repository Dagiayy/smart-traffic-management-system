"""accounts/urls.py — Auth endpoints shared by all clients"""
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    path('register/',         views.RegisterView.as_view(),      name='auth-register'),
    path('login/',            views.LoginView.as_view(),         name='auth-login'),
    path('logout/',           views.LogoutView.as_view(),        name='auth-logout'),
    path('token/refresh/',    TokenRefreshView.as_view(),        name='token-refresh'),
    path('me/',               views.MeView.as_view(),            name='auth-me'),
    path('otp/send/',         views.SendOTPView.as_view(),       name='otp-send'),
    path('otp/verify/',       views.VerifyOTPView.as_view(),     name='otp-verify'),
    path('password/reset/',   views.ResetPasswordView.as_view(), name='password-reset'),
    path('push-token/',       views.PushTokenView.as_view(),     name='push-token'),
]
