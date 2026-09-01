<?php
$content = file_get_contents('app/Http/Controllers/StaffController.php');

$methods = <<<'PHP'

    public function update(Request $request, $id)
    {
        $user = $request->user();
        $tenantId = $user->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');

        $staff = Staff::whereIn('branch_id', $branchIds)->findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'mobile' => 'nullable|string', // Validation without unique initially, we check manually
            'email' => 'nullable|email',
            'is_bookable' => 'boolean',
            'is_active' => 'boolean',
            'role' => 'string|in:STAFF,MANAGER',
        ]);

        DB::beginTransaction();
        try {
            if ($staff->user_id) {
                $staffUser = User::find($staff->user_id);
                if ($staffUser) {
                    if (isset($validated['email']) && $validated['email'] !== $staffUser->email) {
                        if (User::where('email', $validated['email'])->where('id', '!=', $staffUser->id)->exists()) {
                            return response()->json(['success' => false, 'message' => 'Email already in use.'], 422);
                        }
                        $staffUser->email = $validated['email'];
                    }
                    if (isset($validated['mobile']) && $validated['mobile'] !== $staffUser->mobile) {
                        if (User::where('mobile', $validated['mobile'])->where('id', '!=', $staffUser->id)->exists()) {
                            return response()->json(['success' => false, 'message' => 'Mobile already in use.'], 422);
                        }
                        $staffUser->mobile = $validated['mobile'];
                    }
                    if (isset($validated['name'])) {
                        $staffUser->name = $validated['name'];
                    }
                    $staffUser->save();

                    if (isset($validated['role'])) {
                        $staffUser->syncRoles([$validated['role']]);
                    }
                }
            }

            $staff->update($validated);
            DB::commit();

            return response()->json(['success' => true, 'message' => 'Staff updated successfully.', 'data' => $staff]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Update failed: ' . $e->getMessage()], 500);
        }
    }

    public function destroy(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $staff = Staff::whereIn('branch_id', $branchIds)->findOrFail($id);

        DB::beginTransaction();
        try {
            if ($staff->user_id) {
                User::where('id', $staff->user_id)->delete();
            }
            $staff->delete();
            
            DB::commit();
            return response()->json(['success' => true, 'message' => 'Staff deleted successfully.']);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['success' => false, 'message' => 'Failed to delete staff: ' . $e->getMessage()], 500);
        }
    }

    public function resetPassword(Request $request, $id)
    {
        $tenantId = $request->user()->tenant_id;
        $branchIds = Branch::where('tenant_id', $tenantId)->pluck('id');
        
        $staff = Staff::whereIn('branch_id', $branchIds)->findOrFail($id);

        $validated = $request->validate([
            'password' => 'required|string|min:8'
        ]);

        if (!$staff->user_id) {
            return response()->json(['success' => false, 'message' => 'This staff member does not have a login account.'], 400);
        }

        $staffUser = User::find($staff->user_id);
        if ($staffUser) {
            $staffUser->password = Hash::make($validated['password']);
            $staffUser->save();
            return response()->json(['success' => true, 'message' => 'Password reset successfully.']);
        }

        return response()->json(['success' => false, 'message' => 'Staff user not found.'], 404);
    }
PHP;

$content = preg_replace('/}\s*$/', $methods . "\n}\n", $content);
file_put_contents('app/Http/Controllers/StaffController.php', $content);
echo "StaffController patched.";
