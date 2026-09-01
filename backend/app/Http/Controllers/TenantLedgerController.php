<?php

namespace App\Http\Controllers;

use App\Models\TenantLedger;
use App\Models\PlatformSetting;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class TenantLedgerController extends Controller
{
    /**
     * Get SaaS Commission Ledger for Authenticated Shop Owner.
     * Filtered strictly to the PAST 6 MONTHS.
     */
    public function index(Request $request)
    {
        $tenantId = $request->user()->tenant_id;
        if (!$tenantId) {
            $tenantId = \App\Models\Tenant::first()?->id;
        }
        if (!$tenantId) {
            return response()->json(['success' => false, 'message' => 'No business tenant associated.'], 404);
        }

        // Check if SaaS Fee Feature Flag is Enabled in DB Platform Settings
        $dbBillingEnabled = PlatformSetting::where('key', 'billing_enabled')->value('value');
        $isEnabled = ($dbBillingEnabled === 'true' || $dbBillingEnabled === '1');

        // Strictly past 6 months filter
        $sixMonthsAgo = Carbon::now()->subMonths(6);

        $ledgers = TenantLedger::where('tenant_id', $tenantId)
            ->where('created_at', '>=', $sixMonthsAgo)
            ->with(['booking.service', 'booking.customer'])
            ->latest()
            ->get();

        $debitPending = TenantLedger::where('tenant_id', $tenantId)
            ->where('type', 'DEBIT')
            ->where('status', 'PENDING')
            ->sum('amount');

        $creditPending = TenantLedger::where('tenant_id', $tenantId)
            ->where('type', 'CREDIT')
            ->where('status', 'PENDING')
            ->sum('amount');

        $pendingBalance = max(0, $debitPending - $creditPending);

        $settledBalance = TenantLedger::where('tenant_id', $tenantId)
            ->where('status', 'SETTLED')
            ->where('created_at', '>=', $sixMonthsAgo)
            ->sum('amount');

        $razorpayKey = env('RAZORPAY_KEY', 'rzp_test_bookify_owner_key');

        return response()->json([
            'success' => true,
            'enabled' => true,
            'pending_balance' => (float)$pendingBalance,
            'settled_balance' => (float)$settledBalance,
            'razorpay_key' => $razorpayKey,
            'data' => $ledgers,
        ]);
    }

    /**
     * Add Test Commission Dues for Testing Razorpay Payments (+₹10, +₹50, +₹100, etc.)
     */
    public function addTestDues(Request $request)
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:1|max:10000',
            'description' => 'nullable|string',
        ]);

        $user = $request->user();
        $tenantId = $user->tenant_id;
        if (!$tenantId) {
            return response()->json(['success' => false, 'message' => 'No business tenant associated.'], 404);
        }

        $amount = (float)$validated['amount'];
        $desc = $validated['description'] ?? "Test Commission Fee Addition (+₹{$amount})";

        $ledger = TenantLedger::create([
            'tenant_id' => $tenantId,
            'booking_id' => null,
            'amount' => $amount,
            'type' => 'DEBIT',
            'description' => $desc,
            'status' => 'PENDING',
        ]);

        return response()->json([
            'success' => true,
            'message' => "⚡ Added test dues of ₹{$amount} to your ledger!",
            'data' => $ledger,
        ]);
    }

    /**
     * Create Razorpay Settlement Order for Pending Commission Fees
     */
    public function createOrder(Request $request)
    {
        $tenantId = $request->user()->tenant_id;
        if (!$tenantId) {
            $tenantId = \App\Models\Tenant::first()?->id;
        }
        if (!$tenantId) {
            return response()->json(['success' => false, 'message' => 'No business tenant associated.'], 404);
        }

        $pendingAmount = TenantLedger::where('tenant_id', $tenantId)
            ->where('status', 'PENDING')
            ->where('type', 'DEBIT')
            ->sum('amount');

        if ($pendingAmount <= 0) {
            return response()->json(['success' => false, 'message' => 'No pending SaaS fee balance to settle.'], 400);
        }

        $razorpayKey    = env('RAZORPAY_KEY', 'rzp_test_TMBFVjWrSJ2qmQ');
        $razorpaySecret = env('RAZORPAY_SECRET', 'dnH0G8OjVrOl85AebYVfcj16');
        $amountInPaise  = (int)round($pendingAmount * 100);

        // Create real Razorpay Order via API
        try {
            $ch = curl_init('https://api.razorpay.com/v1/orders');
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST           => true,
                CURLOPT_USERPWD        => "$razorpayKey:$razorpaySecret",
                CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
                CURLOPT_POSTFIELDS     => json_encode([
                    'amount'          => $amountInPaise,
                    'currency'        => 'INR',
                    'receipt'         => 'saas_receipt_' . $tenantId . '_' . time(),
                    'notes'           => ['tenant_id' => $tenantId, 'type' => 'SaaS Commission Settlement'],
                ]),
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => false,
                CURLOPT_TIMEOUT        => 15,
            ]);
            $rzpResponse = curl_exec($ch);
            $httpCode    = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError   = curl_error($ch);
            curl_close($ch);

            $rzpData = json_decode($rzpResponse, true);

            if ($httpCode !== 200 || empty($rzpData['id'])) {
                Log::error('Razorpay order creation failed', [
                    'http_code'  => $httpCode,
                    'curl_error' => $curlError,
                    'response'   => $rzpData,
                    'raw'        => $rzpResponse
                ]);
                $errDesc = $rzpData['error']['description'] ?? ($curlError ?: 'API status code ' . $httpCode);
                return response()->json([
                    'success' => false,
                    'message' => 'Razorpay order creation failed: ' . $errDesc,
                ], 500);
            }

            $orderId = $rzpData['id'];
        } catch (\Throwable $e) {
            Log::error('Razorpay curl error', ['message' => $e->getMessage()]);
            return response()->json(['success' => false, 'message' => 'Network error creating Razorpay order: ' . $e->getMessage()], 500);
        }

        $tenant = $request->user()->tenant;

        return response()->json([
            'success'         => true,
            'order_id'        => $orderId,
            'amount'          => (float)$pendingAmount,
            'amount_in_paise' => $amountInPaise,
            'currency'        => 'INR',
            'key'             => $razorpayKey,
            'business_name'   => $tenant->business_name ?? 'Shop Partner',
            'contact_email'   => $request->user()->email,
            'contact_mobile'  => $request->user()->mobile ?? '9999999999',
        ]);
    }

    /**
     * Verify Razorpay Payment Signature and Settle All Pending Ledger Entries
     */
    public function verifyPayment(Request $request)
    {
        $validated = $request->validate([
            'razorpay_payment_id' => 'required|string',
            'razorpay_order_id'   => 'required|string',
            'razorpay_signature'  => 'required|string',
        ]);

        $user = $request->user();
        $tenantId = $user->tenant_id;
        if (!$tenantId) {
            $tenantId = \App\Models\Tenant::first()?->id;
        }
        if (!$tenantId) {
            return response()->json(['success' => false, 'message' => 'No business tenant associated.'], 404);
        }

        $paymentId = $validated['razorpay_payment_id'];
        $orderId   = $validated['razorpay_order_id'];
        $signature = $validated['razorpay_signature'];

        // ✅ Verify Razorpay HMAC-SHA256 Signature
        $razorpaySecret   = env('RAZORPAY_SECRET', 'dnH0G8OjVrOl85AebYVfcj16');
        $expectedSignature = hash_hmac('sha256', $orderId . '|' . $paymentId, $razorpaySecret);

        if (!hash_equals($expectedSignature, $signature)) {
            Log::warning('Razorpay signature mismatch', [
                'tenant_id'  => $tenantId,
                'payment_id' => $paymentId,
                'order_id'   => $orderId,
            ]);
            return response()->json([
                'success' => false,
                'message' => '⚠️ Payment signature verification failed. Transaction rejected for security.',
            ], 422);
        }

        // Update all PENDING ledger entries for this tenant to SETTLED
        $updatedCount = TenantLedger::where('tenant_id', $tenantId)
            ->where('status', 'PENDING')
            ->update([
                'status'               => 'SETTLED',
                'razorpay_order_id'    => $orderId,
                'razorpay_payment_id'  => $paymentId,
                'razorpay_signature'   => $signature,
                'settled_at'           => Carbon::now(),
            ]);

        ActivityLog::create([
            'user_id'     => $user->id,
            'action'      => 'Settled SaaS Ledger Fee via Razorpay',
            'description' => "Shop owner {$user->name} settled {$updatedCount} pending SaaS fee entries via Razorpay Payment ID {$paymentId}.",
            'ip_address'  => $request->ip()
        ]);

        return response()->json([
            'success'            => true,
            'message'            => "✅ Payment Verified! {$updatedCount} ledger entries successfully settled.",
            'razorpay_payment_id' => $paymentId,
            'settled_count'      => $updatedCount,
        ]);
    }

    /**
     * Download Invoice PDF / Printable HTML Receipt for a Settled Entry
     */
    public function downloadInvoice(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id ?? \App\Models\Tenant::first()?->id;
        $ledger = TenantLedger::where('tenant_id', $tenantId)
            ->with(['tenant', 'booking.service', 'booking.customer'])
            ->findOrFail($id);

        $shopName = $ledger->tenant->business_name ?? 'Salon Partner';
        $invoiceNo = 'INV-GLAMORA-' . str_pad($ledger->id, 6, '0', STR_PAD_LEFT);
        $date = Carbon::parse($ledger->settled_at ?? $ledger->updated_at)->format('d M Y, h:i A');

        $html = "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='utf-8'>
            <title>Invoice {$invoiceNo}</title>
            <style>
                body { font-family: 'Helvetica Neue', Arial, sans-serif; margin: 40px; color: #1e293b; background: #ffffff; }
                .invoice-box { max-width: 800px; margin: auto; padding: 30px; border: 1px solid #e2e8f0; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
                .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #4f46e5; padding-bottom: 20px; }
                .brand { font-size: 24px; font-weight: 900; color: #4f46e5; }
                .badge { background: #dcfce7; color: #166534; padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; }
                .details { margin: 24px 0; display: flex; justify-content: space-between; }
                .table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                .table th, .table td { padding: 12px; text-align: left; border-bottom: 1px solid #e2e8f0; }
                .table th { background: #f8fafc; color: #475569; font-size: 12px; text-transform: uppercase; }
                .total { text-align: right; margin-top: 20px; font-size: 18px; font-weight: bold; color: #4f46e5; }
                .footer { margin-top: 40px; text-align: center; font-size: 12px; color: #94a3b8; }
            </style>
        </head>
        <body>
            <div class='invoice-box'>
                <div class='header'>
                    <div>
                        <div class='brand'>✂️ Bookify Partner SaaS</div>
                        <div style='font-size: 12px; color: #64748B;'>Official Fee Receipt & Tax Invoice</div>
                    </div>
                    <div class='badge'>STATUS: PAID & SETTLED</div>
                </div>

                <div class='details'>
                    <div>
                        <strong>Billed To:</strong><br>
                        {$shopName}<br>
                        GST / Partner ID: TENANT-{$tenantId}<br>
                        Date: {$date}
                    </div>
                    <div style='text-align: right;'>
                        <strong>Invoice Number:</strong> {$invoiceNo}<br>
                        <strong>Payment ID:</strong> " . ($ledger->razorpay_payment_id ?? 'ONLINE_SETTLED') . "<br>
                        <strong>Order ID:</strong> " . ($ledger->razorpay_order_id ?? 'ORDER_PAY') . "
                    </div>
                </div>

                <table class='table'>
                    <thead>
                        <tr>
                            <th>Item Description</th>
                            <th>Booking Reference</th>
                            <th>Fee Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>" . htmlspecialchars($ledger->description) . "</td>
                            <td>Booking #" . ($ledger->booking_id ?? 'N/A') . "</td>
                            <td>₹" . number_format($ledger->amount, 2) . "</td>
                        </tr>
                    </tbody>
                </table>

                <div class='total'>
                    Total Settled Amount: ₹" . number_format($ledger->amount, 2) . "
                </div>

                <div class='footer'>
                    Thank you for choosing Bookify SaaS Partner Network! Flat ₹1/booking SaaS fee.<br>
                    Generated automatically on {$date}.
                </div>
            </div>
        </body>
        </html>";

        return response($html, 200)->header('Content-Type', 'text/html');
    }
}
