const CACHE_NAME = 'quran-huffaz-v1';
const CORE_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './assets/app_icon.png',
  './assets/flipsound.mp3',
  './data/surahs.json',
  './data/juz.json',
  './data/page_map.json'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(CORE_ASSETS).catch(err => console.log('Cache pre-fetch error:', err));
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // If fetching page images, use cache-first strategy with runtime caching
  if (url.pathname.includes('/pages/page_') || url.pathname.includes('/data/surahs/')) {
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((cachedResponse) => {
          if (cachedResponse) return cachedResponse;
          return fetch(event.request).then((networkResponse) => {
            if (networkResponse && networkResponse.status === 200) {
              cache.put(event.request, networkResponse.clone());
            }
            return networkResponse;
          }).catch(() => cachedResponse);
        });
      })
    );
    return;
  }

  // Default network-first or cache fallback for core assets
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request).then((networkResponse) => {
        return networkResponse;
      }).catch(() => response);
    })
  );
});
