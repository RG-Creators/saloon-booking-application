<?php

$controllers = [
    'TenantController' => <<<PHP
<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use App\Models\Tenant;
use Illuminate\Support\Facades\Auth;

class TenantController extends Controller {
    public function store(Request \$request) {
        \$validated = \$request->validate([
            'business_name' => 'required|string|max:255',
            'business_type' => 'nullable|string',
        ]);
        
        // Super Admin or initial registration logic
        \$tenant = Tenant::create(\$validated);
        
        // Link to user if registering
        if (Auth::check()) {
            \$user = Auth::user();
            \$user->tenant_id = \$tenant->id;
            \$user->assignRole('OWNER');
            \$user->save();
        }
        
        return response()->json(['success' => true, 'data' => \$tenant]);
    }

    public function show(\$id) {
        // Must implement policy: \$this->authorize('view', \$tenant);
        return response()->json(['success' => true, 'data' => Tenant::findOrFail(\$id)]);
    }
}
PHP,
    
    'BranchController' => <<<PHP
<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use App\Models\Branch;
use Illuminate\Support\Facades\Auth;

class BranchController extends Controller {
    public function index() {
        \$tenant_id = Auth::user()->tenant_id;
        return response()->json(['success' => true, 'data' => Branch::where('tenant_id', \$tenant_id)->get()]);
    }
    
    public function store(Request \$request) {
        \$tenant_id = Auth::user()->tenant_id;
        \$validated = \$request->validate([
            'name' => 'required|string',
            'address' => 'required|string',
            'city' => 'required|string',
        ]);
        \$validated['tenant_id'] = \$tenant_id;
        return response()->json(['success' => true, 'data' => Branch::create(\$validated)]);
    }
}
PHP,

    'ServiceController' => <<<PHP
<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use App\Models\Service;
use App\Models\Branch;
use Illuminate\Support\Facades\Auth;

class ServiceController extends Controller {
    public function index(Request \$request) {
        // Enforce tenant isolation via branch
        \$tenant_id = Auth::user()->tenant_id;
        \$branch_ids = Branch::where('tenant_id', \$tenant_id)->pluck('id');
        \$services = Service::whereIn('branch_id', \$branch_ids)->get();
        return response()->json(['success' => true, 'data' => \$services]);
    }
    
    public function store(Request \$request) {
        \$validated = \$request->validate([
            'branch_id' => 'required|exists:branches,id',
            'name' => 'required|string',
            'price' => 'required|numeric',
            'duration_minutes' => 'required|integer',
        ]);
        
        // Authorize branch belongs to user's tenant
        \$branch = Branch::where('id', \$validated['branch_id'])->where('tenant_id', Auth::user()->tenant_id)->firstOrFail();
        
        return response()->json(['success' => true, 'data' => Service::create(\$validated)]);
    }
}
PHP,

    'StaffController' => <<<PHP
<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use App\Models\Staff;
use App\Models\Branch;
use Illuminate\Support\Facades\Auth;

class StaffController extends Controller {
    public function index() {
        \$tenant_id = Auth::user()->tenant_id;
        \$branch_ids = Branch::where('tenant_id', \$tenant_id)->pluck('id');
        \$staff = Staff::whereIn('branch_id', \$branch_ids)->get();
        return response()->json(['success' => true, 'data' => \$staff]);
    }
}
PHP,

    'BookingController' => <<<PHP
<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class BookingController extends Controller {
    public function store(Request \$request) {
        // Complex availability engine logic goes here
        // 1. Lock slot
        // 2. Validate availability
        // 3. Initiate payment
        return response()->json(['success' => true, 'message' => 'Slot locked, pending payment']);
    }
}
PHP,

    'PaymentController' => <<<PHP
<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use App\Services\Payment\PaymentGatewayInterface;

class PaymentController extends Controller {
    protected \$paymentGateway;
    public function __construct(PaymentGatewayInterface \$paymentGateway) {
        \$this->paymentGateway = \$paymentGateway;
    }
    
    public function webhook(Request \$request) {
        if(\$this->paymentGateway->verifyPayment(\$request->all())) {
            // Confirm booking
            return response()->json(['success' => true]);
        }
        return response()->json(['success' => false], 400);
    }
}
PHP,

    'DiscoveryController' => <<<PHP
<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use App\Models\Branch;

class DiscoveryController extends Controller {
    public function nearby(Request \$request) {
        // Geospatial search logic placeholder
        // Returns active branches
        return response()->json(['success' => true, 'data' => Branch::limit(20)->get()]);
    }
}
PHP,
];

foreach (\$controllers as \$name => \$content) {
    file_put_contents(__DIR__ . "/app/Http/Controllers/{\$name}.php", \$content);
    echo "Created {\$name}\n";
}

// Generate API Routes
\$apiRoutes = <<<PHP
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TenantController;
use App\Http\Controllers\BranchController;
use App\Http\Controllers\ServiceController;
use App\Http\Controllers\StaffController;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\DiscoveryController;

// Public Customer Discovery
Route::get('/v1/discovery/nearby', [DiscoveryController::class, 'nearby']);
Route::post('/v1/payment/webhook', [PaymentController::class, 'webhook']);

// Protected Owner/Staff/Customer Routes
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    // Tenant Onboarding
    Route::post('/tenant', [TenantController::class, 'store']);
    Route::get('/tenant/{id}', [TenantController::class, 'show']);
    
    // Branches
    Route::apiResource('branches', BranchController::class);
    
    // Services
    Route::apiResource('services', ServiceController::class);
    
    // Staff
    Route::apiResource('staff', StaffController::class);
    
    // Bookings
    Route::post('/bookings', [BookingController::class, 'store']);
});
PHP;

file_put_contents(__DIR__ . "/routes/api.php", \$apiRoutes);
echo "Updated routes/api.php\n";

echo "Backend scaffolding complete.\n";
