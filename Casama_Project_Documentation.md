CASAMA

Making shared living simpler, warmer, and more coordinated.

DETAILED PROJECT DOCUMENTATION

| DOCUMENT PROFILE \| DETAILS \|

| --- \| --- \|

| Project name \| Casama \|

| Project type \| Academic software development / mobile application \|

| Primary platform \| Flutter mobile application (Android first;
  cross-platform structure) \|

| Backend \| Supabase Auth, PostgreSQL, Realtime; Storage reserved for
  Phase 2 \|

| Primary users \| Dormmates, apartment roommates, shared-household
  members, families \|

| Planned MVP schedule \| Three-week implementation plan (subject to
  team capacity and course requirements) \|

| Document version \| 1.0 \| Detailed functional, UI/UX, and technical
  specification \|

PROJECT PURPOSE

Casama provides one organized place for household members to coordinate
presence, deliveries, shared items, maintenance, and small household
responsibilities. It replaces scattered group-chat messages with clear,
shared records and timely updates.

# Document Guide

This updated edition includes Casama Connect, a household-focused
messaging and in-person meet-up feature. The MVP includes basic group
chat, direct messages, and meet-up invitations; offline message queuing
and advanced chat options are deferred.

| SECTION \| CONTENTS \|

| --- \| --- \|

| 1. Project Overview \| Background, problem, objectives, users, scope
  \|

| 2. Requirements \| Functional requirements, non-functional
  requirements, assumptions \|

| 3. Functional Modules \| Detailed workflows, rules, validations, edge
  cases \|

| 4. UI/UX Design System \| Visual direction, typography, colors,
  components, responsive behavior, accessibility \|

| 5. Screen Specifications \| Purpose and expected behavior of each
  screen \|

| 6. Technical Architecture \| Flutter, Supabase, data flow, state
  management, realtime \|

| 7. Database Design \| Tables, relationships, recommended constraints
  and indexes \|

| 8. Security and Privacy \| Authentication, RLS, invite codes, data
  handling \|

| 9. Testing and Acceptance \| Test coverage, acceptance criteria,
  success measures \|

| 10. Implementation Plan \| Three-week schedule, priorities, demo
  scenario, risks \|

| 11. Future Enhancements \| Features intentionally deferred beyond MVP
  \|

# 1. Project Overview

## 1.1 Project Description

Casama is a household coordination mobile application for people who
share a living space. Its name combines "Casa," meaning house, and
"Kasama," meaning companion. The application helps members answer
everyday questions such as who is currently home, whether someone can
receive a parcel, who has borrowed a shared item, and which household
issue needs attention.

Instead of allowing important details to disappear inside a busy group
chat, Casama organizes them into dedicated modules. Household members
can update information, view the latest status, and receive in-app
activity updates.

## 1.2 Problem Statement

Shared households often coordinate through informal messaging groups.
Although convenient, group chats can make important information
difficult to find. Delivery schedules, COD amounts, item ownership,
maintenance concerns, and household errands may be buried among
unrelated messages. This can lead to missed deliveries, repeated
questions, forgotten tasks, and misunderstandings.

Casama addresses this problem by providing structured household records,
clear responsibilities, and near-real-time updates.

## 1.3 General Objective

To design and develop a responsive, user-friendly mobile application
that improves coordination and communication among people who share a
household.

## 1.4 Specific Objectives

-   Allow users to create or join a household through a secure
    invitation code.

-   Provide a shared dashboard showing each member's manually updated
    Home or Out status.

-   Coordinate expected parcels, arrival schedules, roommate
    availability, receiving claims, and COD records.

-   Help household members report, locate, claim, and return lost or
    found items.

-   Organize maintenance and restocking tasks by category, urgency, and
    status.

-   Encourage helpful participation through a transparent points ledger
    and monthly leaderboard.

-   Deliver household-scoped realtime updates while preventing access
    between unrelated households.

-   Provide household group chats, private member-to-member messaging,
    and simple face-to-face meet-up invitations.

## 1.5 Target Users

| USER GROUP \| NEEDS / USE CASE \|

| --- \| --- \|

| College students in dormitories \| Coordinate class schedules, parcel
  receiving, shared supplies, and room responsibilities. \|

| Apartment or condominium roommates \| Know who is home, track
  deliveries, and manage maintenance concerns. \|

| Families sharing a household \| Coordinate errands, household upkeep,
  and shared belongings. \|

| Young professionals in shared housing \| Reduce repeated messages and
  make household responsibilities visible. \|

## 1.6 Value Proposition

Casama is a household coordination platform, not an expense-splitting
application or another messaging app. Its main value is the combination
of presence visibility, parcel and COD coordination, shared-item
tracking, and household task management in one shared space.

# 2. Scope and Requirements

## 2.1 Minimum Viable Product (MVP)

The MVP is the first working version. It should focus on dependable core
workflows rather than implementing every possible enhancement. Casama
Connect is included as a focused household communication module: basic
household group chat, direct messages, and simple meet-up invitations.
Advanced chat capabilities such as offline message queuing, attachments,
and rich reactions remain later enhancements.

| MODULE \| MVP SCOPE \|

| --- \| --- \|

| Authentication and household \| Email/password registration and login;
  create household; join with invite code. \|

| Presence \| Manual Home/Out toggle; optional status note; household
  dashboard; event history. \|

| Parcel board \| Create, edit, cancel, arrival date, paid/COD type,
  availability, conflict warning, receive claim, COD owed record. \|

| Lost and found \| Create lost/found post; update status; claim found
  item; simple "Who has it?" responses. \|

| Maintenance and restock \| Create task; category and urgency; optional
  assignee; Open/In Progress/Done status. \|

| Good Kasama Points \| Award points for eligible actions; prevent
  duplicate awards; monthly leaderboard. \|

| Realtime and notifications \| Live household updates; in-app activity
  feed with read/unread state. \|

| Security \| Authentication and Row Level Security (RLS) on all
  household data; cross-household access tests. \|

## 2.2 Phase 2 Features

-   Geofencing with manual status fallback.

-   Offline event queue and later synchronization.

-   Photo uploads for parcels and lost/found items.

-   Push notifications for important household events and new chat
    messages.

-   One optional mini-game, such as Chore Roulette or an anonymous
    household poll.

-   Temporary, opt-in exact location sharing.

## 2.3 Explicitly Out of Scope for MVP

-   General-purpose public messaging or social networking. Casama
    Connect is limited to members of the same household.

-   Payment processing, bank integration, or collection of payment
    credentials.

-   Calendar integration.

-   Live map tracking.

-   Full offline support and background geofencing.

## 2.4 Assumptions and Constraints

-   Users have an internet connection for MVP data operations.

-   Each user belongs to one active household in the initial release.
    Supporting multiple households can be considered later.

-   Presence is updated manually. The MVP does not collect GPS or
    background location data.

-   COD is a record of money owed between household members; Casama does
    not transfer or collect money.

-   The three-week schedule is an aggressive development target.
    Security and core workflows take priority over optional polish.

# 3. Functional Requirements

## 3.1 Authentication and Household Management

| ID \| REQUIREMENT \| ACCEPTANCE CONDITION \|

| --- \| --- \| --- \|

| FR-01 \| The system shall allow users to register using email and
  password. \| A valid registration creates an authenticated account and
  profile. \|

| FR-02 \| The system shall allow registered users to log in and log
  out. \| Invalid credentials show a clear error; logout ends the
  session. \|

| FR-03 \| A user shall be able to create a household. \| The creator
  becomes the household owner and receives an invite code. \|

| FR-04 \| A user shall be able to join using a valid invite code. \|
  The user becomes a member of that household. \|

| FR-05 \| The system shall reject invalid or expired invite codes. \|
  No membership record is created. \|

## 3.2 Presence and Household Dashboard

Members manually set their presence to Home or Out. They may add a short
note such as "Studying," "Sleeping / DND," or "At class until 5 PM." The
dashboard displays each member's current status and when it was last
updated.

-   Store each change as a presence event rather than overwriting one
    boolean field.

-   Derive current status from the latest accepted event for that user
    and household.

-   Display a last-updated time so members do not mistake old
    information for live presence.

-   Show a useful empty state when a household has no other members.

-   If an update fails, retain the previous confirmed status and show a
    retry message.

-   Do not request location permissions in the MVP.

## 3.3 Parcel Board

A buyer creates a parcel record containing the courier, expected arrival
date/time, payment type, COD amount when applicable, and optional
delivery notes. Household members indicate whether they can receive that
parcel.

| FIELD \| RULE \|

| --- \| --- \|

| Courier \| Required; choose a known courier or enter Other. \|

| Expected arrival \| Required date; time may be optional if the
  delivery estimate is broad. \|

| Payment type \| Paid or COD. \|

| COD amount \| Required and greater than zero only when payment type is
  COD; otherwise null. \|

| Notes \| Optional instructions such as fragile, leave with guard, or
  call on arrival. \|

| Availability \| Each member can mark Available or Unavailable for that
  parcel. \|

| Receiver \| The member who confirms receipt is recorded with
  timestamp. \|

| Settlement \| A COD record can be marked settled; this is a household
  record only. \|

Parcel lifecycle: Expected → Arrived → Received → Closed. A parcel may
also be Cancelled. "Claiming" should mean that a member volunteers to
receive the parcel; it must not be confused with confirming that the
parcel has physically arrived.

Conflict rule: if every eligible household member is marked Unavailable
for the parcel's expected arrival, show a visible warning to the buyer.
If the arrival date/time changes, recalculate availability and refresh
the warning.

## 3.4 Lost, Found, and Shared Items

| ITEM TYPE \| SUGGESTED STATUS FLOW \| BEHAVIOR \|

| --- \| --- \| --- \|

| Lost item \| Open → Found → Returned \| Owner reports an item missing;
  another member reports finding it; return is confirmed. \|

| Found item \| Unclaimed → Claimed → Returned \| A member posts an item
  found; the owner claims it; return is confirmed. \|

| Shared item ping \| Available / In use / Seen at location \| Members
  respond to "Who has it?" with a short status or note. \|

For the MVP, the lost/found flows are required. Shared-item pings can
use a simple response list. If time is limited, a complete borrowing
history should be deferred.

## 3.5 Maintenance and Restock

Members create tasks with a title, description or note, category,
urgency, and optional assignee. Tasks appear in a list ordered by
urgency and creation time.

| ATTRIBUTE \| OPTIONS / RULE \|

| --- \| --- \|

| Category \| DIY / Roommate; Landlord / Admin; Household Restock. \|

| Urgency \| Low, Medium, Urgent. \|

| Status \| Open → In Progress → Done. \|

| Assignee \| Optional household member. If the assignee leaves, clear
  the assignment. \|

| Completion \| Record who completed the task and when. \|

## 3.6 Good Kasama Points

| ELIGIBLE ACTION \| POINTS \|

| --- \| --- \|

| Parcel successfully received and confirmed \| +5 \|

| Lost item found and returned \| +3 \|

| Maintenance task completed \| +5 \|

| Restock task completed \| +2 \|

Points must be awarded only after the related action is successfully
committed. Use a unique ledger constraint so retrying a request cannot
award points twice. If a task is reopened, retain the historical award
and record the reopening event; do not silently issue another award when
it is completed again.

The monthly leaderboard shows each member's total points for the
selected month. Ties may be broken by the number of eligible actions.
Any suggested household treat is optional and social, never enforced by
the application.

## 3.7 In-App Activity Feed

## 3.8 Casama Connect: Housemate Communication

Casama Connect gives members of the same household a dedicated place to
communicate online and coordinate in-person interaction. It is
intentionally household-focused rather than a general-purpose messaging
or social networking service.

Core MVP functions:

-   Household group chat: one shared conversation for members of a
    household.

-   Direct messages: private one-to-one conversations between household
    members.

-   Realtime messaging: new messages appear for authorized participants
    without manual refresh.

-   Meet-up invitations: members can suggest an activity, time, and
    user-entered location such as the dorm common area; invitees can
    respond Going, Maybe, or Can't make it.

-   Basic message history: conversations retain messages with timestamps
    and sender information.

-   Chat notifications: notify members about new messages and invitation
    updates, subject to user notification settings.

Recommended later enhancements:

-   Read receipts, delivery indicators, emoji reactions, pinned
    messages, and file/photo attachments.

-   Offline message composition and a local send queue that synchronizes
    when connectivity returns.

-   Optional availability labels such as Available, Busy, Away, and
    Offline. Users should control their availability; online presence
    must not imply willingness to talk.

Offline behavior: in the initial implementation, previously loaded
messages may remain readable if locally cached, but sending requires a
network connection. If offline message queuing is implemented later,
queued messages must be clearly labeled as waiting for connection and
must not appear as sent or delivered until the server confirms receipt.

Message lifecycle: Composed → Sent → Delivered → Read (where receipts
are enabled). The server timestamp and persisted message record are the
source of truth. Retries must use a stable client-generated message ID
or idempotency key to prevent duplicate messages.

-   Show the latest 20 household events, newest first.

-   Support per-user read/unread state.

-   Include events such as presence changes, parcel creation, parcel
    conflict, parcel receipt, item found, and task completion.

-   Do not rely on the activity feed as the only source of truth. Each
    module must retain its own record.

# 4. UI/UX Design System

## 4.1 Design Direction

The interface should use a flat design approach: clean surfaces, clear
hierarchy, simple icons, restrained color, and minimal decoration. Avoid
heavy gradients, glass effects, excessive shadows, and unnecessary
visual effects. The app should feel warm and welcoming without looking
childish.

## 4.2 Typography

Use a consistent type family throughout the application. Recommended
primary font: Inter. If Inter is unavailable in the Flutter project, use
the platform's clean sans-serif fallback. Use font weight, size, and
spacing to establish hierarchy rather than using many different fonts.

| STYLE \| SIZE \| WEIGHT \| USAGE \|

| --- \| --- \| --- \| --- \|

| Display \| 28--32 sp \| Bold / 700 \| Page title or key dashboard
  greeting. \|

| Headline \| 22--24 sp \| Semibold / 600 \| Screen and section
  headings. \|

| Title \| 16--18 sp \| Semibold / 600 \| Cards, dialogs, list item
  titles. \|

| Body \| 14--16 sp \| Regular / 400 \| Descriptions, labels,
  explanatory text. \|

| Body Small \| 12--13 sp \| Regular / 400 \| Secondary details and
  timestamps. \|

| Label \| 12--14 sp \| Medium / 500 \| Buttons, chips, form labels. \|

| Caption \| 11--12 sp \| Regular / 400 \| Helper text and metadata. \|

Typography rules: use sentence case; keep long paragraphs left-aligned;
avoid all-caps for normal content; use tabular numerals for currency,
dates, and point totals when supported; do not communicate status using
color alone.

## 4.3 Color Palette

| TOKEN \| HEX \| PURPOSE \|

| --- \| --- \| --- \|

| Primary Coral \| #E87968 \| Primary actions, highlights, active
  controls. \|

| Deep Teal \| #3F7772 \| Secondary actions, navigation accents,
  positive emphasis. \|

| Ink \| #263238 \| Main text and strong headings. \|

| Muted Gray \| #607078 \| Secondary text and metadata. \|

| Warm Cream \| #FFF8F1 \| Warm page background or welcome surfaces. \|

| Soft Neutral \| #F3F5F4 \| Cards, input backgrounds, subtle grouping.
  \|

| Border Gray \| #DCE3E0 \| Dividers and input borders. \|

| White \| #FFFFFF \| Card and modal surfaces. \|

Use coral sparingly for the primary action. Use teal for supporting
emphasis. Use semantic colors consistently for success, warning, and
error states, and always pair them with a label or icon. Check
text/background contrast before release.

## 4.4 Flat UI Components

| COMPONENT \| VISUAL / BEHAVIOR SPECIFICATION \|

| --- \| --- \|

| Primary button \| Solid primary color, readable label, 10--12 px
  corner radius, clear pressed/disabled/loading states. \|

| Secondary button \| Neutral surface with border; used for alternate
  actions. \|

| Cards \| Flat white or soft-neutral surface, subtle 1 px border,
  12--16 px radius, no heavy shadow. \|

| Text fields \| Persistent label, clear placeholder, visible focus
  border, inline validation and helper text. \|

| Status chips \| Compact pill with text and optional icon; use
  consistent colors for Home/Out, urgency, and task status. \|

| Bottom navigation \| Five main destinations with icon and text label;
  selected destination clearly indicated. \|

| Dialogs / sheets \| Use for confirmations and short forms; avoid long
  multi-step forms where a dedicated screen is clearer. \|

| Empty states \| Friendly explanation and one clear next action; never
  leave a blank screen. \|

| Snackbars \| Short success or error feedback; include retry when an
  operation can be retried. \|

## 4.5 Layout and Spacing

-   Use an 8-point spacing rhythm: common gaps of 8, 16, 24, and 32
    logical pixels.

-   Use consistent horizontal page padding, generally 16--20 px on
    phones and 24--32 px on wider layouts.

-   Keep forms readable and avoid placing too many fields in one row on
    small screens.

-   Use a consistent corner-radius scale, such as 8 px for controls and
    12--16 px for cards.

-   Keep important actions visually prominent and place destructive
    actions away from primary actions.

## 4.6 Responsive Behavior

Although the first release is mobile-focused, layouts must adapt to
different screen widths, orientations, and text scaling. In Flutter, use
LayoutBuilder or MediaQuery breakpoints rather than fixed screen
coordinates.

| VIEWPORT \| LAYOUT RULE \|

| --- \| --- \|

| Compact phone (\< 360 logical px) \| Single-column layout; full-width
  primary buttons; cards stack; labels may wrap. \|

| Standard phone (360--599 px) \| Single-column dashboard; bottom
  navigation; forms use full width. \|

| Large phone / small tablet (600--839 px) \| Use wider cards or a
  two-column dashboard where content remains readable; maintain
  comfortable margins. \|

| Tablet (≥ 840 px) \| Optional navigation rail or side navigation;
  dashboard can use two columns; cap content width to avoid overly long
  lines. \|

| Landscape \| Allow scrolling; avoid clipped dialogs and fixed-height
  content; keep primary actions accessible. \|

-   Support system font scaling and prevent text clipping.

-   Use scrollable content for forms and long lists.

-   Respect safe areas and keyboard insets.

-   Use minimum touch targets of approximately 48 × 48 logical pixels.

-   Test on a small Android phone, a standard phone, and a
    tablet/emulator if available.

## 4.7 Accessibility and Usability

-   Every icon-only action must have a semantic label.

-   Use readable contrast and do not rely on color alone to communicate
    meaning.

-   Provide clear field labels, error messages, and focus states.

-   Make confirmation dialogs understandable and specific, such as "Mark
    this parcel as received?"

-   Provide loading, empty, success, offline/error, and disabled states
    for important screens.

-   Use plain language and consistent labels throughout the application.

# 5. Screen Specifications

| SCREEN \| KEY CONTENT \| PRIMARY INTERACTIONS \|

| --- \| --- \| --- \|

| Splash / Authentication \| Casama identity; login and registration
  forms. \| Register, log in, show validation, reset password if
  included. \|

| Household Setup \| Create household or join with invite code. \|
  Create household; validate and submit invite code. \|

| Dashboard \| Household name; member presence cards; quick actions;
  active parcel/task summaries. \| Set Home/Out; edit status note;
  navigate to modules. \|

| Parcel Board \| Upcoming parcels, filters, availability, COD
  indicator, conflict warning. \| Create/edit/cancel parcel; set
  availability; volunteer to receive; confirm receipt. \|

| Parcel Detail \| Courier, expected arrival, payment type, COD amount,
  notes, members' availability, activity history. \| Update details;
  claim; mark arrived/received; mark COD settled. \|

| Lost & Found \| Tabs or filters for Lost, Found, and Shared Item
  Pings. \| Post item; update status; claim; respond to a ping. \|

| Maintenance \| Open tasks grouped or sorted by urgency and status. \|
  Create task; assign member; update status; complete task. \|

| Points \| Monthly leaderboard and personal points history. \| Switch
  month/all-time view; inspect point actions. \|

| Notifications \| Recent household activity with read/unread
  indication. \| Open related record; mark as read. \|

| Profile / Settings \| Display name, household details, privacy notes,
  logout. \| Edit profile; view household; log out. \|

## 5.1 Dashboard Layout Recommendation

1.  Top area: household name and notification icon.

2.  Welcome line with a short, friendly message.

3.  Presence section: member cards with Home/Out status, status note,
    and last-updated time.

4.  Quick actions: Add Parcel, Report Item, Create Task.

5.  Attention section: parcel conflicts, deliveries expected soon, and
    urgent open tasks.

6.  Bottom navigation: Home, Boards, Add, Chat, and Profile. Points and
    Chore Roulette remain accessible from the Home screen or a secondary
    section.

## 5.4 Form Behavior

-   Validate required fields before submission and show errors beside
    the relevant field.

-   Disable the submit button while a request is in progress to prevent
    duplicate submissions.

-   Show a success message only after the backend confirms the
    operation.

-   Preserve entered values if a network request fails, where practical.

-   Ask for confirmation before destructive actions such as cancelling a
    parcel or deleting a post.

# 6. Technical Architecture

## 6.1 Technology Stack

| LAYER \| TECHNOLOGY \| PURPOSE \|

| --- \| --- \| --- \|

| Mobile application \| Flutter + Dart \| Build the interface and
  application logic for Android and potentially iOS. \|

| Backend platform \| Supabase \| Provides managed authentication,
  database access, realtime events, and later file storage. \|

| Database \| PostgreSQL \| Stores household, presence, parcel, item,
  task, points, and notification records. \|

| Authentication \| Supabase Auth \| Manages user registration, login,
  and session tokens. \|

| Realtime \| Supabase Realtime \| Notifies connected clients when
  household records change. \|

| State management \| Riverpod (recommended) \| Keeps screen state and
  data flow organized and testable. \|

| Navigation \| GoRouter (recommended) \| Defines routes and protects
  authenticated screens. \|

## 6.2 Architecture in Plain Language

The Flutter app is the part users see and interact with. It displays
screens, validates form input, and sends requests through the Supabase
client library. Supabase Auth verifies who the user is. PostgreSQL
stores the application records. Row Level Security checks whether the
signed-in user is allowed to access each record. Realtime sends change
events to other authorized members so their screens can refresh without
manually reloading.

The app must not treat the interface as the security boundary. Hiding a
button does not prevent an unauthorized database request. Database
policies must enforce access rules.

## 6.3 Data Flow Example: Updating Presence

1.  The member taps "I'm Home" in the Flutter app.

2.  The app checks that the user is signed in and has an active
    household.

3.  The app inserts a new presence event into PostgreSQL.

4.  PostgreSQL applies RLS and accepts or rejects the request.

5.  Supabase Realtime broadcasts the permitted database change to
    subscribed household clients.

6.  Other members' apps receive the event and refresh the presence
    display.

7.  The interface shows the new status and timestamp.

## 6.4 Frontend Organization

Organize the Flutter project by feature so each module keeps its
screens, models, providers, and repository logic together. Avoid putting
all application logic inside widget files.

| FOLDER / LAYER \| RESPONSIBILITY \|

| --- \| --- \|

| lib/core/ \| Theme, constants, shared utilities, error handling,
  routing. \|

| lib/features/auth/ \| Login, registration, session handling. \|

| lib/features/household/ \| Create/join household, member management.
  \|

| lib/features/presence/ \| Presence events, status cards, dashboard
  presence section. \|

| lib/features/parcels/ \| Parcel forms, availability, claims, COD
  records. \|

| lib/features/items/ \| Lost/found posts and item responses. \|

| lib/features/tasks/ \| Maintenance and restock tasks. \|

| lib/features/points/ \| Points ledger and leaderboard. \|

| lib/features/notifications/ \| In-app activity feed. \|

| lib/shared/ \| Reusable buttons, cards, form fields, chips, loading
  and empty states. \|

| lib/data/ \| Supabase client, repositories, DTOs, and shared data
  access. \|

## 6.5 State Management and Repository Pattern

Use Riverpod to expose application state to screens. A repository is a
small class responsible for reading and writing one type of data, such
as ParcelRepository or PresenceRepository. Screens call providers or
controllers; they should not contain raw SQL or scattered database
requests.

-   Keep form state separate from server-loaded data.

-   Represent loading, success, empty, and error states explicitly.

-   Invalidate or refresh the relevant provider after a successful
    mutation.

-   Dispose realtime subscriptions when leaving a household or logging
    out.

-   Keep business rules in testable functions or service classes, not
    only in button callbacks.

## 6.6 Realtime Design

Subscribe to the current household's relevant database changes after
authentication and household selection. Filter subscriptions by
household_id where supported, and rely on RLS as the security control.
Unsubscribe when the user logs out or switches household. Realtime is a
notification mechanism; it is not a replacement for database
transactions or constraints.

## 6.7 Atomic Operations

Some actions update more than one table. For example, receiving a COD
parcel may update the parcel status, create a claim record, create a COD
owed record, and award points. These related changes should succeed or
fail together. Use a PostgreSQL function or transaction-backed server
operation for multi-table actions. This prevents a parcel from appearing
received when the COD record or points award failed.

-   Confirm parcel receipt + create claim/COD ledger + award points as
    one logical operation.

-   Claim a found item only if it is still unclaimed.

-   Prevent duplicate points with a unique database constraint.

-   Use server-generated timestamps for authoritative event ordering.

# 7. Database Design

Use UUID primary keys and timestamptz timestamps. Every household-owned
record should carry household_id directly. This makes access policies
easier to understand and audit. Profiles are user-scoped rather than
household-scoped.

## 7.1 Recommended Tables

| TABLE \| IMPORTANT FIELDS \| PURPOSE \|

| --- \| --- \| --- \|

| profiles \| id (auth user UUID), display_name, avatar_url, created_at
  \| Public-facing user profile information. \|

| households \| id, name, invite_code_hash or protected invite code,
  created_by, created_at \| A shared living group. \|

| household_members \| household_id, user_id, role, joined_at \|
  Connects users to households; composite unique key. \|

| presence_events \| id, household_id, user_id, event_type, note,
  source, local_created_at, server_received_at \| Presence history and
  current-status source. \|

| parcels \| id, household_id, buyer_id, courier, expected_arrival,
  payment_type, cod_amount, currency, status, notes \| Expected
  deliveries and their lifecycle. \|

| parcel_availability \| id, household_id, parcel_id, user_id,
  available, note, updated_at \| Availability per parcel and member. \|

| parcel_claims \| id, household_id, parcel_id, receiver_id,
  received_at, amount_owed, settled \| Who received the parcel and COD
  accountability. \|

| items \| id, household_id, type, title, description, status,
  reported_by, created_at \| Lost/found/shared item records. \|

| item_responses \| id, household_id, item_id, user_id, response_type,
  note, created_at \| Responses to item posts and shared-item pings. \|

| maintenance_tasks \| id, household_id, title, category, urgency,
  status, assignee_id, created_by, notes, due_note, completed_at \|
  Household maintenance and restock work. \|

| points_ledger \| id, household_id, user_id, action_type, points,
  reference_id, created_at \| Auditable points awards. \|

| notifications \| id, household_id, user_id, type, payload, read_at,
  created_at \| Per-user in-app activity feed entries. \|

| Table \| Purpose \|

| --- \| --- \|

| conversations \| Stores household group or direct conversation
  metadata, type, household_id, creator, and timestamps. \|

| conversation_members \| Maps users to conversations and stores
  membership/role and joined_at. \|

| messages \| Stores sender, conversation_id, message body, server
  timestamp, and client_message_id for idempotent retries. \|

| message_receipts \| Optional per-user delivered/read timestamps for
  each message. \|

| meet_up_invitations \| Stores activity, optional note, suggested time,
  user-entered place, creator, and status. \|

| meet_up_responses \| Stores each invitee's Going, Maybe, or Can't make
  it response. \|

## 7.2 Important Relationships

-   A household has many household_members.

-   A user can be a member of a household through household_members.

-   A household has many presence_events, parcels, items,
    maintenance_tasks, conversations, and notifications.

-   A parcel belongs to one buyer and may have multiple availability
    responses.

-   A parcel may have one or more claim/history records, depending on
    the chosen parcel lifecycle implementation.

-   An item may have multiple item_responses.

-   A points_ledger entry belongs to one user and references the action
    that earned the points.

-   A household conversation belongs to one household and has multiple
    conversation_members.

-   A direct conversation has only its intended participants; the server
    must enforce participant access.

-   A conversation has many messages and may have message_receipts for
    each recipient.

-   A meet_up_invitation belongs to a conversation and has one response
    per invited member.

## 7.3 Data Integrity Rules

-   Use foreign keys for relationships and define delete behavior
    deliberately.

-   Use CHECK constraints for enumerated values such as event_type,
    payment_type, urgency, and status.

-   Require cod_amount to be positive when payment_type is COD; require
    it to be null for Paid.

-   Use unique (household_id, user_id) in household_members.

-   Use unique (parcel_id, user_id) in parcel_availability if each
    member has one current availability response per parcel.

-   Use a unique points-ledger key such as (user_id, action_type,
    reference_id) to prevent duplicate awards.

-   Use indexes on household_id, created_at, status, expected_arrival,
    and foreign-key columns used by common queries.

## 7.4 Important Schema Clarification

The initial concept document states that all household-scoped tables
include household_id, but several sample table definitions omit it. The
implementation should resolve this before coding: add household_id to
every household-owned table listed above, or implement and document an
equally strong relational policy. For this project, storing household_id
directly is the simpler and easier-to-test approach.

Also, the initial parcel availability table is described as
date-specific in the workflow but only uses parcel_id and user_id in its
sample schema. Because each parcel already has an expected arrival date,
this can work for a single expected date. If the application later
supports multiple delivery windows, add an arrival-window identifier or
availability date/time to the design.

# 8. Security and Privacy

## 8.1 Authentication

-   Use Supabase Auth for account creation, login, session refresh, and
    logout.

-   Associate each profile row with the authenticated user UUID.

-   Never store passwords directly in the application database.

## 8.2 Row Level Security (RLS)

Enable RLS on every table that contains user or household data. A user
may access a household-owned record only when they are a member of that
record's household. Profiles should be readable and editable according
to a clearly defined user-profile policy.

RLS policies must independently validate auth.uid() and household
membership. Do not trust a household_id sent by the mobile app without
checking that the authenticated user belongs to it.

## 8.3 Required Security Tests

-   A household member can read and send messages only in conversations
    where they are an active participant.

-   A user from Household A cannot read, insert, edit, or delete
    messages in Household B conversations.

-   A user cannot add themselves to a private conversation by modifying
    a client request.

-   Meet-up invitation responses are limited to invited conversation
    members.

-   Message retries with the same client_message_id do not create
    duplicate records.

-   User A in Household A cannot SELECT records belonging to Household
    B.

-   User A cannot INSERT a record into Household B by manually supplying
    its household_id.

-   User A cannot UPDATE or DELETE records belonging to Household B.

-   An unauthenticated user cannot read protected household records.

-   A user cannot add themselves as owner or change their role by
    editing a client request.

-   Invite-code joining validates the code on the server and does not
    expose unrestricted household data.

## 8.4 Secrets and API Keys

The Supabase anon/publishable key may be included in a client
application when RLS is correctly configured. The Supabase service-role
key must never be placed in Flutter source code, app assets, or a
distributed build. It bypasses normal RLS protections and must remain on
a trusted server.

## 8.5 Privacy

-   The MVP collects no GPS or exact location data. Meet-up invitations
    may contain a user-entered place or shared-space label, not
    device-derived location.

-   Presence status is manually entered and visible only to household
    members.

-   COD records store amounts owed, not payment credentials.

-   Explain what household members can see before users join a
    household.

-   Provide a clear logout action and avoid exposing private data in
    notification previews unnecessarily.

-   Phase 2 location features must be opt-in, temporary, and accompanied
    by clear permission explanations.

# 9. Non-Functional Requirements

| CATEGORY \| REQUIREMENT \|

| --- \| --- \|

| Usability \| Core tasks should be understandable without technical
  knowledge. Forms must provide clear labels and validation. \|

| Responsiveness \| Layouts must adapt to compact phones, standard
  phones, and tablet-sized screens without clipping. \|

| Performance \| Common screens should load promptly under a normal
  mobile connection; target realtime UI update under 2 seconds in the
  pilot environment. \|

| Reliability \| Failed network operations must show an error and must
  not falsely display an unconfirmed success. \|

| Security \| RLS must prevent cross-household reads and writes for all
  CRUD operations. \|

| Maintainability \| Feature-based code organization, reusable widgets,
  documented data access, and testable business logic. \|

| Compatibility \| Test the target Android version(s) and at least one
  physical device when available. \|

| Accessibility \| Readable text, sufficient contrast, semantic labels,
  and touch targets of approximately 48 logical pixels. \|

| Data integrity \| Duplicate claims and duplicate point awards must be
  prevented by database constraints or atomic server operations. \|

# 10. Testing and Acceptance Criteria

## 10.1 Testing Types

| TEST TYPE \| WHAT TO TEST \|

| --- \| --- \|

| Unit tests \| Presence status selection, parcel conflict detection,
  COD validation, points calculation, item and task status transitions.
  \|

| Widget tests \| Forms, validation messages, buttons, loading states,
  empty states, responsive layouts. \|

| Integration tests \| Registration, household creation/join, presence
  update, parcel receiving, item claim, task completion. \|

| Security / RLS tests \| SELECT, INSERT, UPDATE, DELETE isolation
  across two different households. \|

| Realtime tests \| Two devices in one household receive updates; a
  different household receives no private data. \|

| Device tests \| Keyboard behavior, safe areas, orientation, text
  scaling, slow network, app resume. \|

| Usability pilot \| One or two households use the app for 2--3 days;
  collect task observations and feedback. \|

## 10.2 MVP Acceptance Criteria

-   Two users can register, create a household, and join using an invite
    code.

-   Presence updates appear on another authorized household member's
    device.

-   Presence displays a last-updated timestamp.

-   A parcel can be created, edited, cancelled, and marked received.

-   COD amount is required only for COD parcels and is recorded when
    received.

-   A conflict warning appears when every eligible member is
    unavailable.

-   Lost/found item status transitions work and duplicate claims are
    rejected.

-   Maintenance tasks can be created and moved through Open, In
    Progress, and Done.

-   Points are awarded once per eligible action and the leaderboard
    totals are correct.

-   RLS prevents all tested cross-household read and write attempts.

-   Important screens, including chat and invitation views, adapt to
    supported screen widths and do not clip text or controls.

-   Household members can exchange messages in the household group
    conversation.

-   A member can start and use a private direct conversation with
    another member of the same household.

-   New messages appear for authorized participants through realtime
    updates.

-   A member can create a meet-up invitation and invited members can
    submit a response.

-   Chat access is blocked for users who are not conversation members.

## 10.3 Suggested Performance Targets

| MEASURE \| TARGET \|

| --- \| --- \|

| Realtime update visibility \| Under 2 seconds in a normal test
  network, measured from successful database write to other device UI
  update. \|

| Parcel conflict detection \| Correctly identifies 100% of test cases
  where all eligible members are unavailable. \|

| Security isolation \| Zero successful unauthorized cross-household
  reads or writes in the test suite. \|

| Usability \| Aim for SUS above 70 if the number and profile of pilot
  participants make the score meaningful. \|

These are project targets, not guaranteed results. Record the test
setup, number of participants, device/network conditions, and observed
results in the final report.

# 11. Implementation Plan

The original plan targets three weeks. Treat the schedule as a
development sequence, not a reason to skip testing. Add basic Casama
Connect group chat and direct messaging after household membership and
RLS are stable. Implement meet-up invitations after the messaging
foundation. Defer offline message queuing and advanced chat features
until core messaging is verified.

| WEEK \| FOCUS \| DELIVERABLE / EXIT CONDITION \|

| --- \| --- \| --- \|

| Week 1 \| Foundation and presence \| Flutter scaffold, Supabase
  connection, auth, household creation/join, RLS, manual presence, live
  dashboard. Two-household isolation test passes. \|

| Week 2 \| Core household workflows \| Parcel board, availability,
  conflict alert, receiving/COD flow, lost/found, maintenance, realtime
  updates, basic notification feed. \|

| Week 3 \| Points, validation, demo \| Points ledger and leaderboard,
  regression/security tests, pilot, UI polish, documentation, slides,
  demo and backup recording. \|

## 11.1 Recommended Daily Sequence

| DAY \| TASK \|

| --- \| --- \|

| 1 \| Finalize MVP scope, ERD, repository structure, and Supabase
  project. \|

| 2 \| Authentication, profile creation, login and registration UI. \|

| 3 \| Household creation, invite code, and join flow. \|

| 4 \| RLS policies and two-household isolation tests. \|

| 5--6 \| Presence events, manual toggle, status notes, dashboard,
  realtime. \|

| 7 \| Buffer and Week 1 acceptance checks. \|

| 8--10 \| Parcel CRUD, availability, conflict detection, receive flow,
  COD ledger. \|

| 11 \| Lost/found posts, item responses, claim flow. \|

| 12 \| Maintenance and restock tasks. \|

| 13--14 \| Realtime coverage, notification feed, end-to-end tests,
  buffer. \|

| 15 \| Points ledger and leaderboard. \|

| 16 \| Only if core MVP is stable: one stretch feature. \|

| 17--19 \| Regression, security retest, pilot, fixes, responsive UI
  review. \|

| 20 \| README, ERD, architecture diagram, setup documentation. \|

| 21 \| Demo rehearsal, slides, backup video, final submission. \|

## 11.2 Priority if Behind Schedule

Remove features in this order: optional mini-game or photo upload;
detailed leaderboard history; notification-feed refinements; presence
history view; advanced task assignment. Preserve authentication,
household membership, RLS, manual presence, parcel conflict detection,
and core realtime behavior.

## 11.3 Demonstration Scenario

1.  User A registers and creates a household.

2.  User B registers on another device and joins using the invite code.

3.  User A changes presence to Home and adds "Studying." User B sees the
    update.

4.  User B creates a COD parcel with an expected arrival date.

5.  All members mark themselves unavailable. The buyer sees the conflict
    warning.

6.  User A becomes available, receives the parcel, and confirms receipt.

7.  The app records the receiver, COD amount owed, and eligible points.

8.  User B posts a lost item. User A marks it Found; the status updates
    live.

9.  User A creates an urgent landlord maintenance task.

10. User B completes the task; the leaderboard reflects the points
    award.

# 12. Risks and Mitigation

| RISK \| POSSIBLE IMPACT \| MITIGATION \|

| --- \| --- \| --- \|

| RLS is difficult to configure \| Private household information may be
  exposed or legitimate actions blocked. \| Implement RLS early; test
  with two separate households before adding many modules. \|

| Realtime updates do not arrive \| Users see stale information. \|
  Verify subscription filters, table publication, policies, and cleanup
  behavior. \|

| Parcel workflow becomes too complex \| Development slips beyond
  schedule. \| Keep conflict logic simple: alert only when all eligible
  members are unavailable. \|

| UI polish consumes development time \| Core workflows remain
  unfinished. \| Use a small design system and reusable components;
  prioritize functional consistency. \|

| Duplicate actions award points twice \| Leaderboard becomes
  inaccurate. \| Use unique constraints and atomic server-side
  operations. \|

| Network failure creates false success \| Users trust a change that was
  not saved. \| Show confirmed success only after the backend responds;
  provide retry and error states. \|

| Testing is delayed until the end \| Critical bugs appear near
  submission. \| Test each module immediately and reserve the final week
  for regression and pilot testing. \|

# 13. Project Deliverables

-   Functional Flutter application for the agreed target platform.

-   Supabase backend with documented schema and verified RLS policies.

-   Entity Relationship Diagram (ERD).

-   High-level system architecture diagram.

-   README with installation, environment setup, and run instructions.

-   Functional and non-functional requirements documentation.

-   Test cases and summarized test results.

-   UI screenshots and/or short demonstration video.

-   Pilot feedback summary and known-issues list.

-   Presentation slides and backup demo recording.

# 14. Future Enhancements

-   Geofencing with manual fallback and explicit location permission.

-   Offline event queue and conflict-aware synchronization for household
    actions.

-   Advanced notification preferences and delivery refinements.

-   Photo attachments for lost/found posts and parcel proof.

-   Optional Chore Roulette, polls, or photo bounty challenges.

-   Temporary opt-in live location sharing.

-   Filipino and English localization.

-   Shared shopping list and household supply tracking.

-   Household activity timeline and simple usage analytics.

-   Offline chat message queue with automatic retry and synchronization.

-   Message reactions, read receipts, pinned messages, and media
    attachments.

-   Optional member availability indicators and richer meet-up planning.

# 15. Conclusion

Casama is designed to make shared living more organized and connected
through focused household tools and communication. Presence, parcel
coordination, lost/found tracking, maintenance, and Casama Connect help
members coordinate everyday responsibilities while making it easier to
communicate and build stronger housemate relationships.

The most important implementation priorities are a reliable
manual-presence workflow, a clear parcel receiving process,
household-scoped database security, and a consistent responsive
interface. A flat visual design, readable typography, accessible
controls, and well-defined loading and error states will help the
application feel polished without adding unnecessary complexity.

For a successful academic MVP, the team should deliver fewer features
correctly rather than many features incompletely. Optional automation,
location tracking, push notifications, and mini-games should remain
outside the initial release unless the essential workflows are already
stable and tested.

# Appendix A. Recommended UI Copy

| SITUATION \| SUGGESTED MESSAGE \|

| --- \| --- \|

| No household yet \| Create a household or join one with an invite code
  to get started. \|

| No members online/status \| No presence updates yet. Be the first to
  update your status. \|

| Presence update failed \| Your status could not be updated. Check your
  connection and try again. \|

| No parcels \| No parcels scheduled. Add a delivery when you are
  expecting one. \|

| All unavailable \| No household members are currently available for
  this delivery window. \|

| No lost/found posts \| Nothing reported right now. Post an item if
  something is missing or found. \|

| No maintenance tasks \| All clear for now. Add a task when something
  needs attention. \|

| Action successful \| Changes saved successfully. \|

| Action failed \| We couldn't save that change. Your information is
  still here; please try again. \|

# Appendix B. Development Notes

-   Recommended state management: Riverpod. Select one approach and use
    it consistently.

-   Recommended routing: GoRouter. Protect authenticated routes and
    redirect users without a household to setup.

-   Use repository classes for Supabase reads and writes.

-   Use PostgreSQL constraints and transactions for data integrity; do
    not rely only on client-side checks.

-   Keep the service-role key out of the mobile application.

-   Document all environment variables and provide a safe example
    configuration file without real secrets.

-   Keep design tokens in one theme file so color, typography, spacing,
    and radius remain consistent.

## 5.2 Chat Screen

The Chat tab should use a familiar, uncluttered messaging layout
consistent with Casama's flat design system.

-   Header: "Your Housemates" with household name and a search action.

-   Household group conversation displayed prominently, followed by
    direct conversations.

-   Conversation rows show avatar, name or group name, latest message
    preview, timestamp, and unread count.

-   Optional online indicators must be subtle and accompanied by
    accessible text; do not equate online status with availability.

-   Conversation view includes message bubbles, sender identity where
    needed, timestamps, and a clearly labeled composer.

-   Meet-up invitations appear as structured cards inside the
    conversation with activity, suggested time, place, and response
    status.

-   Provide empty, loading, failed-send, offline, and no-search-results
    states.

## 5.3 Meet-up Invitation Screen Behavior

-   Allow a member to enter an activity title, optional note, suggested
    date/time, and a place description.

-   Allow invitees to respond Going, Maybe, or Can't make it.

-   Show response counts and the individual responses to household
    members who can access the conversation.

-   Do not collect or infer device location for meet-up invitations.

# 16. Brand Mascot: Cas

## 16.1 Mascot Overview

**Name:** Cas\
**Animal:** Owl\
**Role:** Official Casama brand mascot\
**Personality:** Friendly, helpful, approachable, cheerful, dependable,
and community-oriented.

Cas represents the idea that a good home is not only a place to stay,
but also a place where people look out for one another. The owl was
selected to communicate awareness, helpfulness, and guidance while
giving Casama a recognizable and welcoming visual identity.

## 16.2 Visual Identity

Cas is a rounded, friendly owl with: - Midnight Blue and Dusty Blue
feathers. - Ivory or warm cream facial and body areas. - A small
orange-gold beak and feet. - Large expressive eyes and soft, rounded
shapes. - A small Casama house emblem positioned high on the left chest
area of the shirt, near the heart. The emblem should remain subtle and
proportionate. - A smartphone as an optional prop to represent household
communication and the Casama app.

The mascot should follow the same flat, clean, friendly visual direction
as the application. Keep the silhouette recognizable at small sizes and
avoid excessive detail, gradients, or decorative effects.

## 16.3 Mascot Color Palette

  -----------------------------------------------------------------------
  Color                   Hex                     Usage
  ----------------------- ----------------------- -----------------------
  Midnight Blue           `#1C2E4A`               Main feathers,
                                                  outlines, primary brand
                                                  color

  Dusty Blue              `#52677D`               Secondary feather
                                                  shading and supporting
                                                  elements

  Ivory                   `#BDC4D4`               Light body and facial
                                                  areas

  Deep Navy               `#0F1A2B`               Dark text, deep
                                                  outlines, contrast

  Buttercream             `#D1CFC9`               Warm neutral
                                                  backgrounds

  Coral                   `#E87968`               Friendly highlights and
                                                  action accents

  Warm Gold               `#F4B544`               Beak, feet, stars,
                                                  positive accents
  -----------------------------------------------------------------------

The mascot palette should coordinate with the app interface. Use the
darker blues for identity and contrast, warm neutrals for softness, and
coral or gold sparingly for emphasis.

## 16.4 Expressions and Poses

Recommended expression set: - **Happy:** Welcoming expression for
successful actions and positive feedback. - **Excited:** Celebrates
completed tasks, received parcels, and household milestones. -
**Thinking:** Appears beside tips, questions, and helpful suggestions. -
**Winking:** Adds a friendly touch to casual reminders. - **Surprised:**
Used sparingly for unexpected updates or alerts.

Recommended pose set: - **Standing:** Default mascot pose for onboarding
and brand materials. - **Waving:** Welcomes new members and introduces
screens. - **Jumping:** Celebrates achievements and earned Kasama
Points. - **Holding a phone:** Represents Casama Connect and household
coordination. - **Holding a parcel:** Represents delivery
coordination. - **Holding a checklist:** Represents maintenance and
household tasks. - **Together with other owls:** Represents community,
teamwork, and shared living.

## 16.5 Where Cas Appears in the App

  -----------------------------------------------------------------------
  App area                            Suggested mascot use
  ----------------------------------- -----------------------------------
  Onboarding                          Cas waves and introduces the
                                      purpose of Casama.

  Home dashboard                      Small welcome illustration or
                                      contextual greeting.

  Chat / Casama Connect               Cas holding a phone or speech
                                      bubble to encourage housemate
                                      communication.

  Parcels                             Cas holding a parcel to guide
                                      receiving and COD workflows.

  Lost & Found                        Cas thinking or looking for an item
                                      in empty states.

  Maintenance                         Cas holding a checklist or tool.

  Kasama Points                       Cas celebrating earned points and
                                      helpful contributions.

  Empty states                        Cas provides friendly, useful
                                      guidance when no records exist.

  Success states                      Cas celebrates completed actions
                                      without distracting from the task.
  -----------------------------------------------------------------------

## 16.6 Mascot Usage Guidelines

1.  Keep Cas visually consistent across screens, posters, documentation,
    and promotional materials.
2.  Preserve the owl's key features, proportions, colors, and chest
    emblem.
3.  Use the chest emblem on the upper-left chest area, near the heart,
    and keep it small.
4.  Use expressions and props that match the context of the screen.
5.  Do not place the mascot on every screen if it adds clutter.
    Prioritize onboarding, empty states, helpful prompts, and milestone
    moments.
6.  Maintain sufficient contrast against both light and dark
    backgrounds.
7.  Do not use the mascot as the only way to communicate an important
    status. Pair illustrations with clear text and accessible labels.

## 16.7 Mascot Brand Description

**Cas** is Casama's friendly owl companion, designed to represent
awareness, kindness, and cooperation in shared living. With a warm
expression, navy-and-ivory appearance, and a small house emblem over the
heart, Cas reminds housemates that a better home is built through
communication and small acts of consideration.

**Suggested mascot line:** "A better home starts with being a good
kasama."

## 16.8 Visual Reference Assets

The following image assets accompany this documentation when stored in
the same folder as this Markdown file:

-   `Cas - Mascot Owl.png` --- mascot identity and character reference.
-   `Casama Mockup Ui.png` --- current Casama mobile UI screen showcase.
-   `a_clean_flat_vector_illustration_character_sheet_i.png` ---
    character expressions and poses reference, if retained.
-   `a_clean_flat_ui_design_mockup_collage_of_a_mobile.png` --- earlier
    UI design reference, if retained.

The current UI reference includes the Home dashboard, Parcels, Lost &
Found, Maintenance, Chat, household group conversation, meet-up
creation, Profile, and Chore Roulette screens. Use the latest approved
UI mockup as the primary interface reference.
