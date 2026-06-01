#!/usr/bin/env python3
"""
Test script to verify order creation endpoint and capture validation errors.
Run from backend directory: python manage.py shell < ../test_order_creation.py
"""
import os
import sys
import django

# Setup Django environment
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.exceptions import ValidationError
from rest_framework.test import APIRequestFactory
from orders.serializers import OrderCreateSerializer
from orders.views import OrderViewSet

# Test 1: Create order with missing required fields
print("=" * 60)
print("Test 1: Creating order with EMPTY payload (should fail)")
print("=" * 60)

factory = APIRequestFactory()
request = factory.post('/api/v1/orders/', {}, format='json')

# Test with empty data
serializer = OrderCreateSerializer(data={})
is_valid = serializer.is_valid()
print(f"Is valid: {is_valid}")

if not is_valid:
    print("Validation errors:")
    for field, errors in serializer.errors.items():
        print(f"  {field}: {errors}")

# Test 2: Create order with partial data
print("\n" + "=" * 60)
print("Test 2: Creating order with PARTIAL payload (missing shipping)")
print("=" * 60)

partial_data = {
    'items': [{'product': 1, 'product_name': 'Test', 'price': '10.00', 'quantity': 1}],
    'subtotal': '10.00',
    'shipping_cost': '5.00',
    'total_amount': '15.00',
}

serializer2 = OrderCreateSerializer(data=partial_data)
is_valid2 = serializer2.is_valid()
print(f"Is valid: {is_valid2}")

if not is_valid2:
    print("Validation errors:")
    for field, errors in serializer2.errors.items():
        print(f"  {field}: {errors}")

# Test 3: Create order with all required fields
print("\n" + "=" * 60)
print("Test 3: Creating order with COMPLETE payload")
print("=" * 60)

complete_data = {
    'items': [{'product': 1, 'product_name': 'Test Product', 'price': '10.00', 'quantity': 1}],
    'subtotal': '10.00',
    'shipping_cost': '5.00',
    'total_amount': '15.00',
    # Required shipping fields
    'shipping_first_name': 'John',
    'shipping_last_name': 'Doe',
    'shipping_email': 'john@example.com',
    'shipping_phone': '1234567890',
    'shipping_address': '123 Main St',
    'shipping_city': 'Accra',
    'shipping_state': 'Greater Accra',
    'shipping_postal_code': '12345',
    'shipping_country': 'Ghana',
}

serializer3 = OrderCreateSerializer(data=complete_data)
is_valid3 = serializer3.is_valid()
print(f"Is valid: {is_valid3}")

if not is_valid3:
    print("Validation errors:")
    for field, errors in serializer3.errors.items():
        print(f"  {field}: {errors}")
else:
    print("Success! All required fields present.")
    print(f"Saved data: {serializer3.validated_data}")
