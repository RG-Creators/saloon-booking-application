<?php

namespace App\Services\Payment;

class MockPaymentGateway implements PaymentGatewayInterface
{
    // PENDING_USER_INPUT: Await actual payment gateway credentials. This is a mock.

    public function createOrder(array $data): array
    {
        return [
            'success' => true,
            'order_id' => 'mock_order_' . uniqid(),
            'amount' => $data['amount'] ?? 0,
        ];
    }

    public function verifyPayment(array $data): bool
    {
        return true;
    }

    public function refund(string $paymentId, float $amount): array
    {
        return [
            'success' => true,
            'refund_id' => 'mock_refund_' . uniqid(),
        ];
    }
}
