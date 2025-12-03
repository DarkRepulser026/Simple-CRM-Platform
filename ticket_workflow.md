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