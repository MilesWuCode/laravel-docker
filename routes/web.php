<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

use App\Jobs\TestQueueJob;

Route::get('/test-queue', function () {
    dispatch(new TestQueueJob)
        ->onQueue('default') // queue name
        ->delay(10);

    return 'TestQueueJob dispatched! : '.now()->toDateTimeString();
});
