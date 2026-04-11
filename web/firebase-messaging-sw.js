importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDsvPXJ6ndekXerqIUgMXN7YNtX06MG6jc",
  authDomain: "myrwa-india.firebaseapp.com",
  projectId: "myrwa-india",
  storageBucket: "myrwa-india.firebasestorage.app",
  messagingSenderId: "1059068225676",
  appId: "1:1059068225676:web:98e7a357c3981a324e73a9"
});

const messaging = firebase.messaging();
