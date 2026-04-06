const CACHE_NAME = 'hps-app-v3'; // Version incremented for update detection
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
    './assets/js/config.js',
    './assets/js/login.js',
    './assets/js/db.js',
    './assets/js/sync.js',
    './assets/js/vitals.js',
    './assets/js/intake_output.js',
    './assets/js/doctor_orders.js',
    './assets/js/settings.js',
    './icon.png',
    'https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700&display=swap'
];

// Install Event: Cache essential assets
self.addEventListener('install', event => {
    self.skipWaiting(); // Force the waiting service worker to become the active service worker
    event.waitUntil(
        caches.open(CACHE_NAME).then(cache => {
            console.log('SW: Pre-caching v3');
            return cache.addAll(urlsToCache);
        })
    );
});

// Activate Event: Clear old caches and take control
self.addEventListener('activate', event => {
    event.waitUntil(
        Promise.all([
            caches.keys().then(cacheNames => {
                return Promise.all(
                    cacheNames.map(cache => {
                        if (cache !== CACHE_NAME) {
                            console.log('SW: Deleting old cache:', cache);
                            return caches.delete(cache);
                        }
                    })
                );
            }),
            self.clients.claim() // Immediately take control of all open clients
        ])
    );
});

// Fetch Event: Stale-while-revalidate for assets, network-first for others (optional strategy)
self.addEventListener('fetch', event => {
    // Only handle GET requests and avoid API calls
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
                    // Fail silently or handle fallback
                });
                return cachedResponse || fetchPromise;
            });
        })
    );
});
