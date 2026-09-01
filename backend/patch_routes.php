<?php
$content = file_get_contents('routes/api.php');
$content = str_replace(
    "Route::apiResource('staff', StaffController::class);",
    "Route::apiResource('staff', StaffController::class);\n        Route::post('/staff/{id}/reset-password', [StaffController::class, 'resetPassword']);",
    $content
);
file_put_contents('routes/api.php', $content);
echo "Routes patched.";
