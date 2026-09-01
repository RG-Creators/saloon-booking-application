<?php

namespace App\Http\Controllers;

use App\Models\Branch;
use App\Models\Service;
use Illuminate\Http\Request;

class ServiceController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $staffRecord = \App\Models\Staff::where('user_id', $user?->id)->first();
        $tenantId = $user?->tenant_id ?? $staffRecord?->branch?->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $services = Service::whereIn('branch_id', $branchIds)
            ->with('branch:id,name,city,pin_code')
            ->when($request->branch_id, function ($query, $branchId) {
                return $query->where('branch_id', $branchId);
            })
            ->latest()
            ->get();
            
        return response()->json(['success' => true, 'data' => $services]);
    }

    public function store(Request $request)
    {
        $tenantId = $request->user()->tenant_id;
        $allTenantBranches = Branch::where('tenant_id', $tenantId)->get();

        if ($allTenantBranches->isEmpty()) {
            return response()->json(['success' => false, 'message' => 'Please create at least one branch before adding services.'], 422);
        }

        $validated = $request->validate([
            'branch_id'             => 'nullable|integer',
            'branch_ids'            => 'nullable|array',
            'branch_ids.*'          => 'integer|exists:branches,id',
            'apply_to_all_branches' => 'nullable|boolean',
            'name'                  => 'required|string|max:255',
            'description'           => 'nullable|string',
            'category'              => 'nullable|string',
            'service_type'          => 'nullable|string|in:IN_STUDIO,AT_HOME,EVENT_WEDDING,ANY',
            'price'                 => 'required|numeric|min:0',
            'home_surcharge'        => 'nullable|numeric|min:0',
            'duration_minutes'      => 'required|integer|min:1',
            'buffer_time_minutes'   => 'nullable|integer|min:0',
            'image'                 => 'nullable|string',
            'is_active'             => 'nullable|boolean',
            'online_booking_enabled'=> 'nullable|boolean',
        ]);

        $applyToAll = $request->boolean('apply_to_all_branches', false);
        $targetBranchIds = [];

        if ($applyToAll || (empty($validated['branch_ids']) && empty($validated['branch_id']))) {
            // Default to ALL branches of this salon
            $targetBranchIds = $allTenantBranches->pluck('id')->toArray();
        } elseif (!empty($validated['branch_ids'])) {
            $targetBranchIds = $allTenantBranches->whereIn('id', $validated['branch_ids'])->pluck('id')->toArray();
        } elseif (!empty($validated['branch_id'])) {
            $targetBranchIds = [$validated['branch_id']];
        } else {
            $targetBranchIds = [$allTenantBranches->first()->id];
        }

        $createdServices = [];
        foreach ($targetBranchIds as $bId) {
            $service = Service::updateOrCreate(
                [
                    'branch_id' => $bId,
                    'name'      => $validated['name'],
                ],
                [
                    'description'           => $validated['description'] ?? null,
                    'category'              => $validated['category'] ?? 'General',
                    'service_type'          => $validated['service_type'] ?? 'IN_STUDIO',
                    'price'                 => $validated['price'],
                    'home_surcharge'        => $validated['home_surcharge'] ?? 0.00,
                    'duration_minutes'      => $validated['duration_minutes'],
                    'buffer_time_minutes'   => $validated['buffer_time_minutes'] ?? 5,
                    'image'                 => $validated['image'] ?? null,
                    'is_active'             => $validated['is_active'] ?? true,
                    'online_booking_enabled'=> $validated['online_booking_enabled'] ?? true,
                ]
            );
            $createdServices[] = $service->load('branch:id,name,city,pin_code');
        }

        return response()->json([
            'success' => true, 
            'message' => 'Service successfully published across ' . count($createdServices) . ' branch(es)!',
            'data'    => $createdServices[0] ?? null,
            'all'     => $createdServices
        ], 201);
    }

    public function show(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $service = Service::whereIn('branch_id', $branchIds)
            ->with('branch:id,name,city,pin_code')
            ->findOrFail($id);
            
        return response()->json(['success' => true, 'data' => $service]);
    }

    public function update(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $allTenantBranches = Branch::where('tenant_id', $tenantId)->get();
        $branchIds = $allTenantBranches->pluck('id');
        
        $service = Service::whereIn('branch_id', $branchIds)->findOrFail($id);

        $validated = $request->validate([
            'branch_id'             => 'nullable|integer',
            'branch_ids'            => 'nullable|array',
            'branch_ids.*'          => 'integer|exists:branches,id',
            'apply_to_all_branches' => 'nullable|boolean',
            'name'                  => 'sometimes|string|max:255',
            'description'           => 'nullable|string',
            'category'              => 'nullable|string',
            'service_type'          => 'nullable|string|in:IN_STUDIO,AT_HOME,EVENT_WEDDING,ANY',
            'price'                 => 'sometimes|numeric|min:0',
            'home_surcharge'        => 'nullable|numeric|min:0',
            'duration_minutes'      => 'sometimes|integer|min:1',
            'buffer_time_minutes'   => 'nullable|integer|min:0',
            'image'                 => 'nullable|string',
            'is_active'             => 'nullable|boolean',
            'online_booking_enabled'=> 'nullable|boolean',
        ]);

        $applyToAll = $request->boolean('apply_to_all_branches', false);
        $oldName = $service->name;
        $newName = $validated['name'] ?? $oldName;

        if ($applyToAll) {
            // Replicate update across ALL branches of this salon
            foreach ($allTenantBranches as $b) {
                Service::updateOrCreate(
                    [
                        'branch_id' => $b->id,
                        'name'      => ($b->id === $service->branch_id) ? $newName : $oldName,
                    ],
                    [
                        'name'                  => $newName,
                        'description'           => array_key_exists('description', $validated) ? $validated['description'] : $service->description,
                        'category'              => $validated['category'] ?? $service->category,
                        'service_type'          => $validated['service_type'] ?? $service->service_type,
                        'price'                 => $validated['price'] ?? $service->price,
                        'home_surcharge'        => array_key_exists('home_surcharge', $validated) ? $validated['home_surcharge'] : $service->home_surcharge,
                        'duration_minutes'      => $validated['duration_minutes'] ?? $service->duration_minutes,
                        'buffer_time_minutes'   => $validated['buffer_time_minutes'] ?? $service->buffer_time_minutes,
                        'is_active'             => array_key_exists('is_active', $validated) ? $validated['is_active'] : $service->is_active,
                        'online_booking_enabled'=> array_key_exists('online_booking_enabled', $validated) ? $validated['online_booking_enabled'] : $service->online_booking_enabled,
                    ]
                );
            }
        } elseif (!empty($validated['branch_ids'])) {
            // Update / sync across selected branches
            $targetBranchIds = $allTenantBranches->whereIn('id', $validated['branch_ids'])->pluck('id');
            foreach ($targetBranchIds as $bId) {
                Service::updateOrCreate(
                    [
                        'branch_id' => $bId,
                        'name'      => ($bId === $service->branch_id) ? $newName : $oldName,
                    ],
                    [
                        'name'                  => $newName,
                        'description'           => array_key_exists('description', $validated) ? $validated['description'] : $service->description,
                        'category'              => $validated['category'] ?? $service->category,
                        'service_type'          => $validated['service_type'] ?? $service->service_type,
                        'price'                 => $validated['price'] ?? $service->price,
                        'home_surcharge'        => array_key_exists('home_surcharge', $validated) ? $validated['home_surcharge'] : $service->home_surcharge,
                        'duration_minutes'      => $validated['duration_minutes'] ?? $service->duration_minutes,
                        'buffer_time_minutes'   => $validated['buffer_time_minutes'] ?? $service->buffer_time_minutes,
                        'is_active'             => array_key_exists('is_active', $validated) ? $validated['is_active'] : $service->is_active,
                        'online_booking_enabled'=> array_key_exists('online_booking_enabled', $validated) ? $validated['online_booking_enabled'] : $service->online_booking_enabled,
                    ]
                );
            }
        } else {
            // Single service update
            $service->update($validated);
        }

        return response()->json([
            'success' => true, 
            'message' => 'Service updated successfully!', 
            'data'    => $service->fresh()->load('branch:id,name,city,pin_code')
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $service = Service::whereIn('branch_id', $branchIds)->findOrFail($id);
        $service->delete();
        
        return response()->json(['success' => true, 'message' => 'Service deleted']);
    }
}
