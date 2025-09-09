# Inactivation Scenarios for Clients and Providers

This document describes the rules and flows for handling account inactivation (making a client or provider inactive).

---

## 1. Admin-Initiated Inactivation  
*(Performed via the action button in the **User Management** tab of the Admin Dashboard)*  

### a. General Case  
- The admin can mark either a **client** or a **provider** as inactive.  
- This usually happens when there is a serious issue (e.g., misconduct) and the admin decides to intervene.  
- Immediate actions:  
  - **Force logout** the user by ending their session and showing an alert explaining why.  
  - **Prevent future access** with the same account (by deleting the account or fully disabling it).  
  - Cancel all **pending** or **confirmed bookings** related to the user.  
  - Send a **notification** to the other party (the “second side”) explaining that the admin deactivated the account and canceled bookings for important reasons, ensuring client safety and service quality.  

### b. Client Inactivated by Admin  
- All the client’s bookings are:  
  - Removed if **pending**, or  
  - Completed/canceled if **confirmed**.  
- Providers linked to those bookings will receive a notification about the cancellation and inactivation.  

### c. Provider Inactivated by Admin  
- All the provider’s bookings are:  
  - Removed if **pending**, or  
  - Completed/canceled if **confirmed**.  
- Additional actions:  
  - Remove the provider’s **service card** from the “Our Services” tab.  
  - Delete all links between the provider and their services.  
- Clients linked to those bookings will receive a notification about the cancellation and inactivation.  

### d. Service Deletion by Admin  
- If the admin deletes a service for any reason:  
  - **All bookings** related to that service (between any client and provider) are canceled.  
  - Both clients and providers receive a notification about the cancellation.  


---
## 2. Client-Initiated Inactivation  
*(Performed via the delete button in the profile settings of the Client Dashboard)*  

When a client requests to delete or deactivate their account:  
- Immediate actions:  if there is no something conflict with the booking rule 
  - **Force logout** the client by ending their session and showing an alert confirming the deletion.  
  - **Disable the account** to prevent future login.  
- Booking rules:  
  - **Pending bookings**: canceled immediately.  
  - **Confirmed bookings within 2 days**: the account cannot be inactivated until these are completed or canceled.  
  - **Other bookings (more than 2 days away)**: canceled automatically if more than 2 hours remain before the appointment.  
- The client should always receive an alert explaining why their account cannot yet be deleted if bookings are still active.  

This ensures that a client cannot simply disappear while still having active engagements with providers.  

---

## 3. Provider-Initiated Inactivation  
*(Performed via the delete button in the profile settings of the Provider Dashboard)*  

- A provider cannot delete their account instantly.  
- When they request deletion, a **notification** is sent to the admin for approval.  
- The admin should approve the request 

### Conditions  
- A **two-day delay** is enforced:  
  - If the provider has bookings scheduled within the next two days, they cannot delete their account immediately.  
  - They must wait until the two-day period has passed, then resend the request.  
- During this waiting period:  
  - The provider cannot accept new bookings.  
  - Existing confirmed bookings must either be completed or canceled.  
- Immediate actions once approved:  
  - **Force logout** the provider by ending their session and showing an alert.  
  - **Disable the account** to prevent future login.  
  - Remove the provider’s **service card** from the “Our Services” tab.  
  - Delete all links between the provider and their services.  

### Alignment with Client Rules  
- Since a provider can also act like a client in the system, the same inactivation rules that apply to clients also apply to providers when they are in the client role.  



Test plan (numbered): for 1
1) Admin inactivates client: verify bookings cancelled, client logged out, notifications sent.
2) Admin inactivates provider: verify bookings cancelled, provider services deactivated, logout, notifications.
3) Re-inactivate already inactive user: expect 400 with “already inactive”.
4) Inactivated user hits any protected API: expect 401 with code ACCOUNT_DEACTIVATED and reason.
5) Frontend force logout: after inactivation, validate token triggers deactivation dialog and redirects home.
6) Service deletion: confirm bookings cancelled, notifications sent, audit logged, UI shows impact message.
7) Admin UI: inactivation dialog requires reason; cancel keeps state unchanged; confirm updates status to inactive in table.
8) Notifications: verify types booking_cancelled_inactivation and booking_cancelled_service_deletion stored.
9) Audit logs: confirm entries for user_inactivation and service_deletion with impact details.
10) Localization: inactivation dialog/buttons show correct strings in EN/AR.