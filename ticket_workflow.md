A. Ticket Submission Phase
1. Customer sends ticket

Email: Customer sends an email to support@company.com

Web Widget: Customer fills form → subject, description, attachments, category, priority

2. System captures ticket

Email → parsed automatically

Web widget → inserts directly into ticket DB

Sanitizes HTML & validates fields

Checks duplicate conversations (same customer + similar subject)

3. Ticket is created

System assigns:

ticket ID

default status = OPEN

default priority (NORMAL unless specified)

requester information (email/name)

channel = EMAIL or WEB

4. Auto-response to customer

“Thanks, we received your request.”

Includes ticket ID

Reduces customer anxiety + lowers first-response SLA penalty

B. Ticket Routing Phase
5. Categorization / Tagging

System detects:

Keywords (billing, payment, bug, login issue)

Sentiment (optional ML)

Category assigned automatically or left for agents

6. Assignment

Based on:

Round-robin

Skill-based routing (billing → billing team)

Load balancing

VIP routing (priority customers)

If no rule matches → goes to Unassigned Queue

C. Agent Handling Phase
7. Agent views new ticket

Agent sees:

Customer profile

Previous tickets

Internal notes

Ticket timeline

8. Agent replies

Agent can:

Send public reply

Add private/internal note

Attach images / files

Ask for more info

Change category/priority

9. Customer receives email reply

Includes tracking thread

Email threading keeps conversation inside same ticket

D. Ticket Thread Continues
10. Customer responds

Reply by email

Widget portal (if you have one)

11. System detects reply

Reopens ticket if status = RESOLVED/CLOSED

Adds message to conversation

Notifies agent

E. Ticket Resolution Phase
12. Agent marks ticket as Resolved

Customer receives resolution confirmation

SLA timer stops

Resolution logged

13. If customer replies again

Ticket automatically returns to OPEN

F. Ticket Closure Phase
14. Automatic or manual closure

System can:

Auto-close after X days of no reply

Or agent manually closes it

15. Survey sent (optional)

CSAT survey

“How was our service?”

16. Ticket archived

Added to analytics

Available in customer history

ActivityLog entry created

Ticket System - Full CRM Implementation Plan
Based on the ticket workflow document, here's what we need to implement:

PHASE 1: Core Data Model & Backend APIs ✅ (Done)

PHASE 2: Ticket Routing & Assignment Logic ✅ (Done)
To Do:

Implement assignment strategies:

Round-robin: Distribute evenly among available agents
Skill-based: Route to agents with matching skill tags
Load-balancing: Route to agent with fewest open tickets
VIP routing: Priority for high-value customers
Unassigned queue: Default routing for non-matching tickets
Add backend logic:

Get list of eligible agents (by skill/role)
Calculate current load per agent
Apply assignment strategy
Create activity log entry
Add database support:

Agent skills/categories (many-to-many)
VIP customer flag
Load metrics
PHASE 3: Frontend - Ticket Messaging UI ✅ (Done)
To Do:

Enhance ticket detail screen:

Add messaging tab/section showing full conversation thread
Timeline view with public replies and internal notes (separate)
Reply composer with formatting
Attachment upload
Build message list widget:

Show messages chronologically
Distinguish public vs internal notes (visual diff)
Show sender name and avatar
Show timestamp
Build reply composer:

Rich text editor (or simple textarea)
Toggle: Public Reply / Internal Note
File upload button
Send button with loading state
PHASE 4: Frontend - Ticket Actions & Management ✅ (Done)
To Do:

Quick actions on detail screen:

Status dropdown: Open → Pending → Resolved → Closed
Resolve button (with optional resolution message)
Close button
Reopen button (if resolved/closed)
Reassign dropdown (with agent search)
Priority selector
Category selector
Add SLA indicators:

Show due date / SLA expiration
Color code if approaching deadline (yellow) or overdue (red)
Show response time metrics
Add customer profile card:

Link to customer/contact record
Previous tickets count
VIP badge if applicable
PHASE 5: Frontend - Unassigned Queue & Filtering
To Do:

Build unassigned queue view:

Filter to show only ownerId = null tickets
Prioritize by: urgency, age, SLA
Quick assign button (with skill-based suggestions)
Enhanced filtering:

Filter by status (Open, Pending, Resolved, Closed)
Filter by priority
Filter by category
Filter by assigned agent
Filter by date range
Search conversation history
Add ticket views:

My Tickets (assigned to current user)
Unassigned Queue
All Tickets
Resolved/Closed Archive
PHASE 6: Frontend - Ticket Creation
To Do:

Build ticket creation form:

Subject (required)
Description/issue details (required)
Category selector (auto-detect keywords)
Priority selector (default: NORMAL)
Attachments
Customer/contact selector (if internal staff creating on behalf of customer)
Add validation:

Check for duplicates (similar subject + same customer)
Sanitize HTML/content
Add confirmation:

Show ticket ID
Show auto-response message that customer will receive
Option to send to customer email
PHASE 7: SLA & Automation
To Do:

Implement SLA tracking:

Calculate due date based on priority (e.g., High: 4hrs, Normal: 24hrs, Low: 72hrs)
Show visual indicator (green/yellow/red)
Track response time SLA vs resolution SLA
Auto-close logic:

Background job to close tickets after X days of no activity
Send warning to agent before auto-close
Create activity log entry
Auto-reopen logic:

If customer replies to resolved/closed ticket, automatically reopen
PHASE 8: Optional - Email Integration
To Do:

Email capture:

Set up email forwarding to support@company.com
Parse incoming emails
Extract sender, subject, body
Create ticket automatically
Email threading:

Keep conversation in same ticket
Forward agent replies to customer
Strip internal notes from email

continue with phase