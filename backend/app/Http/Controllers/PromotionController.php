<?php

namespace App\Http\Controllers;

use App\Models\Branch;
use App\Models\OffPeakDiscount;
use App\Models\RushPricingRule;
use App\Models\Tenant;
use Illuminate\Http\Request;

class PromotionController extends Controller
{
    private function getTenantId(Request $request): int
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        return (int) ($user?->tenant_id ?? $staffRecord?->branch?->tenant_id ?? Tenant::first()?->id ?? 1);
    }

    /**
     * Get all Off-Peak Discounts and Rush Surge Rules from the database.
     */
    public function index(Request $request)
    {
        $tenantId = $this->getTenantId($request);

        $discounts = OffPeakDiscount::where('tenant_id', $tenantId)
            ->with('branch:id,name,city')
            ->orderBy('id', 'desc')
            ->get();

        $surgeRules = RushPricingRule::where('tenant_id', $tenantId)
            ->with('branch:id,name,city')
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'success'    => true,
            'promotions' => $discounts->map(fn($d) => [
                'id'               => $d->id,
                'title'            => $d->title,
                'discount_percent' => (int) round($d->discount_percent),
                'time_window'      => $d->time_window ?? $this->formatTimeWindow($d->days_of_week ?? [], $d->start_time ?? '14:00', $d->end_time ?? '17:00'),
                'days_of_week'     => $d->days_of_week ?? [],
                'start_time'       => $d->start_time ? substr($d->start_time, 0, 5) : '14:00',
                'end_time'         => $d->end_time ? substr($d->end_time, 0, 5) : '17:00',
                'branch_id'        => $d->branch_id,
                'branch_name'      => $d->branch?->name ?? 'All Branches',
                'is_active'        => (bool) $d->is_active,
            ]),
            'rush_rules' => $surgeRules->map(fn($r) => [
                'id'           => $r->id,
                'title'        => $r->title,
                'surge_amount' => (float) $r->surge_amount,
                'time_slot'    => $r->time_slot ?? $this->formatTimeWindow($r->days_of_week ?? [], $r->start_time ?? '16:00', $r->end_time ?? '20:00'),
                'days_of_week' => $r->days_of_week ?? [],
                'start_time'   => $r->start_time ? substr($r->start_time, 0, 5) : '16:00',
                'end_time'     => $r->end_time ? substr($r->end_time, 0, 5) : '20:00',
                'branch_id'    => $r->branch_id,
                'branch_name'  => $r->branch?->name ?? 'All Branches',
                'is_enabled'   => (bool) $r->is_enabled,
            ]),
        ]);
    }

    // ==========================================
    // OFF-PEAK DISCOUNTS CRUD
    // ==========================================

    public function storeDiscount(Request $request)
    {
        $tenantId = $this->getTenantId($request);

        $validated = $request->validate([
            'title'            => 'required|string|max:255',
            'discount_percent' => 'required|numeric|min:1|max:100',
            'days_of_week'     => 'nullable|array',
            'start_time'       => 'nullable|string',
            'end_time'         => 'nullable|string',
            'time_window'      => 'nullable|string',
            'branch_id'        => 'nullable|integer|exists:branches,id',
            'is_active'        => 'nullable|boolean',
        ]);

        $days = $validated['days_of_week'] ?? [1, 2, 3, 4];
        $startTime = $this->to24Hour($validated['start_time'] ?? '14:00');
        $endTime = $this->to24Hour($validated['end_time'] ?? '17:00');
        $timeWindow = $validated['time_window'] ?? $this->formatTimeWindow($days, $startTime, $endTime);

        $discount = OffPeakDiscount::create([
            'tenant_id'        => $tenantId,
            'branch_id'        => $validated['branch_id'] ?? null,
            'title'            => $validated['title'],
            'discount_percent' => $validated['discount_percent'],
            'days_of_week'     => $days,
            'start_time'       => $startTime,
            'end_time'         => $endTime,
            'time_window'      => $timeWindow,
            'is_active'        => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Off-Peak Discount promotion created successfully!',
            'data'    => $discount->load('branch'),
        ], 201);
    }

    public function updateDiscount(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $discount = OffPeakDiscount::where('tenant_id', $tenantId)->findOrFail($id);

        $validated = $request->validate([
            'title'            => 'sometimes|string|max:255',
            'discount_percent' => 'sometimes|numeric|min:1|max:100',
            'days_of_week'     => 'nullable|array',
            'start_time'       => 'nullable|string',
            'end_time'         => 'nullable|string',
            'time_window'      => 'nullable|string',
            'branch_id'        => 'nullable|integer|exists:branches,id',
            'is_active'        => 'nullable|boolean',
        ]);

        if (isset($validated['start_time'])) {
            $validated['start_time'] = $this->to24Hour($validated['start_time']);
        }
        if (isset($validated['end_time'])) {
            $validated['end_time'] = $this->to24Hour($validated['end_time']);
        }

        if (isset($validated['days_of_week']) || isset($validated['start_time']) || isset($validated['end_time'])) {
            $days = $validated['days_of_week'] ?? $discount->days_of_week ?? [];
            $startTime = $validated['start_time'] ?? $discount->start_time ?? '14:00';
            $endTime = $validated['end_time'] ?? $discount->end_time ?? '17:00';
            $validated['time_window'] = $this->formatTimeWindow($days, $startTime, $endTime);
        }

        $discount->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Off-Peak Discount updated successfully!',
            'data'    => $discount->load('branch'),
        ]);
    }

    public function toggleDiscount(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $discount = OffPeakDiscount::where('tenant_id', $tenantId)->findOrFail($id);

        $newActive = $request->has('is_active') ? (bool) $request->is_active : !$discount->is_active;
        $discount->update(['is_active' => $newActive]);

        return response()->json([
            'success'   => true,
            'message'   => 'Discount status updated successfully!',
            'is_active' => $discount->is_active,
        ]);
    }

    public function destroyDiscount(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $discount = OffPeakDiscount::where('tenant_id', $tenantId)->findOrFail($id);
        $discount->delete();

        return response()->json([
            'success' => true,
            'message' => 'Off-Peak Discount deleted successfully!',
        ]);
    }

    // ==========================================
    // RUSH SURGE RULES CRUD
    // ==========================================

    public function storeSurgeRule(Request $request)
    {
        $tenantId = $this->getTenantId($request);

        $validated = $request->validate([
            'title'        => 'required|string|max:255',
            'surge_amount' => 'required|numeric|min:1',
            'days_of_week' => 'nullable|array',
            'start_time'   => 'nullable|string',
            'end_time'     => 'nullable|string',
            'time_slot'    => 'nullable|string',
            'branch_id'    => 'nullable|integer|exists:branches,id',
            'is_enabled'   => 'nullable|boolean',
        ]);

        $days = $validated['days_of_week'] ?? [0, 6];
        $startTime = $this->to24Hour($validated['start_time'] ?? '16:00');
        $endTime = $this->to24Hour($validated['end_time'] ?? '20:00');
        $timeSlot = $validated['time_slot'] ?? $this->formatTimeWindow($days, $startTime, $endTime);

        $surgeRule = RushPricingRule::create([
            'tenant_id'    => $tenantId,
            'branch_id'    => $validated['branch_id'] ?? null,
            'title'        => $validated['title'],
            'surge_amount' => $validated['surge_amount'],
            'days_of_week' => $days,
            'start_time'   => $startTime,
            'end_time'     => $endTime,
            'time_slot'    => $timeSlot,
            'is_enabled'   => $validated['is_enabled'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Rush Surge Pricing Rule created successfully!',
            'data'    => $surgeRule->load('branch'),
        ], 201);
    }

    public function updateSurgeRule(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $surgeRule = RushPricingRule::where('tenant_id', $tenantId)->findOrFail($id);

        $validated = $request->validate([
            'title'        => 'sometimes|string|max:255',
            'surge_amount' => 'sometimes|numeric|min:1',
            'days_of_week' => 'nullable|array',
            'start_time'   => 'nullable|string',
            'end_time'     => 'nullable|string',
            'time_slot'    => 'nullable|string',
            'branch_id'    => 'nullable|integer|exists:branches,id',
            'is_enabled'   => 'nullable|boolean',
        ]);

        if (isset($validated['start_time'])) {
            $validated['start_time'] = $this->to24Hour($validated['start_time']);
        }
        if (isset($validated['end_time'])) {
            $validated['end_time'] = $this->to24Hour($validated['end_time']);
        }

        if (isset($validated['days_of_week']) || isset($validated['start_time']) || isset($validated['end_time'])) {
            $days = $validated['days_of_week'] ?? $surgeRule->days_of_week ?? [];
            $startTime = $validated['start_time'] ?? $surgeRule->start_time ?? '16:00';
            $endTime = $validated['end_time'] ?? $surgeRule->end_time ?? '20:00';
            $validated['time_slot'] = $this->formatTimeWindow($days, $startTime, $endTime);
        }

        $surgeRule->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Rush Surge Rule updated successfully!',
            'data'    => $surgeRule->load('branch'),
        ]);
    }

    public function toggleSurgeRule(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $surgeRule = RushPricingRule::where('tenant_id', $tenantId)->findOrFail($id);

        $newEnabled = $request->has('is_enabled') ? (bool) $request->is_enabled : !$surgeRule->is_enabled;
        $surgeRule->update(['is_enabled' => $newEnabled]);

        return response()->json([
            'success'    => true,
            'message'    => 'Surge rule status updated successfully!',
            'is_enabled' => $surgeRule->is_enabled,
        ]);
    }

    public function destroySurgeRule(Request $request, $id)
    {
        $tenantId = $this->getTenantId($request);
        $surgeRule = RushPricingRule::where('tenant_id', $tenantId)->findOrFail($id);
        $surgeRule->delete();

        return response()->json([
            'success' => true,
            'message' => 'Rush Surge Rule deleted successfully!',
        ]);
    }

    private function formatTime12H(string $time): string
    {
        $time = trim($time);
        if (empty($time)) return '';
        if (stripos($time, 'AM') !== false || stripos($time, 'PM') !== false) {
            return $time;
        }
        $parts = explode(':', $time);
        $hour = (int) ($parts[0] ?? 0);
        $min = (int) ($parts[1] ?? 0);
        $period = $hour >= 12 ? 'PM' : 'AM';
        $displayHour = $hour % 12;
        if ($displayHour === 0) $displayHour = 12;
        return sprintf('%02d:%02d %s', $displayHour, $min, $period);
    }

    private function to24Hour(string $time): string
    {
        $time = trim($time);
        if (empty($time)) return '12:00:00';
        if (stripos($time, 'AM') !== false || stripos($time, 'PM') !== false) {
            $isPm = stripos($time, 'PM') !== false;
            $clean = preg_replace('/[^0-9:]/', '', $time);
            $parts = explode(':', $clean);
            $h = (int) ($parts[0] ?? 0);
            $m = (int) ($parts[1] ?? 0);
            if ($isPm && $h < 12) $h += 12;
            if (!$isPm && $h === 12) $h = 0;
            return sprintf('%02d:%02d:00', $h, $m);
        }
        $parts = explode(':', $time);
        $h = (int) ($parts[0] ?? 0);
        $m = (int) ($parts[1] ?? 0);
        return sprintf('%02d:%02d:00', $h, $m);
    }

    private function formatTimeWindow(array $days, string $start, string $end): string
    {
        $dayNames = [0 => 'Sun', 1 => 'Mon', 2 => 'Tue', 3 => 'Wed', 4 => 'Thu', 5 => 'Fri', 6 => 'Sat'];
        $dayLabels = [];
        foreach ($days as $d) {
            if (isset($dayNames[$d])) {
                $dayLabels[] = $dayNames[$d];
            }
        }
        $daysStr = !empty($dayLabels) ? implode(', ', $dayLabels) : 'Everyday';
        $start12 = $this->formatTime12H($start);
        $end12 = $this->formatTime12H($end);
        return "{$daysStr} • {$start12} to {$end12}";
    }
}
