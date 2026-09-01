<?php

namespace App\Http\Controllers;

use App\Models\Branch;
use App\Models\Service;
use App\Models\Staff;
use App\Models\StaffWorkingHour;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AvailabilityController extends Controller
{
    /**
     * The core booking engine availability calculator.
     * Given a branch, date, service, and optional staff, calculate 30-min block availability.
     */
    public function check(Request $request)
    {
        $validated = $request->validate([
            'branch_id' => 'required|exists:branches,id',
            'service_id' => 'required|exists:services,id',
            'date' => 'required|date_format:Y-m-d',
            'staff_id' => 'nullable|exists:staff,id',
        ]);

        $date = Carbon::parse($validated['date']);
        $dayOfWeek = $date->dayOfWeek; // 0 (Sunday) to 6 (Saturday)

        // 1. Fetch Staff Working Hours for the requested day
        $staffQuery = Staff::where('branch_id', $validated['branch_id'])
            ->where('is_active', true)
            ->where('is_bookable', true);

        if (!empty($validated['staff_id'])) {
            $staffQuery->where('id', $validated['staff_id']);
        } else {
            // Must have this service assigned
            $staffQuery->whereHas('services', function($q) use ($validated) {
                $q->where('services.id', $validated['service_id']);
            });
        }

        $availableStaffIds = $staffQuery->pluck('id');

        if ($availableStaffIds->isEmpty()) {
            return response()->json(['success' => true, 'data' => [], 'message' => 'No staff available for this service']);
        }

        $workingHours = StaffWorkingHour::whereIn('staff_id', $availableStaffIds)
            ->where('day_of_week', $dayOfWeek)
            ->where('is_working_day', true)
            ->get();

        if ($workingHours->isEmpty()) {
            return response()->json(['success' => true, 'data' => [], 'message' => 'No staff working on this day']);
        }

        // 2. Fetch existing bookings for these staff on this date to block out slots
        // TODO: Query the `bookings` table once implemented in Phase 3.
        $existingBookings = []; 

        $service = Service::findOrFail($validated['service_id']);
        $requiredDuration = $service->duration_minutes + $service->buffer_time_minutes;

        // 3. Generate Time Slots (e.g., 9:00 AM to 5:00 PM in 30 min intervals)
        $slots = [];
        foreach ($workingHours as $wh) {
            $start = Carbon::parse($validated['date'] . ' ' . $wh->start_time);
            $end = Carbon::parse($validated['date'] . ' ' . $wh->end_time);

            while ($start->copy()->addMinutes($requiredDuration)->lte($end)) {
                $timeString = $start->format('H:i');
                
                // Exclude breaks
                if ($wh->break_start && $wh->break_end) {
                    $breakStart = Carbon::parse($validated['date'] . ' ' . $wh->break_start);
                    $breakEnd = Carbon::parse($validated['date'] . ' ' . $wh->break_end);
                    $potentialEnd = $start->copy()->addMinutes($requiredDuration);
                    
                    if ($potentialEnd->gt($breakStart) && $start->lt($breakEnd)) {
                        $start->addMinutes(30);
                        continue;
                    }
                }

                // Exclude existing bookings (placeholder logic)
                $isBooked = false; // Logic to check against $existingBookings goes here

                if (!$isBooked && !isset($slots[$timeString])) {
                    $slots[$timeString] = [
                        'time' => $timeString,
                        'available' => true,
                        'staff_ids' => []
                    ];
                }
                
                if (!$isBooked) {
                    $slots[$timeString]['staff_ids'][] = $wh->staff_id;
                }

                $start->addMinutes(30);
            }
        }

        // Sort slots by time
        ksort($slots);

        return response()->json([
            'success' => true, 
            'data' => array_values($slots),
            'service_duration' => $requiredDuration
        ]);
    }
}
