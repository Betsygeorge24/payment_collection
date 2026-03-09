from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Customer, Payment
from .serializers import CustomerSerializer, PaymentSerializer
# Create your views here.
@api_view(['GET'])
def get_customers(request):

    customers = Customer.objects.all()
    serializer = CustomerSerializer(customers, many=True)

    return Response(serializer.data)
@api_view(['POST'])
def make_payment(request):
    account_number = request.data.get('account_no')
    amount = request.data.get('payment_amount')

    try:
        customer = Customer.objects.get(account_no=account_number)
    except Customer.DoesNotExist:
        return Response(
            {"error": "Customer does not exist."},
            status=status.HTTP_404_NOT_FOUND
        )

    payment = Payment.objects.create(
        customer=customer,
        payment_amount=amount
    )

    return Response({
        "id": payment.id,
        "customer": customer.account_no,
        "payment_amount": payment.payment_amount,
        "status": payment.status
    })

@api_view(['GET'])
def payment_history(request, account_number):

    customer = Customer.objects.get(account_no=account_number)

    payments = Payment.objects.filter(customer=customer)

    serializer = PaymentSerializer(payments, many=True)

    return Response(serializer.data)
