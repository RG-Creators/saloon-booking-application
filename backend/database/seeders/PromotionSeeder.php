<?php

namespace Database\Seeders;

use App\Models\OffPeakDiscount;
use App\Models\RushPricingRule;
use App\Models\Tenant;
use Illuminate\Database\Seeder;

class PromotionSeeder extends Seeder
{
    public function run(): void
    {
        $tenants = Tenant::all();
        if ($tenants->isEmpty()) {
            return;
        }

        foreach ($tenants as $tenant) {
            $tenantId = $tenant->id;

            if (OffPeakDiscount::where('tenant_id', $tenantId)->count() === 0) {
                OffPeakDiscount::create([
                    'tenant_id'        => $tenantId,
                    'title'            => 'Afternoon Happy Hour (2 PM - 4 PM)',
                    'discount_percent' => 20,
                    'days_of_week'     => [1, 2, 3, 4],
                    'start_time'       => '14:00:00',
                    'end_time'         => '16:00:00',
                    'time_window'      => 'Mon, Tue, Wed, Thu • 02:00 PM to 04:00 PM',
                    'is_active'        => true,
                ]);

                OffPeakDiscount::create([
                    'tenant_id'        => $tenantId,
                    'title'            => 'Early Bird Morning Special (10 AM - 11:30 AM)',
                    'discount_percent' => 15,
                    'days_of_week'     => [2, 3, 4, 5],
                    'start_time'       => '10:00:00',
                    'end_time'         => '11:30:00',
                    'time_window'      => 'Tue, Wed, Thu, Fri • 10:00 AM to 11:30 AM',
                    'is_active'        => false,
                ]);
            }

            if (RushPricingRule::where('tenant_id', $tenantId)->count() === 0) {
                RushPricingRule::create([
                    'tenant_id'    => $tenantId,
                    'title'        => 'Weekend Peak Hours Surge (4 PM - 8 PM)',
                    'surge_amount' => 100,
                    'days_of_week' => [0, 6],
                    'start_time'   => '16:00:00',
                    'end_time'     => '20:00:00',
                    'time_slot'    => 'Sat, Sun • 04:00 PM to 08:00 PM',
                    'is_enabled'   => true,
                ]);

                RushPricingRule::create([
                    'tenant_id'    => $tenantId,
                    'title'        => 'Evening Festival Prime Rush (6 PM - 9 PM)',
                    'surge_amount' => 150,
                    'days_of_week' => [0, 1, 2, 3, 4, 5, 6],
                    'start_time'   => '18:00:00',
                    'end_time'     => '21:00:00',
                    'time_slot'    => 'Everyday • 06:00 PM to 09:00 PM',
                    'is_enabled'   => false,
                ]);
            }
        }
    }
}
