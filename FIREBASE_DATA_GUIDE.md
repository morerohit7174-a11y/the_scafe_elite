# 🔥 Firebase Data — Kasa Baghaychya

## Firebase Console var Data Bagha
1. https://console.firebase.google.com var jaa
2. Tumcha project "cafe-elite-billing" open kara
3. Left menu → "Firestore Database" click kara

## Data Structure
```
cafe_elite/
  └── data/
       ├── bills/          ← Saglya bills
       │    ├── BILL-123   ← Individual bill
       │    └── BILL-456
       ├── hold_orders/    ← Hold orders
       └── products/       ← Products (future)
```

## Bills Data Bagha
- Firestore → cafe_elite → data → bills
- Konataही bill click kara → sagle details disatil

## Export Data (Excel/CSV)
1. Firebase Console → Firestore
2. Top right → "..." menu → Export
3. Google Cloud Storage madhe export hoto

## Real-time Dashboard
- Firestore madhe data add/update zala ki
- Saglya devices madhe LAGAR disato!
