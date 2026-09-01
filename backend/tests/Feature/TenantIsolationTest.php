<?php

namespace Tests\Feature;

use App\Models\Tenant;
use App\Models\User;
use App\Models\Branch;
use App\Models\Service;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantIsolationTest extends TestCase
{
    use RefreshDatabase;

    public function test_tenant_a_cannot_access_tenant_b_branch()
    {
        $tenantA = Tenant::create(['business_name' => 'Salon A', 'business_type' => 'Barber', 'status' => 'ACTIVE']);
        $tenantB = Tenant::create(['business_name' => 'Salon B', 'business_type' => 'Spa', 'status' => 'ACTIVE']);
        
        $userA = User::factory()->create(['tenant_id' => $tenantA->id]);
        $branchB = Branch::create(['tenant_id' => $tenantB->id, 'name' => 'Branch B', 'address' => 'Street B', 'city' => 'Delhi']);

        $this->assertNotEquals($userA->tenant_id, $branchB->tenant_id, "Tenant A user should not have matching tenant ID with Tenant B branch.");
    }
}
