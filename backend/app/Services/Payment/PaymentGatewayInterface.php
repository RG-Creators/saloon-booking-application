<?php

namespace App\Services\Payment;

interface PaymentGatewayInterface
{
    /**
     * Create a payment order.
     */
    public function createOrder(array $data): array;

    /**
     * Verify a payment signature/webhook.
     */
    public function verifyPayment(array $data): bool;

    /**
     * Initiate a refund.
     */
    public function refund(string $paymentId, float $amount): array;
}
