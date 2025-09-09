# Inactivation Scenarios for Clients and Providers

This document describes the rules and flows for handling account inactivation (making a client or provider inactive).

---

## 1. Admin-Initiated Inactivation

### a. General Case
- The admin can mark either a **client** or a **provider** as inactive.  
- This usually happens if the user has a serious issue (e.g., misconduct) and the admin decides to step in.  
- In this case:
  - All **pending** or **confirmed bookings** must be canceled.  
  - A **notification** must be sent to the other party (the “second side”) explaining that the admin deactivated the account and canceled the related bookings for important reasons, and to ensure safe, high-quality service.

### b. Client Inactivated by Admin
- All the client’s bookings are either:
  - Removed if **pending**, or  
  - Completed/canceled if **confirmed**.  
- The provider(s) will receive a notification about the cancellation and inactivation.

### c. Provider Inactivated by Admin
- All the provider’s bookings are either:
  - Removed if **pending**, or  
  - Completed/canceled if **confirmed**.  
- The client(s) will receive a notification about the cancellation and inactivation.

### d. Service Deletion by Admin
- If the admin deletes a service for any reason, **all bookings related to that service** between any client and provider will be canceled.  
- Both sides receive a notification about the cancellation.

---

## 2. Client-Initiated Inactivation

When a client requests to delete or deactivate their account:
- **Pending bookings**: canceled immediately.  
- **Confirmed bookings within 2 days**: the account cannot be inactivated until these are completed or canceled.  
- **Other bookings (more than 2 days away)**: canceled automatically if more than 2 hours remain before the appointment.  

This ensures that a client cannot simply disappear while still having active engagements with providers.

---

## 3. Provider-Initiated Inactivation

- A provider cannot delete their account instantly.  
- When they request deletion, a **notification** is sent to the admin for approval.  
- The admin should approve the request, as there is no reason to deny it once the provider decides to leave.  

### Conditions
- A **two-day delay** is enforced:  
  - If the provider has bookings scheduled within the next two days, they cannot delete their account immediately.  
  - They must wait until the two-day period has passed, then resend the request.  
- During this waiting period:  
  - The provider cannot accept new bookings.  
  - Existing confirmed bookings must either be completed or canceled.  

### Alignment with Client Rules
- Since a provider can also act like a client in the system, the same inactivation rules that apply to clients also apply to providers when they are in the client role.

---

## Summary
- **Admin inactivation**: cancels all bookings, notifies the other side.  
- **Client inactivation**: pending bookings canceled, confirmed bookings within 2 days must finish/cancel, others canceled if more than 2 hours away.  
- **Provider inactivation**: requires admin approval, enforces a 2-day delay, and applies the same client rules when applicable.  
- **Service deletion by admin**: cancels all related bookings and notifies both parties.  
