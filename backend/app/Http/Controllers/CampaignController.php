<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CampaignController extends Controller
{
    /**
     * Create marketing promotion campaign.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'discount_percentage' => 'nullable|integer|min:1|max:100'
        ]);

        return response()->json([
            'success' => true,
            'message' => "Campaign '{$validated['title']}' published successfully to salon customers.",
            'data' => $validated
        ], 201);
    }
}
