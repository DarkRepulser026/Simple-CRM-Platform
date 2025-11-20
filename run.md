1) Start backend on port 3001 (to avoid conflict with Flutter web dev server on 3000):
Windows (cmd.exe):
cd backend
set PORT=3001
npm install
node index.js

2) Start the Flutter web app on port 3000 (default API will be set to http://localhost:3001 for dev builds):
flutter run -d chrome --web-port=3000

