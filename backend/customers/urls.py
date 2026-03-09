
from django.urls import path
from .views import get_customers, make_payment, payment_history

urlpatterns = [
    path('customers/', get_customers, name='get_customers'),
    path('payments/', make_payment, name='make_payment'),
    path('payments/<str:account_number>/', payment_history, name='payment_history'),
]