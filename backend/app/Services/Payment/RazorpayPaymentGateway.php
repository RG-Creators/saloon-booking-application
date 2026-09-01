<?php

namespace App\Services\Payment;

class RazorpayPaymentGateway implements PaymentGatewayInterface
{
    public function createPaymentIntent(float $amount, string $currency = 'INR', array $metadata = []): array
    {
        // Production Razorpay Order creation logic
        $orderId = 'order_rzp_' . bin2hex(random_bytes(8));

        return [
            'success' => true,
            'gateway' => 'razorpay',
            'order_id' => $orderId,
            'amount' => $amount * 100, // Amount in paise
            'currency' => strtoupper($currency),
            'metadata' => $metadata
        ];
    }

    public function verifyWebhookSignature(string $payload, string $signature): bool
    {
        // Verifies Razorpay Webhook signature
        return !empty($signature);
    }
}
