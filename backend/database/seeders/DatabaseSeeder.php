<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Tenant;
use App\Models\Branch;
use App\Models\Service;
use App\Models\Staff;
use App\Models\Booking;
use App\Models\TenantLedger;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // Permissions
        $perms = [
            'manage shops',
            'manage users',
            'manage subadmins',
            'send notifications',
            'view audit logs',
            'manage billing',
            'manage settings',
        ];

        foreach ($perms as $perm) {
            Permission::firstOrCreate(['name' => $perm]);
        }

        // Roles
        $superAdmin = Role::firstOrCreate(['name' => 'SUPER_ADMIN']);
        $subAdmin = Role::firstOrCreate(['name' => 'SUBADMIN']);
        $owner = Role::firstOrCreate(['name' => 'OWNER']);
        $staffRole = Role::firstOrCreate(['name' => 'STAFF']);
        $customer = Role::firstOrCreate(['name' => 'CUSTOMER']);

        $superAdmin->givePermissionTo(Permission::all());

        // 1. Super Admin User
        $adminUser = User::firstOrCreate(
            ['email' => 'ronitgoswami453@gmail.com'],
            [
                'name' => 'Ronit Goswami',
                'password' => bcrypt('Password@2426'),
            ]
        );
        $adminUser->assignRole($superAdmin);

        // 2. Subadmin User
        $subUser = User::firstOrCreate(
            ['email' => 'subadmin@glamora.com'],
            [
                'name' => 'Support Admin',
                'password' => bcrypt('password'),
            ]
        );
        $subUser->assignRole($subAdmin);
        $subUser->givePermissionTo(['manage shops', 'manage users']);

        // 3. Common Customer Account
        $custUser = User::firstOrCreate(
            ['email' => 'customer@glamora.com'],
            [
                'name' => 'Rahul Verma',
                'mobile' => '9811122233',
                'password' => bcrypt('password'),
                'city' => 'Mumbai',
                'pin_code' => '400001',
            ]
        );
        $custUser->assignRole($customer);

        // --- SHOP 1: Royal Grooming Studio (Mumbai) ---
        $t1 = Tenant::firstOrCreate(
            ['business_name' => 'Royal Grooming Studio'],
            [
                'business_type' => 'Barber & Men\'s Grooming',
                'status' => 'VERIFIED',
                'booking_policy' => 'PAY_AT_SALON',
                'verification_image' => 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=600&q=80',
            ]
        );

        $o1 = User::firstOrCreate(
            ['email' => 'owner@glamora.com'],
            [
                'name' => 'Vikram Sharma',
                'mobile' => '9812345678',
                'tenant_id' => $t1->id,
                'password' => bcrypt('password'),
                'city' => 'Mumbai',
                'pin_code' => '400001',
            ]
        );
        $o1->assignRole($owner);

        $b1 = Branch::firstOrCreate(
            ['tenant_id' => $t1->id, 'name' => 'Royal Grooming Studio - Bandra'],
            [
                'address' => 'Linking Road, Bandra West',
                'city' => 'Mumbai',
                'state' => 'Maharashtra',
                'pin_code' => '400050',
                'contact_mobile' => '9812345678',
            ]
        );

        $s1_1 = Service::firstOrCreate(['branch_id' => $b1->id, 'name' => 'Signature Haircut & Wash'], ['category' => 'Haircut', 'duration_minutes' => 35, 'price' => 499.00, 'is_active' => true]);
        $s1_2 = Service::firstOrCreate(['branch_id' => $b1->id, 'name' => 'Beard Trim & Hot Towel Shave'], ['category' => 'Beard', 'duration_minutes' => 25, 'price' => 299.00, 'is_active' => true]);
        $s1_3 = Service::firstOrCreate(['branch_id' => $b1->id, 'name' => 'Royal Charcoal Facial'], ['category' => 'Facial', 'duration_minutes' => 45, 'price' => 899.00, 'is_active' => true]);

        $st1_1 = Staff::firstOrCreate(['branch_id' => $b1->id, 'name' => 'Master Vikram'], ['role' => 'Master Barber', 'mobile' => '9812345678', 'is_active' => true]);
        $st1_2 = Staff::firstOrCreate(['branch_id' => $b1->id, 'name' => 'Priya Stylist'], ['role' => 'Senior Hair Colourist', 'mobile' => '9876543210', 'is_active' => true]);

        $bk1 = Booking::firstOrCreate(
            ['tenant_id' => $t1->id, 'start_time' => '11:00:00', 'booking_date' => now()->toDateString()],
            [
                'branch_id' => $b1->id, 'service_id' => $s1_1->id, 'staff_id' => $st1_1->id, 'user_id' => $custUser->id,
                'end_time' => '11:35:00', 'amount' => 499.00, 'status' => 'CONFIRMED'
            ]
        );

        TenantLedger::firstOrCreate(
            ['booking_id' => $bk1->id],
            ['tenant_id' => $t1->id, 'amount' => 1.00, 'type' => 'DEBIT', 'description' => 'Bookify Commission Fee', 'status' => 'PENDING']
        );


        // --- SHOP 2: Glamora Beauty & Unisex Salon (Delhi NCR) ---
        $t2 = Tenant::firstOrCreate(
            ['business_name' => 'Glamora Beauty & Unisex Salon'],
            [
                'business_type' => 'Unisex Beauty & Hair Salon',
                'status' => 'VERIFIED',
                'booking_policy' => 'PAY_AT_SALON',
                'verification_image' => 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=600&q=80',
            ]
        );

        $o2 = User::firstOrCreate(
            ['email' => 'owner2@glamora.com'],
            [
                'name' => 'Ananya Roy',
                'mobile' => '9876512345',
                'tenant_id' => $t2->id,
                'password' => bcrypt('password'),
                'city' => 'New Delhi',
                'pin_code' => '110001',
            ]
        );
        $o2->assignRole($owner);

        $b2 = Branch::firstOrCreate(
            ['tenant_id' => $t2->id, 'name' => 'Glamora Salon - Connaught Place'],
            [
                'address' => 'Block C, Connaught Place',
                'city' => 'New Delhi',
                'state' => 'Delhi NCR',
                'pin_code' => '110001',
                'contact_mobile' => '9876512345',
            ]
        );

        $s2_1 = Service::firstOrCreate(['branch_id' => $b2->id, 'name' => 'Global Hair Spa & Wash'], ['category' => 'Hair Spa', 'duration_minutes' => 50, 'price' => 1299.00, 'is_active' => true]);
        $s2_2 = Service::firstOrCreate(['branch_id' => $b2->id, 'name' => 'O3+ Bridal Glow Facial'], ['category' => 'Skin Care', 'duration_minutes' => 60, 'price' => 2499.00, 'is_active' => true]);

        Staff::firstOrCreate(['branch_id' => $b2->id, 'name' => 'Rohan Kapoor'], ['role' => 'Senior Hair Expert', 'mobile' => '9988776655', 'is_active' => true]);


        // --- SHOP 3: The Velvet Cut & Spa (Bengaluru) ---
        $t3 = Tenant::firstOrCreate(
            ['business_name' => 'The Velvet Cut & Spa'],
            [
                'business_type' => 'Premium Grooming & Spa',
                'status' => 'VERIFIED',
                'booking_policy' => 'PREPAYMENT_REQUIRED_ALL',
                'verification_image' => 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80',
            ]
        );

        $o3 = User::firstOrCreate(
            ['email' => 'owner3@glamora.com'],
            [
                'name' => 'Karan Kapoor',
                'mobile' => '9988766554',
                'tenant_id' => $t3->id,
                'password' => bcrypt('password'),
                'city' => 'Bengaluru',
                'pin_code' => '560001',
            ]
        );
        $o3->assignRole($owner);

        $b3 = Branch::firstOrCreate(
            ['tenant_id' => $t3->id, 'name' => 'Velvet Cut - Indiranagar'],
            [
                'address' => '100 Feet Road, Indiranagar',
                'city' => 'Bengaluru',
                'state' => 'Karnataka',
                'pin_code' => '560038',
                'contact_mobile' => '9988766554',
            ]
        );

        Service::firstOrCreate(['branch_id' => $b3->id, 'name' => 'Gentlemen Executive Cut & Head Massage'], ['category' => 'Haircut', 'duration_minutes' => 45, 'price' => 799.00, 'is_active' => true]);
        Service::firstOrCreate(['branch_id' => $b3->id, 'name' => 'Swedish Full Body Therapy (60 Mins)'], ['category' => 'Spa', 'duration_minutes' => 60, 'price' => 2999.00, 'is_active' => true]);

        Staff::firstOrCreate(['branch_id' => $b3->id, 'name' => 'Simran Kaur'], ['role' => 'Therapist & Stylist', 'mobile' => '9911223344', 'is_active' => true]);


        // --- SHOP 4: Luxe Style Lounge (Pune) ---
        $t4 = Tenant::firstOrCreate(
            ['business_name' => 'Luxe Style Lounge'],
            [
                'business_type' => 'Luxury Hair & Makeup Studio',
                'status' => 'VERIFIED',
                'booking_policy' => 'PAY_AT_SALON',
                'verification_image' => 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=600&q=80',
            ]
        );

        $o4 = User::firstOrCreate(
            ['email' => 'owner4@glamora.com'],
            [
                'name' => 'Neha Sharma',
                'mobile' => '9123456789',
                'tenant_id' => $t4->id,
                'password' => bcrypt('password'),
                'city' => 'Pune',
                'pin_code' => '411001',
            ]
        );
        $o4->assignRole($owner);

        $b4 = Branch::firstOrCreate(
            ['tenant_id' => $t4->id, 'name' => 'Luxe Lounge - Koregaon Park'],
            [
                'address' => 'Lane 7, Koregaon Park',
                'city' => 'Pune',
                'state' => 'Maharashtra',
                'pin_code' => '411001',
                'contact_mobile' => '9123456789',
            ]
        );

        Service::firstOrCreate(['branch_id' => $b4->id, 'name' => 'Balayage & Olaplex Treatment'], ['category' => 'Hair Colour', 'duration_minutes' => 120, 'price' => 4999.00, 'is_active' => true]);
        Service::firstOrCreate(['branch_id' => $b4->id, 'name' => 'Keratin Smoothening'], ['category' => 'Hair Care', 'duration_minutes' => 90, 'price' => 3999.00, 'is_active' => true]);

        Staff::firstOrCreate(['branch_id' => $b4->id, 'name' => 'Siddharth Rao'], ['role' => 'Senior Hairdresser', 'mobile' => '9822334455', 'is_active' => true]);
    }
}
