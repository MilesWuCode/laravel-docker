<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// 每分鐘寫一個log
Schedule::call(function () {
    Log::info(now()->toDateTimeString().' - Scheduled task executed.');
})->everyMinute();
