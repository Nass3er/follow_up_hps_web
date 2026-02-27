const CACHE_NAME = 'hps-app-v1';
const urlsToCache = [
    '/',
    '/index.html',
    '/vitals.html',
    '/login.html',
    '/assets/css/style.css',
    '/assets/css/login.css',
    '/assets/css/dashboard.css',
    '/assets/js/config.js',
    '/assets/js/login.js',
    '/assets/js/db.js',
    '/assets/js/sync.js',
    '/assets/js/vitals.js',
    '/icon.png'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                return cache.addAll(urlsToCache);
            })
    );
});

self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                if (response) {
                    return response; // Return from cache if found
                }
                return fetch(event.request).catch(() => {
                    // Ignore network errors returning empty responses, this simple SW is just to please PWA Builder
                });
            })
    );
});
