# Project Identity

**專案名稱**：HexGear
**目標**：HexGear 是一款專為 macOS 設計的顏色處理與轉換工具。核心功能涵蓋顏色轉換 (Converter)、顏色混合 (Blender)、影像色票擷取 (Image Palette) 以及無障礙色彩對比度檢查 (WCAG Logic)。目標是提供開發者與設計師高效、準確且原生的 macOS 桌面應用體驗，並支援 Menu Bar 快速操作。

# Technical Standards

## Swift 語法規範
- **併發與狀態管理**：使用現代 Swift 語法，狀態管理高度依賴 SwiftUI 的 `@StateObject`, `@EnvironmentObject`（如 `AppState`, `StoreManager`）。
- **macOS 原生整合**：善用 macOS 專屬的 SwiftUI API (如 `MenuBarExtra`, `Window`, `windowResizability`)，並在必要時安全地調用 `NSApp` 進行原生視窗控制。
- **資料安全**：處理圖片解析 (`ColorExtractor`) 或複雜背景運算時，優先確保運算不會阻塞主執行緒 (Main Thread)，保持 UI 的流暢性。

## SwiftUI 排版與開發慣例
- **架構模式**：採用簡約的狀態管理架構，透過全域 `AppState` 控制核心邏輯與歷史資料，並使用小型 View 組件分離介面。請維持 View 的輕量化。
- **樣式與顏色**：鼓勵使用 `Color+Extensions` 進行顏色定義與操作。UI 佈局應遵循 macOS 適當的邊距 (Padding) 與最小視窗尺寸限制（例如：`minWidth`, `minHeight` 的設置，如 `ContentView` 中的設定）。
- **組件共用**：將跨分頁共通的視圖或樣式抽取並放置於 `SharedViews.swift` 以提升重用度並降低維護成本。

# File Structure

專案採用相對扁平但功能明確的歸檔方式（主要集中於 `/HexGear` 目錄）：
- **/HexGear**：包含專案所有主要視圖與邏輯檔案。
  - **核心視圖 (Views)**：`ContentView.swift`（主導航）, `ConverterView.swift`, `BlenderView.swift`, `ImagePaletteView.swift`。
  - **全域狀態 (State / Manager)**：`AppState.swift`, `StoreManager.swift`（處理內購與贊助贊助頁面 `SponsorshipView`）。
  - **邏輯處理 (Logic / Helpers)**：`ColorExtractor.swift`, `CodeFormat.swift`, `WCAGLogic.swift` (無障礙對比度邏輯)。
  - **輔助與擴充 (Extensions / Shared Views)**：`Color+Extensions.swift`, `SharedViews.swift`。
- **/HexGearTests & /HexGearUITests**：測試模組目錄，未來若撰寫測試，應著重於顏色轉換 (`CodeFormat`) 以及無障礙對比 (`WCAGLogic`) 等核心演算法邏輯。

# Naming Conventions

- **變數與常數 (Variables/Constants)**：使用 `camelCase`。與狀態或綁定相關的屬性，應清楚表達其意圖（例如：`selectedTab`, `codeFormat`）。
- **函式 (Functions)**：使用 `camelCase`，動詞開頭，直白表達行為（如 `extractColors`）。
- **視圖 (Views)**：使用 `PascalCase` 並一律以 `View` 作為後綴（例如：`BlenderView`, `ConverterView`）。
- **資料類型與邏輯層 (Types & Logic)**：使用 `PascalCase`，清楚表達核心用途，例如 `AppState`, `WCAGLogic`, `ColorExtractor`。

# Performance & Token Optimization

> [!IMPORTANT]
> **給 Agent 的優化與節能指南 (核心守則)：**
> 為了節省 Token 消耗、避免觸發使用者的每週額度鎖定，並提昇開發精度，你在本專案執行任務時，嚴格遵守以下規則：

1. **精準讀取 (Precision Reading)**：禁止盲目使用全檔案讀取。優先使用 `grep_search` 定位目標；使用 `view_file` 時，務必使用 `StartLine` 與 `EndLine` 參數限縮範圍（尤其是像 `ColorExtractor.swift` 這類破百行的複雜邏輯檔案）。
2. **避免全域掃描 (No Global Scans)**：若需要了解系統結構，應先詢問使用者提供路徑或參考既有架構，**嚴禁發起跨整個 Repository 的大範圍搜尋**。
3. **聚焦式代碼輸出 (Focused Code Generation)**：生成或建議修復程式碼時，**只提供有實際變更的核心邏輯區塊**。對於未修改的部分（如無關的 UI 佈局或變數宣告），一律使用 `// ... (保留既有代碼)` 略過，堅決不回傳數百行的完整代碼。
4. **高風險攔截與序列化執行 (Risk Interception & Serialization)**：每次對話僅限讀取和編輯單一檔案。若要求牽涉修改超過三個檔案的重構，你必須**立刻停止動作，並向使用者提報「序列化執行計畫」(Step-by-Step Plan)**，待使用者確認與同意後，才能按步驟逐步推進。
