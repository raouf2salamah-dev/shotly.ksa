// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAXgRUc1rnt0zIUiOhYE2vc25rsIaA3fcQ",
  authDomain: "shotly-ksa.firebaseapp.com",
  projectId: "shotly-ksa",
  storageBucket: "shotly-ksa.firebasestorage.app",
  messagingSenderId: "218714911108",
  appId: "1:218714911108:android:93d001779fdc2f16572dd1"
};

// Initialize Firebase
if (typeof firebase !== 'undefined') {
  firebase.initializeApp(firebaseConfig);
} else {
  console.error("Firebase SDK not loaded!");
}