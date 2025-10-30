// Firebase Cloud Messaging Service Worker
// Este arquivo é necessário para receber notificações push em background

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Configuração do Firebase
firebase.initializeApp({
  apiKey: "AIzaSyDUA312OYkAeEfmcQKybNq0KN53HEGHyTU",
  authDomain: "app-no-secreto-com-o-pai.firebaseapp.com",
  projectId: "app-no-secreto-com-o-pai",
  storageBucket: "app-no-secreto-com-o-pai.firebasestorage.app",
  messagingSenderId: "490614568896",
  appId: "1:490614568896:web:YOUR_WEB_APP_ID"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Nova notificação';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  // Open the app
  event.waitUntil(
    clients.openWindow('/')
  );
});
