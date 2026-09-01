<?php

namespace App\Http\Controllers;

use App\Models\Staff;
use App\Models\Booking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StaffWebController extends Controller
{
    /**
     * Staff / Stylist Dashboard Overview.
     */
    public function dashboard()
    {
        $user = Auth::user();
        $staffRecord = Staff::where('user_id', $user->id)->first() ?? Staff::first();

        $todayBookings = Booking::where('staff_id', $staffRecord->id ?? 1)
            ->with(['service', 'customer', 'branch'])
            ->latest()
            ->get();

        $completedCount = $todayBookings->where('status', 'COMPLETED')->count();
        $pendingCount = $todayBookings->whereIn('status', ['PENDING', 'CONFIRMED'])->count();
        $todaysEarnings = $todayBookings->where('status', 'COMPLETED')->sum('amount');

        return view('staff.dashboard', compact('staffRecord', 'todayBookings', 'completedCount', 'pendingCount', 'todaysEarnings'));
    }

    /**
     * Update appointment status by staff member.
     */
    public function updateStatus(Request $request, Booking $booking)
    {
        $validated = $request->validate([
            'status' => 'required|in:CONFIRMED,COMPLETED,CANCELLED'
        ]);

        $booking->update(['status' => $validated['status']]);

        // Auto-generate ₹1 Glamora SaaS fee if completed
        if ($validated['status'] === 'COMPLETED') {
            $existingLedger = \App\Models\TenantLedger::where('booking_id', $booking->id)->exists();
            if (!$existingLedger) {
                \App\Models\TenantLedger::create([
                    'tenant_id' => $booking->tenant_id,
                    'booking_id' => $booking->id,
                    'amount' => 1.00,
                    'type' => 'DEBIT',
                    'description' => "Glamora SaaS Booking Fee - Booking #{$booking->id} (" . ($booking->service->name ?? 'Service') . ")",
                    'status' => 'PENDING'
                ]);
            }
        }

        return back()->with('success', "Appointment #{$booking->id} marked as {$validated['status']}.");
    }

    /**
     * Real-time AJAX endpoint for live unread booking alerts for STAFF.
     */
    public function getUnreadBookingAlert()
    {
        $user = Auth::user();
        $staffRecord = Staff::where('user_id', $user->id)->first();
        
        if (!$staffRecord) {
            return response()->json(['has_new' => false]);
        }

        // Only fetch UNREAD/NEW active bookings assigned to THIS staff member
        $booking = Booking::where('staff_id', $staffRecord->id)
            ->whereIn('status', ['PENDING', 'CONFIRMED'])
            ->where('created_at', '>=', now()->subMinutes(5))
            ->with(['customer', 'service', 'tenant'])
            ->latest()
            ->first();

        if (!$booking) {
            return response()->json(['has_new' => false]);
        }

        // Check Tenant's notification dispatch policy
        $tenant = $booking->tenant;
        if ($tenant && $tenant->notification_target === 'DISPATCH_TO_OWNER') {
            // Policy says ONLY dispatch to owner, don't popup on staff screen
            return response()->json(['has_new' => false]);
        }

        return response()->json([
            'has_new' => true,
            'id' => $booking->id,
            'customer_name' => $booking->customer->name ?? 'Guest Client',
            'service_name' => $booking->service->name ?? 'Salon Service',
            'amount' => number_format($booking->amount, 2),
            'time_ago' => $booking->created_at->diffForHumans()
        ]);
    }
}
