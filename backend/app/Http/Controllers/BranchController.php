<?php

namespace App\Http\Controllers;

use App\Models\Branch;
use Illuminate\Http\Request;

class BranchController extends Controller
{
    public function index(Request $request)
    {
        $tenantId = $request->user()->tenant_id;
        $branches = Branch::where('tenant_id', $tenantId)
            ->withCount(['staff', 'combos'])
            ->with('workingHours')
            ->get();
        return response()->json(['success' => true, 'data' => $branches]);
    }

    public function store(Request $request)
    {
        $tenantId = $request->user()->tenant_id;
        $count = Branch::where('tenant_id', $tenantId)->count();
        if ($count >= 4) {
            return response()->json(['success' => false, 'message' => 'Maximum 4 branches allowed per salon.'], 422);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'address' => 'required|string',
            'city' => 'required|string',
            'state' => 'nullable|string',
            'pin_code' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'contact_mobile' => 'nullable|string',
            'contact_email' => 'nullable|email',
            'is_active' => 'nullable|boolean',
        ]);

        $validated['tenant_id'] = $tenantId;
        $validated['is_active'] = $request->boolean('is_active', true);

        $branch = Branch::create($validated);

        // Auto-seed standard 7-day working hours for the new branch
        for ($i = 0; $i < 7; $i++) {
            $branch->workingHours()->create([
                'day_of_week' => $i,
                'is_open' => $i !== 0, // Sunday closed by default
                'open_time' => '10:00:00',
                'close_time' => '20:00:00',
                'has_split_shift' => false,
            ]);
        }

        return response()->json([
            'success' => true, 
            'message' => 'New branch created successfully!', 
            'data' => $branch->load('workingHours')
        ], 201);
    }

    public function show(Request $request, $id)
    {
        $branch = Branch::where('tenant_id', $request->user()->tenant_id)
            ->with(['workingHours', 'staff', 'combos'])
            ->findOrFail($id);
        return response()->json(['success' => true, 'data' => $branch]);
    }

    public function update(Request $request, $id)
    {
        $branch = Branch::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'address' => 'sometimes|string',
            'city' => 'sometimes|string',
            'state' => 'nullable|string',
            'pin_code' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'contact_mobile' => 'nullable|string',
            'contact_email' => 'nullable|email',
            'is_active' => 'nullable|boolean',
        ]);

        $branch->update($validated);
        return response()->json([
            'success' => true, 
            'message' => 'Branch updated successfully!', 
            'data' => $branch->load('workingHours')
        ]);
    }

    public function toggleActive(Request $request, $id)
    {
        $branch = Branch::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $branch->is_active = !$branch->is_active;
        $branch->save();

        return response()->json([
            'success' => true,
            'message' => $branch->is_active ? "'{$branch->name}' is now active & accepting bookings." : "'{$branch->name}' is now disabled.",
            'data' => $branch
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $count = Branch::where('tenant_id', $tenantId)->count();
        if ($count <= 1) {
            return response()->json([
                'success' => false, 
                'message' => 'Cannot delete your only remaining branch. At least one primary branch is required.'
            ], 422);
        }

        $branch = Branch::where('tenant_id', $tenantId)->findOrFail($id);
        $branch->delete();
        return response()->json(['success' => true, 'message' => 'Branch and its schedules deleted successfully!']);
    }

    public function hours(Request $request, $id)
    {
        $branch = Branch::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $hours = $branch->workingHours()->orderBy('day_of_week')->get();
        return response()->json(['success' => true, 'data' => $hours]);
    }

    public function updateHours(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $branch = Branch::where('tenant_id', $tenantId)->findOrFail($id);
        
        $request->validate([
            'hours' => 'required|array',
            'hours.*.day_of_week' => 'required|integer|min:0|max:6',
            'hours.*.is_open' => 'required',
            'hours.*.open_time' => 'nullable|string',
            'hours.*.close_time' => 'nullable|string',
            'hours.*.has_split_shift' => 'nullable',
            'hours.*.split_open_time' => 'nullable|string',
            'hours.*.split_close_time' => 'nullable|string',
            'apply_to_all_branches' => 'nullable|boolean',
        ]);

        $formatTime = function ($timeStr, $default = null) {
            if (empty($timeStr)) return $default;
            try {
                return \Carbon\Carbon::parse($timeStr)->format('H:i:s');
            } catch (\Exception $e) {
                return $default;
            }
        };

        $applyToAll = $request->boolean('apply_to_all_branches');
        $targetBranches = $applyToAll
            ? Branch::where('tenant_id', $tenantId)->get()
            : collect([$branch]);

        foreach ($targetBranches as $b) {
            foreach ($request->hours as $hourData) {
                $isOpen = filter_var($hourData['is_open'] ?? false, FILTER_VALIDATE_BOOLEAN);
                $hasSplit = filter_var($hourData['has_split_shift'] ?? false, FILTER_VALIDATE_BOOLEAN);

                $b->workingHours()->updateOrCreate(
                    ['day_of_week' => (int)$hourData['day_of_week']],
                    [
                        'is_open' => $isOpen,
                        'open_time' => $formatTime($hourData['open_time'] ?? null, '10:00:00'),
                        'close_time' => $formatTime($hourData['close_time'] ?? null, '20:00:00'),
                        'has_split_shift' => $hasSplit,
                        'split_open_time' => $hasSplit ? $formatTime($hourData['split_open_time'] ?? null, '16:00:00') : null,
                        'split_close_time' => $hasSplit ? $formatTime($hourData['split_close_time'] ?? null, '20:00:00') : null,
                    ]
                );
            }
        }

        return response()->json([
            'success' => true,
            'message' => $applyToAll 
                ? 'Operating hours synced to all branches successfully!' 
                : 'Branch operating schedule saved successfully!',
            'data' => $branch->workingHours()->orderBy('day_of_week')->get()
        ]);
    }
}
