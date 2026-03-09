from django.db import models
from django.db import models

class Customer(models.Model):

    account_no = models.CharField(max_length=20, unique=True)
    issue_date = models.DateField()
    interest_rate = models.FloatField()
    tenure = models.IntegerField()
    emi_due = models.FloatField()

    def __str__(self):
        return self.account_no


class Payment(models.Model):

    STATUS_CHOICES = [
        ('SUCCESS', 'Success'),
        ('FAILED', 'Failed'),
        ('PENDING', 'Pending'),
    ]

    customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
    payment_date = models.DateTimeField(auto_now_add=True)
    payment_amount = models.FloatField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='SUCCESS')

    def __str__(self):
        return str(self.customer) 
# Create your models here.
