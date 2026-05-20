<?php

use App\Jobs\TestQueueJob;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test-queue', function () {
    dispatch(new TestQueueJob)
        ->onQueue('default') // queue name
        ->delay(10);

    return 'TestQueueJob dispatched! : '.now()->toDateTimeString();
});
