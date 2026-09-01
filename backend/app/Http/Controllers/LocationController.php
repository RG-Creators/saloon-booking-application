<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use App\Models\UserLocationLog;

class LocationController extends Controller
{
    public function detect(Request $request)
    {
        $apiKey = config('services.ipgeolocation.key');
        if (!$apiKey) {
            return response()->json(['success' => false, 'message' => 'API Key not configured'], 500);
        }

        $ip = $request->ip();
        // If testing on localhost, you can optionally pass an IP for testing, or we just rely on the API to auto-detect the router's public IP
        // ipgeolocation API will use the requester's IP if the `ip` parameter is omitted.
        
        $url = "https://api.ipgeolocation.io/v3/ipgeo?apiKey={$apiKey}";
        
        // If the client IP is public, pass it along
        if (!in_array($ip, ['127.0.0.1', '::1']) && !str_starts_with($ip, '192.168.') && !str_starts_with($ip, '10.')) {
            $url .= "&ip={$ip}";
        }

        try {
            $response = Http::timeout(10)->get($url);
            
            if ($response->successful()) {
                $data = $response->json();
                
                // Extract relevant data from the nested "location" object (v3 API)
                $city = $data['location']['city'] ?? null;
                $state = $data['location']['state_prov'] ?? null;
                $country = $data['location']['country_name'] ?? null;
                $zipcode = $data['location']['zipcode'] ?? null;
                $lat = $request->input('lat') ?? $data['location']['latitude'] ?? null;
                $lng = $request->input('lng') ?? $data['location']['longitude'] ?? null;
                $isp = $data['asn']['organization'] ?? $data['company']['name'] ?? null;
                
                // If user is logged in, track it, otherwise just return
                if ($request->user()) {
                    UserLocationLog::create([
                        'user_id' => $request->user()->id,
                        'event_type' => 'location_detect',
                        'ip_address' => $ip,
                        'city' => $city,
                        'state' => $state,
                        'country' => $country,
                        'zipcode' => $zipcode,
                        'latitude' => $lat,
                        'longitude' => $lng,
                        'isp' => $isp,
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'data' => [
                        'city' => $city,
                        'state' => $state,
                        'country' => $country,
                        'zipcode' => $zipcode,
                        'latitude' => $lat,
                        'longitude' => $lng,
                        'address' => trim("{$city}, {$state}, {$country}", ', '),
                    ]
                ]);
            } else {
                Log::error('IPGeolocation API Error', ['response' => $response->body()]);
                return response()->json(['success' => false, 'message' => 'Failed to fetch location from API'], 500);
            }
        } catch (\Exception $e) {
            Log::error('IPGeolocation Request Exception: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Exception occurred during location detection'], 500);
        }
    }
}
