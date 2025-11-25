
---

# 🛠 Implementation Task List (Missing & Partial Features)

Below is a prioritized task list with actionable sub-tasks, file references, and suggested acceptance criteria to implement the missing components called out above.

## Top-priority (APIs + UI scaffolding)

1. Add Users API endpoints and UI screens
   - Backend
     - Implement GET /users (paginated), POST /users, GET /users/:id, PUT /users/:id, DELETE /users/:id in `backend/index.js`.
       - Include pagination (page, limit), search, and organization-based filtering where appropriate.
       - Protect creation and deletion with `MANAGE_USERS` permission; allow read-only to managers/admins.
       - Add activity logging for user creation, role changes, and deletion.
     - Acceptance criteria: `GET /users` returns `{ users, pagination }` and `POST/PUT/DELETE` return appropriate JSON.
   - Frontend
     - Implement `UserDetailScreen` and `UserEditScreen` in `lib/screens/admin/`.
     - Update `UsersListScreen` to navigate to User detail and allow editing/invitation.
     - Wire actions using `UsersService` (getUsers, getUser, createUser, updateUser, deleteUser). See `lib/services/users_service.dart`.

2. Add Roles API endpoints and permission management
   - Backend
     - Implement user roles endpoints: GET /user_roles, POST /user_roles, PUT /user_roles/:id, DELETE /user_roles/:id in `backend/index.js`.
     - Accept `permissions` as an array (use Permission enum defined in Prisma schema), ensure only `MANAGE_ROLES` allowed to mutate.
     - Add activity log entries for role creation/update/deletion.
   - Frontend
     - Enhance `RolesListScreen` to add 'create / edit / delete' actions and manage permission list.
     - Ensure `RolesService` endpoints (createRole/updateRole/deleteRole) are wired to UI.

## Medium-priority ( UX / Features )

3. Contact timeline & entity 'view activity'
   - Frontend
     - Add Activity timeline component to `ContactDetailScreen` (e.g., `ActivityLogList` or reuse `ActivityLogsScreen` as a filtered view).
     - Add a 'View Activity' icon on `ContactDetailScreen` that navigates to `ActivityLogsScreen` with `ActivityLogsArgs(entityType: 'Contact', entityId: id)`.
   - Backend (already supported)
     - Confirm `GET /activity_logs?entityType=Contact&entityId=<id>` returns logs.

4. Lead Kanban board (drag to change status)
   - Frontend
     - Create `LeadsKanbanScreen` with columns for statuses. Use `Draggable` / `DragTarget` or a Kanban library for Flutter.
     - On status change, call PUT /leads/:id to update status. Use `LeadsService.updateLead()`.
   - Backend
     - Confirm existing `PUT /leads/:id` supports updating `status` field. Implement if missing.
   - Acceptance criteria: Dragging a lead to a new column updates the backend and causes the UI to reflect the status.

5. Task calendar & reminders
   - Backend
     - Add supports for reminder scheduling for tasks (optional: CRON/worker); store dueDate and reminder fields in `Task` model.
   - Frontend
     - Add a calendar view (monthly timeline) screen `TasksCalendarScreen` to visualize tasks by due date.
   - Acceptance criteria: Creating/updating a task with a due date displays properly on calendar.

6. Password reset flows
   - Backend
     - Add endpoints: `POST /auth/password/request-reset` (send reset token), and `POST /auth/password/reset` (accept token and new password). Store token hash for single-use, or use JWT with `tokenVersion` to revoke sessions after reset.
     - Ensure `tokenVersion` increment on reset so old sessions are revoked.
   - Frontend
     - Add UI screens for requesting password reset and resetting password with token.

## Secondary / Nice-to-have

7. Centralize audit logging helper
   - Backend
     - Create a helper in `backend/lib/` e.g. `audit.js` that accepts an `action`, `entityType`, `entityId`, `userId`, `oldValues`, `newValues`, `metadata` and writes `prisma.activityLog.create(...)` in a consistent format. Replace per-endpoint duplicate logging with this helper.
   - Acceptance criteria: Per-endpoint logs are created using helper, format consistent across services.

8. Permissions, gating, and UI polish
   - Frontend
     - Add permission checks to the UI so admin-only actions are hidden/disabled for unauthorized users.
     - Add role badge colors and permission checkboxes in `Roles` UI (create/edit role modal) to set and display permissions.

9. Export & reports for Activity Logs
   - Backend
     - Implement `GET /activity_logs/export` with filters (CSV, JSON) to export logs.
   - Frontend
     - Add `Export` button to `ActivityLogsScreen` that uses `ActivityLogService` to download CSV.

10. Redact sensitive fields in logs
   - Backend
     - Update logging helper to filter (`password`, `token`, `secret`) from `oldValues` / `newValues` before storing.

11. Add UI/Unit tests
   - Backend
     - Add integration tests for '/activity_logs', '/accounts', '/users', '/user_roles'
   - Frontend
     - Add widget and service tests for `ActivityLogsScreen`, `UsersListScreen`, and `RolesListScreen`.

## Optional / Future

12. S3-backed attachments
   - Backend
     - Support S3 uploads (swap local upload for S3) using config flags.
   - Frontend
     - Show preview and CDN URLs, optionally lazy-load thumbnails.

13. Performance & pagination improvements
   - Backend
     - Ensure all list endpoints support paginated responses with `pagination` metadata.
   - Frontend
     - Update `PaginatedListView` to show total count and pagination controls for large data sets.

---

## Acceptance Criteria & Milestones

Phase 1 — Critical: Users & Roles APIs and UI, Activity log timeline for contacts
 - Backend endpoints implemented and tested (users, user_roles)
 - Frontend screens completed and wired to backend
 - Activity logging consistent and includes `oldValues` / `newValues` on updates

Phase 2 — UX & features: Kanban leads, calendar tasks, password reset
 - Kanban & calendar implemented with status updates to API
 - Password reset flow working end-to-end

Phase 3 — Polish & tests: Centralize audit helper, redaction of sensitive fields, export, and tests
 - Audit helper created, redaction applied, tests added, activity export enabled

---



# ✅ **1. Core Features Based on Your Database Models**
---

# ⭐ **USER FEATURES (User, UserOrganization, UserRole)**

### **1. User Management (Admin-Only)**

**Supported by:** User, UserRole, UserOrganization
**Features:**

* Create / deactivate users
* Assign user to organization
* Change user roles (ADMIN, MANAGER, AGENT, VIEWER)
* Reset password using tokenVersion
* Manage user permissions
* View user activity logs

**UI Recommendations:**

* Table view with:

  * Name, email, role, organizations, active status
  * "Impersonate user" button for admin
* Side modal for editing user
* Add role badge (color-coded)

**Benefit:** Centralized control for multi-organization CRM.

---

# ⭐ **ORGANIZATION FEATURES (Organization, UserOrganization, UserRole)**

### **2. Organization Settings**

**Supported by:** Organization
**Features:**

* Customize organization profile (logo, domain, website)
* Manage roles & permissions
* Invite users to join organization via Invitation model

**UI Recommendations:**

* A “Settings” page with sections:

  * Profile
  * Branding (logo upload)
  * Industry info
  * User & Role Management
  * Invitation tab

**Benefit:** Makes CRM multi-tenant and customizable.

---

# ⭐ **CONTACT FEATURES (Contact Model)**

### **3. Contact Management**

**Supported by:** Contact
**Features:**

* Add/edit contacts
* Assign owner (sales rep/agent)
* Address & geolocation fields (city, state, lat/long)
* Filter contacts by city, owner, department
* Show timeline of activities for each contact
* Link contact with tasks or leads

**UI Recommendations:**

* Contact list with:

  * Avatar initials
  * Owner tag
  * Status color
  * Quick filters (owner, department, country)
* Contact profile page:

  * Left: Contact info
  * Right: Activity timeline
  * Tabs: Details / Tasks / Leads / Files

**Benefit:** Better customer information visibility & service history.

---

# ⭐ **LEAD FEATURES (Lead Model)**

### **4. Lead Management (Sales Pipeline)**

**Supported by:** Lead
**Features:**

* Add/edit leads
* Lead pipeline by status (NEW → CONTACTED → QUALIFIED)
* Convert lead → Contact + Account + Opportunity (you already support conversion IDs)
* Track lead source (WEB, REFERRAL, ADVERTISEMENT…)
* Assign lead to owner
* Lead rating

**UI Recommendations:**

* Kanban board for lead statuses
* Lead profile page with:

  * Activities
  * Owner info
  * Conversion button
* Conversion wizard modal (auto-create related records)

**Benefit:** Organized sales funnel & fast lead qualification.

---

# ⭐ **TASK FEATURES (Task Model)**

### **5. Task & Activity Management**

**Supported by:** Task
**Features:**

* Create tasks tied to:

  * Contact
  * Lead
  * Account
* Assign tasks to user
* Track status (NOT_STARTED → COMPLETED)
* Priority indicator
* Due date & reminder notifications
* Task dashboard per owner

**UI Recommendations:**

* Table view + Kanban mode
* Color-coded priority labels
* Task quick-create from any related entity page
* Calendar view (monthly timeline)

**Benefit:** Team productivity & workflow optimization.

---

# ⭐ **ACCOUNT FEATURES (Account Model)**

### **6. Company Accounts**

**Features:**

* Create account (companies you work with)
* Link contacts, tasks, leads, opportunities
* Central hub for all organization interactions

**UI Recommendations:**

* Account profile page:

  * Company info
  * Related contacts
  * Related tasks
  * Timeline

**Benefit:** Customer servicing at company level, not only individual.

---

# ⭐ **TICKET FEATURES (Ticket + TicketMessage Models)**

### **7. Customer Service Ticketing System**

**Supported by:** Ticket, TicketMessage
**Features:**

* Submit support ticket
* Ticket statuses (OPEN → RESOLVED → CLOSED)
* Assign ticket to agents
* Internal notes (isInternal = true)
* Ticket message thread (like a chat)
* Ticket categories
* Priority levels

**UI Recommendations:**

* Ticket inbox view (similar to Zendesk)
* Message thread with:

  * Customer messages on left
  * Support messages on right
* Internal notes in yellow background
* Ticket metrics:

  * Avg resolution time
  * Total open tickets
  * Agent performance

**Benefit:** Complete CRM-level customer service system.

---

# ⭐ **ACTIVITY LOG (ActivityLog Model)**

### **8. Audit Logging**

**Features:**

* Track who changed what (action, entity type, entity ID)
* Metadata stored as JSON
* Search logs per entity/user

**UI Recommendations:**

* Simple table:

  * User
  * Action
  * Entity
  * Date
  * Metadata (expandable JSON)

**Benefit:** Compliance, traceability, debugging.

---

# ⭐ **FILE ATTACHMENTS (Attachment Model)**

### **9. File Management**

**Features:**

* Upload files linked to:

  * Tickets
  * Contacts
  * Leads
  * Tasks
* Preview attachments
* Drag-drop uploader

**UI Recommendations:**

* File grid with MIME-type icons (PDF, Image, Doc)
* Support Amazon S3 uploads (recommended)

**Benefit:** Better collaboration & documentation.

---

# ⭐ **INVITATIONS (Invitation Model)**

### **10. User Invitation & Secure Onboarding**

**Features:**

* Invite via email
* Role assignment in invite
* Token-based secure onboarding
* Token expiry
* Resend / revoke invitation

**UI Recommendations:**

* Invitation table with:

  * Email
  * Role
  * Status (Accepted/Pending/Revoked)
* Modal form for invite

**Benefit:** Secure, scalable organization growth.

---

# 📊 **ANALYTICS & DASHBOARD (Based on all models)**

## Admin Dashboard Should Include:

### **1. Organization Metrics**

* Number of users
* Active contacts
* Leads status summary (pie chart)
* Tickets by priority
* Tasks overdue

### **2. Activity Timeline**

* "Recent Activities" from ActivityLog

### **3. Weekly Performance Charts**

* Leads created this week
* Tickets resolved this week
* Tasks completed by agents

---

# 👤 User Dashboard Should Include:

* My tasks (due soon)
* My leads
* My open tickets
* My reminders
* My activity log
* Quick actions (Create contact / Create ticket / Add task)

---

# 🎨 Frontend UI/UX Design Recommendations
### **Use These Components for Clean UI:**
| Purpose                          | Recommended Flutter Widgets                           |
| -------------------------------- | ----------------------------------------------------- |
| Dashboard metrics                | `Card`, `Container`, `Row`, `Column`                  |
| Lists (contacts, leads, tickets) | `DataTable`, `PaginatedDataTable`, `ListView.builder` |
| Tabs for entity details          | `TabBar`, `TabBarView`, `DefaultTabController`        |
| Create/Edit forms                | `AlertDialog`, `Dialog`, `showModalBottomSheet()`     |
| Status indicators                | `Chip`, `Container` + `BoxDecoration`                 |
| Global search                    | `SearchAnchor`, `SearchBar`, or custom search bar     |
| Action menus                     | `PopupMenuButton`                                     |
| Sidebar navigation               | `NavigationRail`, `Drawer`                            |
| Top navigation bar               | `AppBar`, `PreferredSize`                             |

### **Visual Standards**

* Consistent entity icons (user, building, ticket, task, briefcase)
* Color codes:

  * Lead status (blue, yellow, green, red)
  * Ticket priority (green → urgent red)
  * Role badges (Admin red, Manager orange, Agent blue, Viewer gray)

### **Layout**

* Left sidebar navigation
* Top bar with search + user menu
* Dashboard with a 3–4 card grid
* Entity pages with:

  * Left column = static data
  * Right column = activity + tasks + messages

---
