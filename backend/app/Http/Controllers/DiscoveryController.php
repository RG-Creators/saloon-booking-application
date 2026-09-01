<?php

namespace App\Http\Controllers;

use App\Models\Tenant;
use App\Models\Branch;
use App\Models\Service;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DiscoveryController extends Controller
{
    /**
     * Helper: Compute approximate distance between two GPS coordinates (in km).
     */
    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        if (empty($lat1) || empty($lon1) || empty($lat2) || empty($lon2)) {
            return null;
        }

        $earthRadius = 6371; // Earth radius in km
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return round($earthRadius * $c, 1);
    }

    /**
     * Helper: Format live store status badge and description.
     */
    private function formatStoreStatus($tenant, $workingHours)
    {
        // 1. Emergency or Paused Mode
        if (in_array($tenant->status, ['EMERGENCY_CLOSED', 'OFFLINE', 'SUSPENDED_FOR_DELETION'])) {
            return [
                'is_open' => false,
                'status_code' => 'PAUSED',
                'status_label' => 'Temporarily Paused',
                'status_color' => '#DC2626',
                'status_subtitle' => 'Bookings paused by salon owner',
            ];
        }

        $now = Carbon::now('Asia/Kolkata');
        $todayDayOfWeek = $now->dayOfWeek; // 0 = Sunday, 1 = Monday ... 6 = Saturday
        $tomorrowDayOfWeek = ($todayDayOfWeek + 1) % 7;

        $todayHours = $workingHours->firstWhere('day_of_week', $todayDayOfWeek);
        $tomorrowHours = $workingHours->firstWhere('day_of_week', $tomorrowDayOfWeek);

        // Check if closed today
        if (!$todayHours || !$todayHours->is_open || empty($todayHours->open_time) || empty($todayHours->close_time)) {
            $tomorrowText = ($tomorrowHours && $tomorrowHours->is_open && !empty($tomorrowHours->open_time))
                ? 'Opens tomorrow ' . Carbon::parse($tomorrowHours->open_time)->format('h:i A')
                : 'Closed tomorrow';

            return [
                'is_open' => false,
                'status_code' => 'CLOSED_TODAY',
                'status_label' => 'Closed Today',
                'status_color' => '#D97706',
                'status_subtitle' => $tomorrowText,
            ];
        }

        $openTime = Carbon::parse($todayHours->open_time, 'Asia/Kolkata');
        $closeTime = Carbon::parse($todayHours->close_time, 'Asia/Kolkata');
        $currentTime = Carbon::parse($now->format('H:i:s'), 'Asia/Kolkata');

        if ($currentTime->lt($openTime)) {
            return [
                'is_open' => false,
                'status_code' => 'OPENS_LATER_TODAY',
                'status_label' => 'Closed',
                'status_color' => '#D97706',
                'status_subtitle' => 'Opens at ' . $openTime->format('h:i A') . ' today',
            ];
        }

        if ($currentTime->gte($openTime) && $currentTime->lt($closeTime)) {
            return [
                'is_open' => true,
                'status_code' => 'OPEN_NOW',
                'status_label' => 'Open Now',
                'status_color' => '#059669',
                'status_subtitle' => 'Closes at ' . $closeTime->format('h:i A'),
            ];
        }

        // Past close time today
        $tomorrowText = ($tomorrowHours && $tomorrowHours->is_open && !empty($tomorrowHours->open_time))
            ? 'Opens tomorrow at ' . Carbon::parse($tomorrowHours->open_time)->format('h:i A')
            : 'Closed tomorrow';

        return [
            'is_open' => false,
            'status_code' => 'CLOSED_FOR_DAY',
            'status_label' => 'Closed',
            'status_color' => '#64748B',
            'status_subtitle' => $tomorrowText,
        ];
    }

    /**
     * Get nearby active salon branches with distance and live statuses.
     */
    public function nearby(Request $request)
    {
        $city = $request->query('city', 'New Delhi');
        $userLat = $request->query('lat') ? (float)$request->query('lat') : null;
        $userLng = $request->query('lng') ? (float)$request->query('lng') : null;
        $category = $request->query('category', '');

        $query = Branch::whereHas('tenant', function ($q) {
                $q->whereNotIn('status', ['SUSPENDED', 'REJECTED', 'SUSPENDED_FOR_DELETION']);
            })
            ->where('is_active', true)
            ->with(['tenant', 'workingHours', 'services' => function ($q) {
                $q->where('is_active', true);
            }, 'combos' => function ($q) {
                $q->where('is_active', true);
            }]);

        if (!empty($city)) {
            $query->where(function ($q) use ($city) {
                $q->where('city', 'LIKE', "%{$city}%")
                  ->orWhere('address', 'LIKE', "%{$city}%");
            });
        }

        $branches = $query->get();

        $formatted = $branches->map(function ($branch) use ($userLat, $userLng) {
            $tenant = $branch->tenant;
            $distanceKm = $this->calculateDistance($userLat, $userLng, (float)$branch->latitude, (float)$branch->longitude);
            $status = $this->formatStoreStatus($tenant, $branch->workingHours);

            $distanceText = $distanceKm !== null
                ? ($distanceKm < 1.0 ? 'Within ' . round($distanceKm * 1000) . ' m' : "Within {$distanceKm} km")
                : 'Within your area (' . ($branch->city ?? 'Local') . ')';

            $servicesCount = $branch->services->count();
            $combosCount = $branch->combos->count();
            $minPrice = $branch->services->min('price') ?? 150.00;

            return [
                'id' => $branch->id,
                'tenant_id' => $branch->tenant_id,
                'name' => $branch->name,
                'business_name' => $tenant->business_name,
                'business_type' => $tenant->business_type ?? 'Grooming & Salon',
                'address' => $branch->address,
                'city' => $branch->city,
                'state' => $branch->state,
                'pin_code' => $branch->pin_code,
                'latitude' => (float)$branch->latitude,
                'longitude' => (float)$branch->longitude,
                'contact_mobile' => $branch->contact_mobile,
                'contact_email' => $branch->contact_email,
                'rating' => 4.9,
                'reviews_count' => 128,
                'distance_km' => $distanceKm,
                'distance_text' => $distanceText,
                'status' => $status,
                'pricing' => [
                    'min_price' => (float)$minPrice,
                    'starting_from_text' => "Starts ₹{$minPrice}",
                    'services_count' => $servicesCount,
                    'combos_count' => $combosCount,
                ],
                'features' => [
                    'home_service_enabled' => (bool)$tenant->home_service_enabled,
                    'event_wedding_enabled' => (bool)$tenant->event_wedding_enabled,
                    'home_service_radius_km' => (int)$tenant->home_service_radius_km,
                    'home_service_travel_fee' => (float)$tenant->home_service_travel_fee,
                    'event_min_booking_amount' => (float)$tenant->event_min_booking_amount,
                    'booking_policy' => $tenant->booking_policy ?? 'PAY_AT_SALON',
                    'cancellation_buffer_minutes' => (int)($tenant->cancellation_buffer_minutes ?? 120),
                    'prebooking_token_amount' => (float)($tenant->prebooking_token_amount ?? 50.00),
                    'crm_only_booking' => (bool)$tenant->crm_only_booking,
                ],
                'working_hours' => $branch->workingHours,
            ];
        });

        // Location priority: Sort closest branches first if user coordinates provided
        if ($userLat !== null && $userLng !== null) {
            $formatted = $formatted->sortBy(function ($item) {
                return $item['distance_km'] ?? 999999;
            })->values();
        }

        return response()->json([
            'success' => true,
            'count' => $formatted->count(),
            'data' => $formatted
        ]);
    }

    /**
     * Search salons by query string.
     */
    public function search(Request $request)
    {
        $query = $request->query('q', '');
        $userLat = $request->query('lat') ? (float)$request->query('lat') : null;
        $userLng = $request->query('lng') ? (float)$request->query('lng') : null;

        $branches = Branch::whereHas('tenant', function ($t) use ($query) {
                $t->whereNotIn('status', ['SUSPENDED', 'REJECTED', 'SUSPENDED_FOR_DELETION'])
                  ->where(function ($q) use ($query) {
                      $q->where('business_name', 'LIKE', "%{$query}%")
                        ->orWhere('business_type', 'LIKE', "%{$query}%");
                  });
            })
            ->orWhere('name', 'LIKE', "%{$query}%")
            ->orWhere('city', 'LIKE', "%{$query}%")
            ->orWhere('address', 'LIKE', "%{$query}%")
            ->where('is_active', true)
            ->with(['tenant', 'workingHours', 'services' => function ($q) {
                $q->where('is_active', true);
            }])
            ->get();

        $formatted = $branches->map(function ($branch) use ($userLat, $userLng) {
            $tenant = $branch->tenant;
            $distanceKm = $this->calculateDistance($userLat, $userLng, (float)$branch->latitude, (float)$branch->longitude);
            $status = $this->formatStoreStatus($tenant, $branch->workingHours);

            return [
                'id' => $branch->id,
                'tenant_id' => $branch->tenant_id,
                'name' => $branch->name,
                'business_name' => $tenant->business_name,
                'business_type' => $tenant->business_type ?? 'Grooming & Salon',
                'address' => $branch->address,
                'city' => $branch->city,
                'distance_km' => $distanceKm,
                'distance_text' => $distanceKm !== null ? "Within {$distanceKm} km" : 'Within your area',
                'status' => $status,
                'rating' => 4.9,
                'features' => [
                    'home_service_enabled' => (bool)$tenant->home_service_enabled,
                    'event_wedding_enabled' => (bool)$tenant->event_wedding_enabled,
                    'booking_policy' => $tenant->booking_policy ?? 'PAY_AT_SALON',
                ],
            ];
        });

        return response()->json([
            'success' => true,
            'count' => $formatted->count(),
            'data' => $formatted
        ]);
    }

    /**
     * Get details of a specific salon branch.
     */
    public function shopDetails($id)
    {
        $branch = Branch::where('id', $id)
            ->orWhere('tenant_id', $id)
            ->whereHas('tenant', function ($q) {
                $q->whereNotIn('status', ['SUSPENDED', 'REJECTED', 'SUSPENDED_FOR_DELETION']);
            })
            ->with([
                'tenant',
                'workingHours',
                'services' => function ($q) { $q->where('is_active', true); },
                'combos' => function ($q) { $q->where('is_active', true); },
                'staff' => function ($q) { $q->where('is_active', true)->where('is_bookable', true); },
            ])
            ->first();

        if (!$branch) {
            return response()->json(['success' => false, 'message' => 'Salon branch not found.'], 404);
        }

        $tenant = $branch->tenant;
        $status = $this->formatStoreStatus($tenant, $branch->workingHours);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $branch->id,
                'tenant_id' => $tenant->id,
                'name' => $branch->name,
                'business_name' => $tenant->business_name,
                'business_type' => $tenant->business_type,
                'description' => $tenant->description ?? 'Premium salon offering hair styling, skincare, spa, and beauty treatments.',
                'address' => $branch->address,
                'city' => $branch->city,
                'state' => $branch->state,
                'pin_code' => $branch->pin_code,
                'contact_mobile' => $branch->contact_mobile,
                'contact_email' => $branch->contact_email,
                'rating' => 4.9,
                'reviews_count' => 128,
                'status' => $status,
                'policies' => [
                    'booking_policy' => $tenant->booking_policy ?? 'PAY_AT_SALON',
                    'cancellation_buffer_minutes' => (int)($tenant->cancellation_buffer_minutes ?? 120),
                    'cancellation_text' => 'Free cancellation up to ' . (($tenant->cancellation_buffer_minutes ?? 120) >= 60 ? (($tenant->cancellation_buffer_minutes ?? 120) / 60) . ' hour(s)' : ($tenant->cancellation_buffer_minutes ?? 120) . ' mins') . ' before appointment.',
                    'prebooking_token_amount' => (float)($tenant->prebooking_token_amount ?? 50.00),
                    'crm_only_booking' => (bool)$tenant->crm_only_booking,
                    'home_service_enabled' => (bool)$tenant->home_service_enabled,
                    'event_wedding_enabled' => (bool)$tenant->event_wedding_enabled,
                    'home_service_radius_km' => (int)$tenant->home_service_radius_km,
                    'home_service_travel_fee' => (float)$tenant->home_service_travel_fee,
                    'event_min_booking_amount' => (float)$tenant->event_min_booking_amount,
                    'home_service_notes' => $tenant->home_service_notes ?? '',
                ],
                'working_hours' => $branch->workingHours,
                'services' => $branch->services,
                'combos' => $branch->combos,
                'staff' => $branch->staff,
            ]
        ]);
    }

    /**
     * Get services offered by a salon.
     */
    public function services($id)
    {
        $services = Service::where(function ($q) use ($id) {
                $q->where('branch_id', $id)
                  ->orWhereHas('branch', function ($b) use ($id) {
                      $b->where('tenant_id', $id);
                  });
            })
            ->where('is_active', true)
            ->get();

        return response()->json([
            'success' => true,
            'count' => $services->count(),
            'data' => $services
        ]);
    }
}

