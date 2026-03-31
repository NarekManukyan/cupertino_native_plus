# Roadmap to v1.1.0

We are planning a major update to make `cupertino_native_better` feel more fluid, premium, and "alive". This roadmap outlines the key features and improvements targeted for version 1.1.0.

## 🚀 New Features (The "Wow" Factor)

### 1. `CNGlassCard` (The "Smart" Container)
A pre-styled Card widget that mimics the "Apple Intelligence" or "Siri" glow effects seen in recent iOS updates.
- **Why:** Users want "alive" interfaces. A card that subtly reacts to being held is very "premium native".
- **Features:**
  - `breathing: true`: Optional subtle pulsing glow/border.
  - `spotlight: Offset`: A light source that follows the user's touch or gyroscope.

### 2. `CNFloatingIsland` (Dynamic Island Style)
A persistent, floating pill at the bottom (or top) of the screen that can expand.
- **Why:** Flutter's `SnackBar` is rigid. A fluid, glass-morphic floating element allows for beautiful notifications or music controls.
- **Tech:** Uses SwiftUI `matchedGeometryEffect` to morph between states smoothly.

### 3. Implicit Animations
Currently, changing a button's color or size "snaps" to the new state.
- **Update:** Add `.animation(.easeInOut)` to all SwiftUI views.
- **Result:** When Flutter sends a new color/size, the native side smoothly transitions to it. This creates the "Liquid" feel.

## 🛠 Core Optimizations

### 1. Native Image Caching
- **Issue:** Passing `Uint8List` (custom icon bytes) over the method channel repeatedly is expensive.
- **Solution:** Implement a native image cache on the Swift side. Hash the bytes and reuse the `UIImage` if the hash matches, reducing bridge traffic significantly.

## 🧱 Architectural Improvements

### 1. Data Models for Groups
- **Refactor:** Change `CNGlassButtonGroup` to accept a list of data objects (`CNGroupItem`) instead of widget instances (`CNButton`).
- **Benefit:** This is lighter on the Flutter framework and separates configuration from the widget tree.

---

*Note: This roadmap is a proposal and subject to change based on feasibility and user feedback.*

