<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;

class LocationProxyController extends Controller
{
    public function states()
    {
        $data = Cache::remember('location_states_india_v3', 86400, function () {
            try {
                $response = Http::withoutVerifying()->timeout(10)->post('https://countriesnow.space/api/v0.1/countries/states', [
                    'country' => 'India'
                ]);
                
                if ($response->successful()) {
                    $apiData = $response->json();
                    $statesList = $apiData['data']['states'] ?? [];
                    return array_map(function($e) { return (string) $e['name']; }, $statesList);
                }
                \Log::error('States API failed: ' . $response->body());
            } catch (\Exception $e) {
                \Log::error('States API exception: ' . $e->getMessage());
            }
            
            // Fallback
            return ['Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu', 'Gujarat', 'West Bengal'];
        });

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function cities($state)
    {
        $data = Cache::remember('location_cities_india_' . md5($state), 86400, function () use ($state) {
            try {
                $response = Http::withoutVerifying()->timeout(10)->post('https://countriesnow.space/api/v0.1/countries/state/cities', [
                    'country' => 'India',
                    'state' => $state
                ]);
                
                if ($response->successful()) {
                    $apiData = $response->json();
                    return $apiData['data'] ?? [];
                }
            } catch (\Exception $e) {}
            
            return ['Mumbai', 'Delhi', 'Bangalore'];
        });

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function pincode($city)
    {
        $data = Cache::remember('location_pincode_india_' . md5($city), 86400, function () use ($city) {
            try {
                $response = Http::withoutVerifying()->timeout(10)->get('https://api.postalpincode.in/postoffice/' . urlencode($city));
                
                if ($response->successful()) {
                    $apiData = $response->json();
                    if (!empty($apiData) && ($apiData[0]['Status'] ?? '') === 'Success') {
                        $postOffice = $apiData[0]['PostOffice'] ?? [];
                        if (!empty($postOffice) && isset($postOffice[0]['Pincode'])) {
                            return $postOffice[0]['Pincode'];
                        }
                    }
                }
            } catch (\Exception $e) {}
            
            return null;
        });

        if ($data !== null) {
            return response()->json(['success' => true, 'data' => $data]);
        }
        return response()->json(['success' => false]);
    }
}
