<?php

namespace App\Http\Controllers;

use App\Models\Booking;
use App\Models\TenantLedger;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    /**
     * Handle payment gateway webhooks (Stripe / Razorpay).
     */
    public function webhook(Request $request)
    {
        $validated = $request->validate([
            'booking_id' => 'required|exists:bookings,id',
            'event' => 'required|string',
            'payment_id' => 'nullable|string'
        ]);

        $booking = Booking::findOrFail($validated['booking_id']);

        if ($validated['event'] === 'payment.captured' || $validated['event'] === 'payment_intent.succeeded') {
            $booking->update([
                'status' => 'CONFIRMED',
                'payment_status' => 'PAID'
            ]);

            // Auto-generate ₹1 Glamora SaaS fee debit entry
            $existingLedger = TenantLedger::where('booking_id', $booking->id)->exists();
            if (!$existingLedger) {
                TenantLedger::create([
                    'tenant_id' => $booking->tenant_id,
                    'booking_id' => $booking->id,
                    'amount' => 1.00,
                    'type' => 'DEBIT',
                    'description' => "Glamora SaaS Booking Fee - Booking #{$booking->id} (" . ($booking->service->name ?? 'Salon Service') . ")",
                    'status' => 'PENDING'
                ]);
            }

            return response()->json(['success' => true, 'message' => 'Payment webhook processed and ₹1 fee logged.']);
        }

        return response()->json(['success' => true, 'message' => 'Webhook received.']);
    }
}
