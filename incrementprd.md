Conflict detection
Online/manual/walk-in bookings
Rescheduling
Cancellation
No-show
Appointment lifecycle
Double-booking prevention
₹1 billing ledger
Audit log
Customer notifications
Customer/salon data isolation
P1 — Important
Multiple services
Service extension
Smart conflict resolution
Staff skill matching
Resources/chairs
Waitlist
Deposits
Customer verification
Basic customer history
P2 — Later
Automated empty-slot filling
Advanced marketing
Advertising
Marketplace
AI receptionist
Advanced predictive scheduling
49. Acceptance Criteria
The implementation is considered successful only if these scenarios work.
Scenario A — Normal booking
Customer books a 40-minute haircut.
System reserves the correct staff/time.
Scenario B — Simultaneous booking
Two customers attempt the same slot.
Only one succeeds.
Scenario C — Rescheduling
Customer moves 5 PM → 6 PM.
Same booking ID.
No duplicate ₹1 charge.
Scenario D — Cancellation
Accepted booking is cancelled by customer.
Appointment remains in history.
Billing ledger remains correct according to the configured billing rule.
Scenario E — Extra service
40-minute appointment becomes 70 minutes.
System detects downstream conflicts.
Scenario F — Alternative staff
Another qualified staff member is available.
System offers that option.
Scenario G — Staff absence
Staff becomes unavailable.
Affected appointments are identified.
Scenario H — Walk-in
Owner creates walk-in.
Same capacity engine is used.
Scenario I — No-show
Owner marks customer as no-show.
History records the event.
Billing remains consistent.
Scenario J — Fraud pattern
Repeated suspicious cancellations do not erase historical billing events.
The account can be flagged.
Scenario K — Monthly billing
System calculates usage from the immutable billing ledger.
Invoice/statement is generated for the correct period.
Scenario L — Privacy
Salon A cannot access Salon B's customers/bookings.
Scenario M — Advertisement boundary
Booking flow can expose contextual advertising later without exposing customer PII or disrupting the booking confirmation.
50. Final Agent Instruction
Do not treat this document as permission to rewrite the application.
Treat it as an incremental enhancement specification.
Before coding:
Inspect the repository.
Inspect the existing booking implementation.
Inspect existing database/schema/models.
Inspect existing APIs/services.
Inspect existing authentication and permissions.
Inspect existing notification/payment systems.
Map each requirement in this PRD to the existing implementation.
Identify what already exists.
Identify what needs extension.
Identify genuine gaps.
Implement the smallest safe changes necessary.
Before changing an existing behavior, explicitly verify that it conflicts with this PRD.
Do not remove existing functionality merely because a new architecture appears cleaner.
Do not create duplicate systems.
Do not perform unrelated refactoring.
Do not change unrelated UI.
Do not change pricing/business rules outside the requirements above.
After implementation, test the acceptance scenarios and verify that existing booking functionality still works.
The final result should feel like a natural evolution of the current application, not a replacement application.
Product North Star
The booking system should ultimately answer, at any moment:
Who is coming, what service are they receiving, when are they coming, who is serving them, what resources are required, what is happening right now, what will happen if something changes, and what should the customer/owner be told?
Build toward that model while keeping the current application intact.