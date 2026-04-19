```markdown
# Meet-Up Dating App – Complete Project Plan

## 1. Executive Summary

**Meet-Up** is a cross‑platform dating app (iOS & Android) that prioritises genuine connections through privacy‑first design, immersive discovery, and real‑time presence features. Key differentiators include:

- **Strict photo privacy** – All user photos are fully blurred until a connection request is accepted. No subscription can unblur them early.
- **Attention Seeker** – A haptic button in chat that makes the other user’s phone vibrate while held, creating a sense of physical presence after relationship maturity.
- **Privacy‑preserving face verification** – On‑device face detection and hashing – no biometric data ever leaves the user’s phone.
- **Reel‑style discovery** – Vertical swipe for profiles, horizontal swipe for multiple images.
- **60/40 matching** – 60% based on common custom interests, 40% random.
- **Rich media chat** – Send any file type up to 500 MB (images, video, audio, documents) with end‑to‑end encryption (E2EE) planned for premium.
- **Live location option** – Users can optionally share real‑time location while the app is open; default is static snapshot.

**Target launch:** 5 months from project start.

---

## 2. Technology Stack

| Layer | Technology | Justification |
|-------|------------|----------------|
| **Frontend** | Flutter (Dart) | Single codebase for iOS & Android, excellent performance for animations (reel swiper), hot reload. |
| **Backend API** | NestJS (Node.js) | TypeScript, modular architecture, easy integration with PostgreSQL and Socket.IO. |
| **Database** | PostgreSQL + PostGIS | Relational for users, matches, messages; PostGIS for location‑based queries. |
| **Real‑time** | Socket.IO (with Redis adapter) | Chat, typing indicators, attention seeker events, presence. |
| **Authentication & Push** | Firebase Auth (Google) + FCM / APNs | Seamless Google login, cross‑platform push notifications. |
| **Storage** | Cloudflare R2 | S3‑compatible, no egress fees, cheap storage for images and large media. |
| **Face Verification** | Google ML Kit (on‑device) + SHA‑256 hashing | Privacy‑first – no face data sent to server. |
| **Video/Audio Calls** | Agora.io | Reliable WebRTC‑based SDK with pre‑built UI. |
| **Ads** | Google AdMob | Banner and interstitial ads for free tier. |
| **Monitoring** | Sentry + Prometheus + Grafana | Error tracking and performance metrics. |
| **Admin Panel** | Retool (low‑code) | Quick setup for user moderation and basic analytics. |

---

## 3. Core Features (by Module)

### 3.1 Onboarding & Authentication
- Animated splash screen (3‑4 sec) with rotating tips about app features.
- Google Sign‑In (primary). Email/password backup optional.
- After login, **mandatory profile completion** (no skip).

### 3.2 Profile Completion (Mandatory)
- Fields: Name, Age, Gender, Interested In (Male/Female/Everyone).
- **Custom interests** – Text input with comma separation. Each word becomes a category chip (e.g., "Travel, Coffee, Hiking" → stored as array).
- Bio / short story (200 chars max).
- Multiple images (3‑6). All images are **blurred** for other users until a connection is accepted.
- Location snapshot (optional live location toggle in settings).

### 3.3 Face Verification (Privacy‑Preserving)
- User takes a live selfie and performs a liveness check (e.g., turn head).
- On device: ML Kit extracts face embedding → SHA‑256 hash with device‑specific salt.
- Server stores only the hash + `is_verified` boolean. No raw biometrics.
- Prevents duplicate/fake accounts.

### 3.4 Discovery (Reel‑Style)
- Vertical swipe (up/down) to see next profile.
- Each profile card: horizontally swipable images (left/right) if multiple.
- Displays: Name, Age, Distance, Interests (as hashtags), Bio.
- Buttons: **Like** (heart) and **Connect** (request).
- Matching algorithm:
  - 60% of profiles from common interests (Jaccard similarity on interest arrays).
  - 40% random (within location & age filters).
- Distance calculated from user’s static or live location.

### 3.5 Connections & Requests
- User A presses **Connect** → sends connection request to User B.
- User B receives push notification + in‑app badge.
- User B can **Accept** or **Reject**.
- If accepted → both can see each other’s **unblurred photos** and can chat.
- If rejected → button resets to Connect for User A.
- Connection request history stored.

### 3.6 Chat & Messaging
- Real‑time with Socket.IO.
- Features: typing indicator, read receipts (✓✓ blue), delivery status.
- **E2EE** (Signal Protocol) for premium users – free tier uses TLS + server‑side encryption at rest.
- **Media sharing** up to 500 MB per file (images, video, audio, documents). Chunked uploads to Cloudflare R2 with virus scanning.
- Chat list shows recent conversations.

### 3.7 Attention Seeker (Haptic Presence)
- Button in chat that becomes enabled after “relationship maturity” (e.g., 100 messages exchanged OR 7 days since connection accepted).
- When User A **presses and holds** the button → WebSocket event `attention:start` sent to User B.
- User B’s phone vibrates continuously until User A releases (`attention:stop`).
- Rate limits: 3 times per minute, 10 times per day. User B can disable haptics in settings.

### 3.8 Audio / Video Calls (Premium Only)
- Powered by Agora.io.
- 1:1 calls only. Call history stored.
- Premium subscription required ($9.99/month or $79.99/year).

### 3.9 Monetisation & Ads
- **Free tier:** Basic matching, 10 likes/day, text chat, media sharing (up to 100 MB total), ads (banner + interstitial after every 5 messages).
- **Premium tier ($9.99/mo):** Unlimited likes, no ads, video/audio calls, E2EE, 500 MB per file, custom stickers (future), attention seeker unlimited.
- **AdMob** integrated – banners at bottom of discovery screen, interstitials after sending 5 messages (free users).

### 3.10 Gamification & Stickers (Post‑MVP)
- Sticker packs (free, event‑based, premium).
- Couple games (Trivia, Would You Rather, Memory Match) – planned for version 2.0.

### 3.11 Admin Panel (Retool)
- Basic dashboard: view users, ban/unban, view reported messages (requires moderation key for E2EE chats), view daily active users, matches, revenue.

---

## 4. Database Schema (PostgreSQL)

### 4.1 Table: `users`
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  age INT NOT NULL,
  gender TEXT NOT NULL,
  interested_in TEXT[] NOT NULL, -- ['male','female'] or ['everyone']
  interests TEXT[] NOT NULL,      -- ['travel','coffee','hiking']
  bio TEXT,
  images TEXT[],                  -- array of R2 URLs (blurred & original)
  face_hash TEXT UNIQUE,          -- hash of on-device face embedding
  is_verified BOOLEAN DEFAULT false,
  location GEOGRAPHY(POINT),      -- last known location (static or live)
  location_updated_at TIMESTAMP,
  live_location_enabled BOOLEAN DEFAULT false,
  premium_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  last_active TIMESTAMP
);
```

### 4.2 Table: `connection_requests`
```sql
CREATE TABLE connection_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending','accepted','rejected')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP
);
```

### 4.3 Table: `connections`
```sql
CREATE TABLE connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID REFERENCES users(id),
  user2_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user1_id, user2_id)
);
```

### 4.4 Table: `photo_access`
```sql
CREATE TABLE photo_access (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  granted_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, viewer_id)
);
-- Populated when a connection request is accepted.
```

### 4.5 Table: `messages`
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  connection_id UUID REFERENCES connections(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id),
  content TEXT,                    -- encrypted for premium, plain for free
  is_encrypted BOOLEAN DEFAULT false,
  type TEXT DEFAULT 'text',        -- text, image, video, audio, file
  media_url TEXT,                  -- R2 URL for media
  thumbnail_url TEXT,              -- for video/image preview
  file_size BIGINT,
  mime_type TEXT,
  delivered_at TIMESTAMP,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 4.6 Table: `attention_seeker_logs`
```sql
CREATE TABLE attention_seeker_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID REFERENCES users(id),
  to_user_id UUID REFERENCES users(id),
  duration_ms INT,                 -- how long button was held
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 5. API Endpoints (NestJS)

### 5.1 Authentication & User
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/google` | Firebase Google token exchange, returns JWT. |
| POST | `/profile` | Create/update user profile (name, age, gender, interests, bio). |
| POST | `/profile/images` | Upload images to R2 (blurred version generated). |
| POST | `/verify/face` | Submit face hash and liveness proof. |
| GET | `/profile/:userId` | Get public profile (blurred images unless connection exists). |

### 5.2 Discovery
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/discover` | Returns list of profiles (60% interest‑based, 40% random) with distance. Query params: `lat`, `lng`, `limit`. |

### 5.3 Connections
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/connections/request` | Send connection request. |
| PUT | `/connections/request/:requestId` | Accept/reject request. |
| GET | `/connections` | List of accepted connections. |
| GET | `/connections/pending` | List of pending requests received. |

### 5.4 Chat
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/messages/:connectionId` | Fetch chat history (paginated). |
| POST | `/messages/:connectionId` | Send message (text or media). |
| POST | `/messages/upload` | Get presigned URL for media upload to R2. |

### 5.5 Attention Seeker
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/attention/maturity/:userId` | Check if button is enabled for this connection. |
| POST | `/attention/log` | Log attention seeker session (duration). |

### 5.6 Premium & Ads
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/premium/status` | Check if user has active premium. |
| POST | `/premium/subscribe` | Handle subscription webhook (RevenueCat). |
| GET | `/ads/config` | Return AdMob unit IDs and frequency caps. |

---

## 6. Real‑Time Events (Socket.IO)

| Event Name | Direction | Payload | Description |
|------------|-----------|---------|-------------|
| `chat:message` | Client → Server | `{ connectionId, content, type, mediaUrl }` | Send new message. |
| `chat:message` | Server → Client | `{ message }` | Broadcast to recipient. |
| `typing:start` | Client → Server | `{ connectionId }` | User starts typing. |
| `typing:start` | Server → Client | `{ userId }` | Show typing indicator. |
| `typing:stop` | Client → Server | `{ connectionId }` | User stops typing. |
| `attention:start` | Client → Server | `{ toUserId }` | Request to start haptic. |
| `attention:start` | Server → Client | `{ fromUserId }` | Trigger vibration on recipient. |
| `attention:stop` | Client → Server | `{ toUserId }` | Request to stop haptic. |
| `attention:stop` | Server → Client | `{ fromUserId }` | Stop vibration on recipient. |
| `presence:online` | Server → Client | `{ userId }` | Notify when a connection comes online. |
| `presence:offline` | Server → Client | `{ userId }` | Notify when a connection goes offline. |

---

## 7. 5‑Month Development Timeline

### Month 1 – Foundation & Authentication
- **Week 1-2:** Project setup – Flutter, NestJS, PostgreSQL, Redis, Cloudflare R2.
- **Week 3:** Firebase Auth (Google login) + animated splash screen.
- **Week 4:** Profile creation screen (name, age, gender, interested in, comma‑separated interests, bio).
- **Milestone:** User can sign up, complete profile, and see “Profile saved”.

### Month 2 – Discovery & Privacy Core
- **Week 5-6:** Reel swiper component (vertical) + horizontal image swiper. Location snapshot (static). Distance calculation.
- **Week 7:** Matching algorithm (60/40) – API endpoint for discovery feed.
- **Week 8:** **Strict photo blur** – generate blurred versions on upload, serve blurred by default. Implement `photo_access` table and logic to unblur only after connection accepted.
- **Milestone:** User can swipe profiles, see blurred photos, like/connect.

### Month 3 – Connections & Basic Chat
- **Week 9:** Connection request system (send, accept, reject) with push notifications (FCM/APNs).
- **Week 10:** Real‑time chat (Socket.IO) – text only, typing indicator, read receipts, chat list.
- **Week 11:** Media sharing – chunked uploads to R2, virus scanning, thumbnail generation. Support up to 500 MB.
- **Week 12:** End‑to‑end encryption (Signal Protocol) for premium users; TLS + server encryption for free tier.
- **Milestone:** Users can connect, exchange text and media messages, and see read status.

### Month 4 – Premium Features & Attention Seeker
- **Week 13:** **Attention Seeker** – maturity logic, WebSocket events, vibration integration (Flutter vibration package), rate limiting.
- **Week 14:** Audio calls (Agora) for premium users.
- **Week 15:** Video calls (Agora) for premium users. Subscription integration (RevenueCat).
- **Week 16:** AdMob banners + interstitials for free tier. Settings screen for live location toggle.
- **Milestone:** Premium monetisation live; attention seeker fully functional.

### Month 5 – Polish, Admin & Launch
- **Week 17:** Face verification – on‑device ML Kit + hash submission, liveness check.
- **Week 18:** Admin panel (Retool) – user management, moderation, basic analytics.
- **Week 19:** Full testing – unit (Jest), integration (Detox), load testing (k6). Bug fixes.
- **Week 20:** Beta via TestFlight + Play Store Internal Track. Final app store assets, privacy policy, launch.
- **Milestone:** App published on iOS App Store and Google Play Store.

**Post‑launch (Months 6-9):** Couple games, custom sticker events, advanced attention seeker analytics, Android tablet / iPad support.

---

## 8. Security & Privacy Measures

| Area | Implementation |
|------|----------------|
| **Face data** | Never stored server‑side – only hash. |
| **Photo privacy** | Strict blur until connection accepted. No unblur by payment. |
| **Messages** | E2EE (Signal Protocol) for premium; TLS in transit, AES‑256 at rest for free tier. |
| **Location** | Default static snapshot; live location only when user enables and app in foreground. |
| **Reporting** | Users can report profiles/messages. Moderators use escrow key to decrypt reported E2EE messages (with user consent). |
| **GDPR/CCPA** | Account deletion endpoint, data export, cookie consent for ads. |

---

## 9. Monetisation & Pricing

| Tier | Price | Features |
|------|-------|----------|
| **Free** | $0 | – 10 likes/day<br>– Text & media chat (100 MB total, no E2EE)<br>– Ads (banner + interstitial)<br>– Static location only<br>– Attention seeker (limited 5 times/day) |
| **Premium** | $9.99/month or $79.99/year | – Unlimited likes<br>– No ads<br>– Audio & video calls<br>– E2EE for all messages<br>– 500 MB per file upload<br>– Live location streaming<br>– Attention seeker unlimited<br>– Read receipts & advanced filters (coming) |

**Alternative:** Sticker packs and event passes as one‑time purchases (post‑launch).

---

## 10. Risk Assessment & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-------------|
| 500 MB uploads slow on poor networks | Medium | Medium | Resumable chunked uploads with progress indicator; warn user on mobile data. |
| Attention seeker haptics drain battery | Low | Low | Vibration only while holding; user can disable in settings. |
| Face verification false positives | Low | High | Allow manual admin override + re‑verification flow. |
| E2EE implementation delay | High | High | Ship without E2EE in MVP, add as premium feature in Month 4. |
| App store rejection for “attention seeker” (vibration) | Low | Medium | Document feature as user‑initiated and optional; provide clear UI disclosure. |
| Scalability of Socket.IO | Medium | High | Use Redis adapter; plan for horizontal scaling; monitor with Prometheus. |

---

## 11. Success Metrics (KPIs)

| Metric | Target (3 months post‑launch) |
|--------|-------------------------------|
| Daily Active Users (DAU) | 5,000 |
| Matches per user per week | 3 |
| Conversion rate (free → premium) | 5% |
| Average chat messages per match | 20 |
| Attention Seeker usage (sessions/day per user) | 1.5 |
| Crash-free session rate | 99.5% |
| App store rating | ≥ 4.5 stars |

---

## 12. Development Team & Roles

| Role | Count | Responsibilities |
|------|-------|------------------|
| Flutter Developer | 2 | Frontend (UI, state management, integrations) |
| Backend Developer (NestJS) | 1 | API, database, real‑time services |
| DevOps / Mobile Engineer | 1 | CI/CD, cloud infrastructure, push notifications |
| UI/UX Designer | 1 (part‑time) | Design system, animations, asset creation |
| QA Engineer | 1 (from Month 3) | Manual + automated testing |

**Total estimated cost (5 months, outsourced in Eastern Europe):** ~$70,000 – $100,000.  
**In‑house (US):** ~$250,000+.

---

## 13. Appendices

### 13.1 Example User Flow
1. User opens app → animated loading screen → Google sign‑in.
2. Mandatory profile: enters name, age, gender, interests (type “Travel, Coffee” → chips). Uploads 4 photos (all blurred for others). Grants location permission.
3. Optional face verification (incentive: “Verified” badge).
4. Enters discovery reel – sees profiles of nearby users (blurred photos). Swipes up for next profile.
5. Likes a profile. Later sends a Connect request.
6. Recipient gets notification → accepts → both see unblurred photos.
7. Chat opens – they send text and a video. Attention seeker button appears after 100 messages.
8. User holds button → other user’s phone vibrates → feels presence.
9. Premium user starts video call.

### 13.2 Sample Comma‑Separated Interest Parser (Flutter)
```dart
List<String> parseInterests(String input) {
  return input.split(',')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();
}
```

### 13.3 Blurred Image Generation (Node.js Sharp)
```javascript
const sharp = require('sharp');
async function blurImage(inputBuffer) {
  return await sharp(inputBuffer)
    .blur(20)  // heavy blur
    .toBuffer();
}
```

---

## 14. Conclusion

The **Meet-Up** project is ambitious but achievable within 5 months by prioritising the core differentiators: strict photo privacy, attention seeker haptics, privacy‑preserving face verification, and a reel‑style discovery. The plan above provides a clear roadmap, from technical stack to database schema to week‑by‑week milestones. Post‑launch features (games, stickers) will keep users engaged while the team iterates on feedback.

**Next step:** Approve this plan and begin Month 1 – Foundation & Authentication.

--- 
*Document version 1.0 – Last updated: April 2026*
```
