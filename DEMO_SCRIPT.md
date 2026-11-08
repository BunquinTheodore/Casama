# Casama — Academic Demonstration Script

This document details the step-by-step procedure to showcase **Casama** during a project defense, presentation, or demonstration.

---

## 🎬 Live Demonstration Scenario (12 Steps)

| Step | Action | What to Showcase on Screen | Expected Outcome |
| :---: | :--- | :--- | :--- |
| **1** | **App Launch** | Open the app. The **Splash Screen** appears with Cas the mascot, warm branding waves, and Casama logo. | Demonstrates brand identity and design consistency. |
| **2** | **One-Tap Demo Login** | Tap *"I already have an account"* ➔ Tap *"One-Tap Demo Login (JP - Casa 204)"*. | Bypasses credential typing; signs in as Jon Paul Berana and opens **Casa 204**. |
| **3** | **Live Presence Toggle** | On the Dashboard Household card, tap on your avatar (**You**). In the modal, toggle from *"I'm Home"* to *"I'm Out"*, add the note *"At library"*, and tap **Save Status**. | Instant update of your presence chip and timestamp without page reloading. |
| **4** | **Home Dashboard Calendar** | Scroll on the Home screen to the **Household Calendar**. Navigate months using `<` and `>`, tap on a date with a dot marker, and filter activities by *"Parcels"*, *"Tasks"*, or *"Meetups"*. | Live scheduling tied to real application tasks and events with empty state handling. |
| **5** | **Plus (+) Quick-Action Menu** | Tap the center coral **`+`** button in the bottom navigation. | Clean modal bottom sheet displays: *Add a Parcel*, *Report an Item*, *Add a Household Task*, *Create a Meet-up*, and *Invite a Housemate*. Selecting any item routes cleanly. |
| **6** | **Delivery & COD Board** | In Quick Access, tap **Parcels**. Review the Shopee delivery marked with `COD • ₱350` and Lazada with `Paid`. Tap *"I Got It"* on Shopee. | The parcel moves to History, records receiver, and awards **+5 Kasama Points** with celebration dialog. |
| **7** | **Lost & Found Board** | Navigate to **Lost & Found**. Review *"Lost AirPods"* (`Open`) and *"Found Backpack"* (`Unclaimed`). Tap **"Post an Item"** to show the posting modal. | Shows the owner reporting and finder claiming workflow. |
| **8** | **Maintenance Task Completion** | Navigate to **Boards ➔ Maintenance**. Show categorized tasks: *Leaking Faucet* (`Urgent`), *Buy Drinking Water* (`To Buy`). Tap the checkmark/avatar on *Buy Drinking Water*. | Task completes and awards **+2 Kasama Points** for household restocking. |
| **9** | **Chat, Spaces & Invitation Codes** | Tap **Chat**. Notice unread badge count updates dynamically. Open **"Casa 204"** group chat. Tap `+` attachment ➔ *"Share Household Code"*. Create a **Custom Chat Space ("Grocery & Supplies 🛒")**, direct-add roommates, or join via code. | Demonstrates group messaging, topic spaces, 1-tap join cards, and unread clearance upon viewing. |
| **10** | **Meet-up RSVP** | In Chat or Group Chat, tap the embedded **Meet-up Invitation card ("Study Session 🎓")**. | Showcases face-to-face meet-up RSVP (`Going`, `Maybe`, `Can't make it`) with live attendee counters. |
| **11** | **Chore Roulette** | From Group Chat attachment or direct action, tap **"Spin Chore Roulette"**. Tap **"Spin"**. | Watch the multi-colored wheel decelerate and land on a chore, randomly assigning it to a housemate with a one-tap button to add to tasks. |
| **12** | **Edit Profile & Appearance Themes** | Navigate to **Profile ➔ Edit Profile**. Upload photo via Gallery/Camera, edit nickname (instantly updates Home greeting). Go to **Settings ➔ Appearance** and switch between **Light, Dark, and System Default** across all tabs. | Demonstrates cross-app theme propagation and profile customization. |

---

## 🛠️ Verification Commands for Evaluation

To demonstrate code quality and test compliance to evaluators:

```bash
# 1. Run full static analysis (must report "No issues found!")
flutter analyze

# 2. Run automated test suite (all tests passing)
flutter test
```

