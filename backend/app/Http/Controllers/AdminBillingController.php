<?php

namespace App\Http\Controllers;

use App\Models\PlatformSetting;
use Illuminate\Http\Request;
use App\Models\TenantLedger;
use App\Models\Tenant;

class AdminBillingController extends Controller
{
    /**
     * Public API — Returns billing engine on/off status for the mobile app.
     * No auth required; safe to poll every few seconds.
     */
    public function billingStatus()
    {
        $raw = PlatformSetting::where('key', 'billing_enabled')->value('value');
        $enabled = ($raw === 'true' || $raw === '1');
        return response()->json([
            'success' => true,
            'enabled' => $enabled,
        ]);
    }
    public function index()
    {
        $billingEnabled = PlatformSetting::where('key', 'billing_enabled')->value('value') ?? 'false';
        $bookingFee = PlatformSetting::where('key', 'booking_fee_amount')->value('value') ?? '1.00';
        
        $totalSaasCollected = TenantLedger::where('type', 'CREDIT')->sum('amount');
        $totalOutstandingFees = max(0, TenantLedger::where('type', 'DEBIT')->where('status', 'PENDING')->sum('amount') - TenantLedger::where('type', 'CREDIT')->where('status', 'PENDING')->sum('amount'));

        $tenantsWithLedger = Tenant::all()->map(function($tenant) {
            $debit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'DEBIT')->where('status', 'PENDING')->sum('amount');
            $credit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'CREDIT')->where('status', 'PENDING')->sum('amount');
            $tenant->due_amount = max(0, $debit - $credit);
            $tenant->total_bookings = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'DEBIT')->count();
            return $tenant;
        });

        // Invoices list based on real ledgers
        $invoices = TenantLedger::with('tenant')->latest()->take(30)->get();

        return view('admin.billing', compact('billingEnabled', 'bookingFee', 'totalSaasCollected', 'totalOutstandingFees', 'tenantsWithLedger', 'invoices'));
    }

    /**
     * Real-time 5-second polling endpoint for Super Admin Billing Portal.
     */
    public function liveData()
    {
        $billingEnabled = PlatformSetting::where('key', 'billing_enabled')->value('value') ?? 'false';
        $bookingFee = PlatformSetting::where('key', 'booking_fee_amount')->value('value') ?? '1.00';
        
        $totalSaasCollected = TenantLedger::where('type', 'CREDIT')->sum('amount');
        $totalOutstandingFees = max(0, TenantLedger::where('type', 'DEBIT')->where('status', 'PENDING')->sum('amount') - TenantLedger::where('type', 'CREDIT')->where('status', 'PENDING')->sum('amount'));

        $tenantsWithLedger = Tenant::all()->map(function($tenant) {
            $debit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'DEBIT')->where('status', 'PENDING')->sum('amount');
            $credit = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'CREDIT')->where('status', 'PENDING')->sum('amount');
            $tenant->due_amount = max(0, $debit - $credit);
            $tenant->total_bookings = TenantLedger::where('tenant_id', $tenant->id)->where('type', 'DEBIT')->count();
            return [
                'id' => $tenant->id,
                'business_name' => $tenant->business_name,
                'business_type' => $tenant->business_type,
                'total_bookings' => $tenant->total_bookings,
                'due_amount' => (float)$tenant->due_amount,
                'formatted_due' => number_format($tenant->due_amount, 2),
            ];
        });

        $invoices = TenantLedger::with('tenant')->latest()->take(30)->get()->map(function($inv) {
            return [
                'id' => $inv->id,
                'date' => $inv->created_at->format('M d, Y • H:i'),
                'tenant_name' => $inv->tenant->business_name ?? 'Tenant Salon',
                'description' => $inv->description,
                'type' => $inv->type,
                'amount' => (float)$inv->amount,
                'formatted_amount' => number_format($inv->amount, 2),
                'status' => $inv->status,
            ];
        });

        return response()->json([
            'success' => true,
            'billing_enabled' => $billingEnabled,
            'booking_fee' => $bookingFee,
            'total_saas_collected' => (float)$totalSaasCollected,
            'formatted_total_collected' => number_format($totalSaasCollected, 2),
            'total_outstanding_fees' => (float)$totalOutstandingFees,
            'formatted_total_outstanding' => number_format($totalOutstandingFees, 2),
            'tenants' => $tenantsWithLedger,
            'invoices' => $invoices,
        ]);
    }

    public function toggle(Request $request)
    {
        try {
            $newValue = $request->input('enabled', 'false');
            $newValue = ($newValue === 'true') ? 'true' : 'false';

            PlatformSetting::updateOrCreate(
                ['key' => 'billing_enabled'],
                ['value' => $newValue]
            );

            $showRawErrors = PlatformSetting::where('key', 'show_raw_errors')->value('value') === 'true';
            $rawMsg = $showRawErrors ? "[RAW VERBOSE LOG]: PlatformSetting updated key=billing_enabled to {$newValue}" : null;

            if ($request->wantsJson() || $request->ajax() || $request->header('Accept') === 'application/json') {
                return response()->json([
                    'success' => true,
                    'billing_enabled' => $newValue,
                    'message' => 'Billing configuration updated successfully.',
                    'raw_error' => $rawMsg,
                ]);
            }

            return back()->with('success', 'Billing configuration updated successfully.');
        } catch (\Throwable $e) {
            $showRawErrors = PlatformSetting::where('key', 'show_raw_errors')->value('value') === 'true';
            $rawErrorStr = $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine();

            if ($request->wantsJson() || $request->ajax() || $request->header('Accept') === 'application/json') {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to update billing configuration.',
                    'raw_error' => $showRawErrors ? $rawErrorStr : null,
                ], 500);
            }
            return back()->with('error', 'Failed to update billing configuration.');
        }
    }

    /**
     * Add Manual Dues for a Shop Tenant
     */
    public function addDues(Request $request)
    {
        try {
            $validated = $request->validate([
                'tenant_id' => 'required|exists:tenants,id',
                'amount' => 'required|numeric|min:1|max:100000',
                'description' => 'nullable|string',
            ]);

            $tenant = Tenant::findOrFail($validated['tenant_id']);
            $amount = (float)$validated['amount'];
            $desc = $validated['description'] ?? "Super Admin Manual SaaS Fee (+₹{$amount})";

            $ledger = TenantLedger::create([
                'tenant_id' => $tenant->id,
                'amount' => $amount,
                'type' => 'DEBIT',
                'description' => $desc,
                'status' => 'PENDING',
            ]);

            $showRawErrors = PlatformSetting::where('key', 'show_raw_errors')->value('value') === 'true';
            $rawMsg = $showRawErrors ? "[RAW VERBOSE LOG]: Created TenantLedger ID={$ledger->id}, Tenant={$tenant->id}, Amount={$amount}" : null;
            $msg = "⚡ Added ₹" . number_format($amount, 2) . " manual SaaS dues to '{$tenant->business_name}' ledger!";

            if ($request->wantsJson() || $request->ajax() || $request->header('Accept') === 'application/json') {
                return response()->json([
                    'success' => true,
                    'message' => $msg,
                    'raw_error' => $rawMsg,
                ]);
            }

            return back()->with('success', $msg);
        } catch (\Throwable $e) {
            $showRawErrors = PlatformSetting::where('key', 'show_raw_errors')->value('value') === 'true';
            $rawErrorStr = $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine();

            if ($request->wantsJson() || $request->ajax() || $request->header('Accept') === 'application/json') {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to add manual dues.',
                    'raw_error' => $showRawErrors ? $rawErrorStr : null,
                ], 500);
            }
            return back()->with('error', 'Failed to add manual dues.');
        }
    }
}
