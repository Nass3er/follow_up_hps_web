const CACHE_NAME = 'hps-app-v7';
const urlsToCache = [
    './',
    './index.html',
    './vitals.html',
    './intake_output.html',
    './doctor-orders.html',
    './login.html',
    './settings.html',
    './sync.html',
    './assets/css/style.css',
    './assets/css/login.css',
    './assets/css/dashboard.css',
    './assets/js/config.js',
    './assets/js/login.js',
    './assets/js/db.js',
    './assets/js/sync.js',
    './assets/js/vitals.js',
    './assets/js/intake_output.js',
    './assets/js/doctor_orders.js',
    './assets/js/settings.js',
    './icon.png'
];

self.addEventListener('install', event => {
    self.skipWaiting();
    event.waitUntil(
        caches.open(CACHE_NAME).then(cache => {
            console.log('SW: Pre-caching v7 (Resilient Installation)');
            return Promise.all(
                urlsToCache.map(url => {
                    return cache.add(url).catch(err => {
                        console.warn('SW: Non-critical pre-cache failed for:', url, err);
                    });
                })
            );
        })
    );
});

self.addEventListener('activate', event => {
    event.waitUntil(
        Promise.all([
            caches.keys().then(cacheNames => {
                return Promise.all(
                    cacheNames.map(cache => {
                        if (cache !== CACHE_NAME) {
                            console.log('SW: Deleting legacy cache:', cache);
                            return caches.delete(cache);
                        }
                    })
                );
            }),
            self.clients.claim()
        ])
    );
});

self.addEventListener('fetch', event => {
    if (event.request.method !== 'GET' || event.request.url.includes('/api/')) {
        return;
    }

    event.respondWith(
        caches.open(CACHE_NAME).then(cache => {
            return cache.match(event.request).then(cachedResponse => {
                const fetchPromise = fetch(event.request).then(networkResponse => {
                    if (networkResponse && networkResponse.status === 200) {
                        cache.put(event.request, networkResponse.clone());
                    }
                    return networkResponse;
                }).catch(() => {
                    // Critical: if we are completely offline and navigating to a page not in cache, never show "No Internet"
                    if (event.request.mode === 'navigate') {
                        return cache.match('./index.html') || cache.match('./login.html');
                    }
                    return null;
                });
                
                // Return cached data immediately if we have it, else wait for network
                return cachedResponse || fetchPromise;
            });
        })
    );
});
