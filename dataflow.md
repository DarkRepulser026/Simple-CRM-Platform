## API Architecture Overview

The example demonstrates a **RESTful API client** that communicates with a CRM backend server. Here's the key components:

### 1. **API Configuration** (api_config.dart)
- **Environment-based URLs**: 
  - Development: `https://b2ad5166b831.ngrok-free.app` (ngrok tunnel)
  - Production: `https://api.temp.io`
- **Endpoint definitions** for all CRM entities:
  - Contacts, Leads, Tasks, Organizations, Activities, etc.
- **Authentication headers**: JWT Bearer tokens + Organization ID

### 2. **Core API Service** (api_service.dart)
Implements a comprehensive HTTP client with:

**HTTP Methods:**
- `GET`, `POST`, `PUT`, `DELETE`, `PATCH`
- Automatic timeout handling (30s)
- Error handling for network issues

**Authentication Flow:**
```dart
// Headers include JWT token and selected organization
Map<String, String> headers = {
  'Authorization': 'Bearer $token',
  'X-Organization-ID': organizationId,
  'Content-Type': 'application/json',
};
```

**Response Handling:**
- Typed `ApiResponse<T>` with success/error states
- Automatic logout on 401 unauthorized
- JSON parsing with error recovery

### 3. **Authentication Service** (auth_service.dart)
**Google OAuth Flow:**
1. User signs in with Google → gets ID token
2. Sends ID token to `/auth/google` endpoint
3. Server returns JWT token + user data + organizations
4. Client stores JWT for subsequent API calls

**Organization Selection:**
- Multi-tenant support with organization context
- `X-Organization-ID` header required for all API calls

### 4. **Business Services** (e.g., contacts_service.dart)
Each entity has a dedicated service that:
- Uses `ApiService` for HTTP communication
- Handles CRUD operations
- Converts JSON ↔ Dart models
- Includes pagination support

**Example Contact Operations:**
```dart
// GET /contacts?page=1&limit=20&search=john
getContacts({page: 1, limit: 20, search: "john"})

// POST /contacts
createContact(contactData)

// PUT /contacts/{id}
updateContact(contactId, contactData)

// DELETE /contacts/{id}
deleteContact(contactId)
```

### 5. **Data Models** (api_models.dart)
- **Contact**, **Lead**, **Task**, **Organization** models
- JSON serialization with `fromJson()`/`toJson()`
- Pagination support for list responses
- Type-safe API responses

## API Request Flow

1. **Authentication**: Google OAuth → JWT token
2. **Organization Selection**: Choose company context
3. **API Calls**: Include JWT + Organization headers
4. **Data Processing**: JSON → Dart models → UI
5. **Error Handling**: Network errors, auth failures, validation errors

## Server Interaction Pattern

The app follows a **client-server architecture** where:
- **Client**: Flutter app handles UI/state management
- **Server**: CRM backend manages data/business logic
- **Communication**: RESTful HTTP API with JWT authentication
- **Data Sync**: Real-time updates via API calls (no WebSocket shown)

This architecture allows the CRM to work across multiple devices with centralized data storage and user management.