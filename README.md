# 📸 Get-NPSWebcams.ps1

> Retrieve, cache, and audit webcam data from the National Park Service (NPS) API.

---

## 🚀 Overview

`Get-NPSWebcams.ps1` is a PowerShell script that:

- Fetches webcam metadata from the NPS API
- Caches results locally (`nps-webcams.json`)
- Provides powerful auditing and search capabilities

Use it to quickly explore, validate, and analyze NPS webcam data without repeatedly hitting the API.

---

## ⚙️ Usage

```powershell
.\Get-NPSWebcams.ps1
    [-findDupes]
    [-findInactive]
    [-findActive]
    [-findByID <String>]
    [-findTitle <String>]
    [-findDescription <String>]
    [-findCredit <String>]
    [-findStreaming]
    [-findTag <String>]
    [-findLatLong <String>]
```

---

## 🔍 Features

### 📦 Data Retrieval

- Pulls webcam data from the NPS API
- Stores results locally for reuse
- Cache is valid for the current calendar day

### 🧪 Auditing Tools

- Detect duplicate webcam IDs
- Identify active vs inactive webcams
- Filter currently streaming webcams

### 🔎 Search Capabilities

- Lookup by:
  - ID (UUID)
  - Title (case-insensitive substring)
  - Description (case-insensitive substring)
  - Credit (case-insensitive substring)
  - Tag (exact case-insensitive match)
  - Latitude/Longitude (case-insensitive substring)

---

## 🧩 Parameters

| Parameter          | Type   | Description                                      |
| ------------------ | ------ | ------------------------------------------------ |
| `-findDupes`       | Switch | Find duplicate webcam IDs                        |
| `-findInactive`    | Switch | List webcams with status `"Inactive"`            |
| `-findActive`      | Switch | List webcams with status `"Active"`              |
| `-findByID`        | String | Find a webcam by its unique ID (UUID)            |
| `-findTitle`       | String | Search webcam titles (case-insensitive)          |
| `-findDescription` | String | Search webcam descriptions (case-insensitive)    |
| `-findCredit`      | String | Search webcam credit metadata (case-insensitive) |
| `-findStreaming`   | Switch | Filter webcams currently streaming               |
| `-findTag`         | String | Filter by exact tag (case-insensitive)           |
| `-findLatLong`     | String | Search coordinates (case-insensitive substring)   |

---

## 🔐 Requirements

- Environment variable must be set:

```powershell
$env:NPS_API_KEY = "your-api-key-here"
```

---

## 📁 Cache Behavior

- File: `nps-webcams.json`
- Automatically refreshed once per calendar day
- Used for all audit/search operations

---

## 🧪 Examples

### 1️⃣ Fetch latest data

```powershell
.\Get-NPSWebcams.ps1
```

### 2️⃣ Find duplicate IDs

```powershell
.\Get-NPSWebcams.ps1 -findDupes
```

### 3️⃣ List inactive webcams

```powershell
.\Get-NPSWebcams.ps1 -findInactive
```

### 4️⃣ List active webcams

```powershell
.\Get-NPSWebcams.ps1 -findActive
```

### 5️⃣ Search by title

```powershell
.\Get-NPSWebcams.ps1 -findTitle "Dark Sky"
```

### 6️⃣ Search by credit

```powershell
.\Get-NPSWebcams.ps1 -findCredit "NPS Photo"
```

### 7️⃣ Search by description

```powershell
.\Get-NPSWebcams.ps1 -findDescription "pandas"
```

### 8️⃣ Find by ID

```powershell
.\Get-NPSWebcams.ps1 -findByID "7388A31D-219C-4061-9040-272E27893264"
```

### 9️⃣ Show streaming webcams

```powershell
.\Get-NPSWebcams.ps1 -findStreaming
```

### 🔟 Filter by tag

```powershell
.\Get-NPSWebcams.ps1 -findTag "eagle"
```

### 1️⃣1️⃣ Search by coordinates

```powershell
.\Get-NPSWebcams.ps1 -findLatLong "42.896, -122.133"
```

---

## 🔗 Related Links

- NPS API (Webcams):
  [https://developer.nps.gov/api/v1/webcams](https://developer.nps.gov/api/v1/webcams)

---

## 📝 Notes

- All searches are **case-insensitive** and **literal** (no wildcards)
- Designed for quick audits and local analysis
- Avoids unnecessary API calls via caching

---

## 💡 Tip

Combine parameters thoughtfully—this script is optimized for **single-purpose queries per run** for clarity and performance.

---

Enjoy exploring National Park webcams! 🌄
