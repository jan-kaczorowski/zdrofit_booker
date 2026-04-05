// Minimal service worker for PWA installability
// Caches app shell assets for faster loads

const CACHE_NAME = "zdrofit-v1"
const SHELL_ASSETS = ["/icon.png", "/icon.svg"]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(SHELL_ASSETS))
  )
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  )
  self.clients.claim()
})

self.addEventListener("fetch", (event) => {
  // Network-first strategy: always try network, fall back to cache
  if (event.request.method !== "GET") return

  event.respondWith(
    fetch(event.request).catch(() => caches.match(event.request))
  )
})
