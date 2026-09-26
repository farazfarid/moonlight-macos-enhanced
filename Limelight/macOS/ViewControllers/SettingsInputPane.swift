//
//  SettingsView.swift
//  Moonlight for macOS
//
//  Created by Michael Kenny on 15/1/2024.
//  Copyright © 2024 Moonlight Game Streaming Project. All rights reserved.
//

import AVFoundation
import AppKit
import Carbon.HIToolbox
import CoreGraphics
import GameController
import SwiftUI

struct InputView: View {
  @EnvironmentObject private var settingsModel: SettingsModel
  @ObservedObject var languageManager = LanguageManager.shared
  @ObservedObject private var inputMonitoringManager = InputMonitoringPermissionManager.sharedManager
  @StateObject private var controllerTester = ControllerTestMonitor()
  @AppStorage("settings.input.mouseAdvancedExpanded") private var mouseAdvancedExpanded = false
  @AppStorage("settings.input.mouseTuningExpanded") private var mouseTuningExpanded = false
  @AppStorage("settings.input.controllerAdvancedExpanded") private var controllerAdvancedExpanded =
    false

  private var selectedMouseStrategy: MouseInputDriverStrategy {
    MouseInputDriverStrategy(selection: settingsModel.selectedMouseDriver)
  }

  private var coreHIDTuningEnabled: Bool {
    selectedMouseStrategy == .coreHID || selectedMouseStrategy == .automatic
  }

  private var showsFreeMouseOptions: Bool {
    settingsModel.mouseMode == "remote"
  }

  private var settingsHostKey: String {
    settingsModel.selectedHost?.id ?? SettingsModel.globalHostId
  }

  private var clipboardSyncAvailableForSelectedHost: Bool {
    SettingsClass.clipboardSyncSupported(for: settingsHostKey)
  }

  private var clipboardSyncDetailKey: String {
    clipboardSyncAvailableForSelectedHost
      ? "Clipboard Sync detail"
      : "Clipboard Sync Foundation detail"
  }

  private var showsHighPrecisionWheelTuning: Bool {
    settingsModel.selectedPhysicalWheelMode == PhysicalWheelScrollMode.automatic.displayKey
      || settingsModel.selectedPhysicalWheelMode
        == PhysicalWheelScrollMode.highPrecision.displayKey
      || settingsModel.physicalWheelHighPrecisionScale
        != SettingsModel.defaultPhysicalWheelHighPrecisionScale
  }

  private var showsSmoothWheelTailFilter: Bool {
    settingsModel.selectedRewrittenScrollMode != RewrittenScrollMode.notched.displayKey
      || settingsModel.smartWheelTailFilter > 0.0001
  }

  private var selectedKeyboardTranslationDetailKey: String {
    switch KeyboardCompatibilityMode(selection: settingsModel.selectedKeyboardCompatibilityMode) {
    case .standard:
      return "Shortcut Translation Mode Keep Mac detail"
    case .commandToControl:
      return "Shortcut Translation Mode CommandToControl detail"
    case .swapLeftControlAndWin:
      return "Shortcut Translation Mode SwapLeftControlAndWin detail"
    case .shortcutTranslation:
      return "Shortcut Translation Mode ShortcutTranslation detail"
    case .hybrid:
      return "Shortcut Translation Mode Hybrid detail"
    }
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 32) {
        mouseSection
        keyboardSection
        controllerSection
      }
      .padding()
    }
  }

  private var mouseSection: some View {
    FormSection(title: "Mouse") {
      PickerSettingRow(
        title: "Mouse Mode",
        detailKey: "Mouse Mode detail",
        content: {
          Picker("", selection: $settingsModel.mouseMode) {
            Label(languageManager.localize("Locked Mouse"), systemImage: "gamecontroller")
              .tag("game")
            Label(languageManager.localize("Free Mouse"), systemImage: "cursorarrow.motionlines")
              .tag("remote")
          }
          .labelsHidden()
        })

      Divider()

      PickerSettingRow(
        title: "Mouse Driver",
        content: {
          Picker("", selection: $settingsModel.selectedMouseDriver) {
            ForEach(SettingsModel.mouseDrivers, id: \.self) { mode in
              if mode == MouseInputDriverStrategy.automatic.displayKey {
                Text("\(languageManager.localize(mode)) · \(languageManager.localize("Recommended"))")
              } else {
                Text(languageManager.localize(mode))
              }
            }
          }
          .labelsHidden()
        })

      Divider()

      if coreHIDTuningEnabled {
        CoreHIDPermissionRow(permissionManager: inputMonitoringManager)

        Divider()
      }

      if showsFreeMouseOptions {
        PickerSettingRow(
          title: "Free Mouse Movement",
          content: {
            Picker("", selection: $settingsModel.selectedFreeMouseMotionMode) {
              ForEach(SettingsModel.freeMouseMotionModes, id: \.self) { mode in
                Text(languageManager.localize(mode))
              }
            }
            .labelsHidden()
          })

        Divider()
      }

      clipboardSyncRow

      Divider()

      DisclosureGroup(
        isExpanded: $mouseTuningExpanded,
        content: {
          VStack(alignment: .leading, spacing: 16) {
            MouseTuningSliderRow(
              title: "Pointer Speed",
              value: $settingsModel.pointerSensitivity,
              range: 0.25...3.0,
              step: 0.05,
              minLabel: "25%",
              maxLabel: "300%"
            )

            Divider()

            InlineSectionLabel(title: "Wheel")

            PickerSettingRow(
              title: "Physical Wheel Mode",
              content: {
                Picker("", selection: $settingsModel.selectedPhysicalWheelMode) {
                  ForEach(SettingsModel.physicalWheelModes, id: \.self) { mode in
                    Text(languageManager.localize(mode))
                  }
                }
                .labelsHidden()
              })

            Divider()

            MouseTuningSliderRow(
              title: "Physical Wheel Speed",
              value: $settingsModel.wheelScrollSpeed,
              range: 0.1...4.0,
              step: 0.05,
              minLabel: "10%",
              maxLabel: "400%"
            )

            if showsHighPrecisionWheelTuning {
              Divider()

              MouseTuningSliderRow(
                title: "High Precision Wheel Speed",
                value: $settingsModel.physicalWheelHighPrecisionScale,
                range: 1.0...12.0,
                step: 0.25,
                minLabel: "1×",
                maxLabel: "12×",
                valueFormatter: { value in
                  String(format: "%.2fx", value)
                }
              )
            }

            Divider()

            PickerSettingRow(
              title: "Smooth Wheel Mode",
              content: {
                Picker("", selection: $settingsModel.selectedRewrittenScrollMode) {
                  ForEach(SettingsModel.rewrittenScrollModes, id: \.self) { mode in
                    Text(languageManager.localize(mode))
                  }
                }
                .labelsHidden()
              })

            Divider()

            MouseTuningSliderRow(
              title: "Smooth Wheel Speed",
              value: $settingsModel.rewrittenScrollSpeed,
              range: 0.1...4.0,
              step: 0.05,
              minLabel: "10%",
              maxLabel: "400%"
            )

            if showsSmoothWheelTailFilter {
              Divider()

              MouseTuningSliderRow(
                title: "Smooth Wheel Tail Filter",
                value: $settingsModel.smartWheelTailFilter,
                range: 0.0...1.0,
                step: 0.02,
                minLabel: "Off",
                maxLabel: "1.00",
                valueFormatter: { value in
                  value <= 0.0001 ? languageManager.localize("Off") : String(format: "%.2f", value)
                }
              )
            }

            Divider()

            MouseTuningSliderRow(
              title: "Trackpad Speed",
              value: $settingsModel.gestureScrollSpeed,
              range: 0.1...4.0,
              step: 0.05,
              minLabel: "10%",
              maxLabel: "400%"
            )
          }
          .padding(.top, 8)
        },
        label: {
          SettingsDisclosureLabel(title: "Pointer & Scroll Tuning")
        }
      )

      Divider()

      ToggleCell(
        title: "Reverse Mouse Scrolling Direction",
        boolBinding: $settingsModel.reverseScrollDirection
      )

      Divider()

      ToggleCell(
        title: "Show Local Cursor",
        boolBinding: $settingsModel.showLocalCursor
      )

      Divider()

      DisclosureGroup(
        isExpanded: $mouseAdvancedExpanded,
        content: {
          AdvancedSettingsCard {
            VStack(alignment: .leading, spacing: 16) {
              PickerSettingRow(
                title: "CoreHID Max Mouse Report Rate",
                hintKey: "CoreHID Max Mouse Report Rate detail",
                content: {
                  Picker("", selection: $settingsModel.coreHIDMaxMouseReportRate) {
                    ForEach(SettingsModel.coreHIDMaxMouseReportRates, id: \.self) { rate in
                      Text(SettingsModel.coreHIDMaxMouseReportRateLabel(rate))
                        .tag(rate)
                    }
                  }
                  .labelsHidden()
                  .disabled(!coreHIDTuningEnabled)
                })

              Divider()

              ToggleCell(
                title: "Swap Left and Right Mouse Buttons",
                boolBinding: $settingsModel.swapMouseButtons
              )

              Divider()

              PickerSettingRow(
                title: "Touchscreen Mode",
                stacked: true,
                content: {
                  Picker("", selection: $settingsModel.selectedTouchscreenMode) {
                    ForEach(SettingsModel.touchscreenModes, id: \.self) { mode in
                      Text(languageManager.localize(mode))
                    }
                  }
                  .labelsHidden()
                })
            }
          }
        },
        label: {
          SettingsDisclosureLabel(title: "Advanced Mouse Settings")
        }
      )
    }
    .onAppear {
      DispatchQueue.main.async {
        inputMonitoringManager.refreshAuthorizationStatus()
      }
    }
  }

  private var keyboardSection: some View {
    FormSection(title: "Keyboard") {
      PickerSettingRow(
        title: "Keyboard Compatibility",
        detailKey: selectedKeyboardTranslationDetailKey,
        content: {
          Picker("", selection: $settingsModel.selectedKeyboardCompatibilityMode) {
            ForEach(SettingsModel.keyboardCompatibilityModes, id: \.self) { mode in
              Text(languageManager.localize(mode))
            }
          }
          .labelsHidden()
        })

      Divider()

      ToggleCell(
        title: "Capture system keyboard shortcuts",
        boolBinding: $settingsModel.captureSystemShortcuts
      )

      Divider()

      KeyboardTranslationRulesView(settingsModel: settingsModel)

      Divider()

      ShortcutReferenceView(settingsModel: settingsModel)
    }
  }

  private var controllerSection: some View {
    FormSection(title: "Controller") {
      PickerSettingRow(
        title: "Multi-Controller Mode",
        stacked: true,
        content: {
          Picker("", selection: $settingsModel.selectedMultiControllerMode) {
            ForEach(SettingsModel.multiControllerModes, id: \.self) { mode in
              Text(languageManager.localize(mode))
            }
          }
          .labelsHidden()
        })

      Divider()

      ToggleCell(title: "Rumble Controller", boolBinding: $settingsModel.rumble)

      Divider()

      ControllerTestCard(monitor: controllerTester)

      Divider()

      DisclosureGroup(
        isExpanded: $controllerAdvancedExpanded,
        content: {
          AdvancedSettingsCard {
            VStack(alignment: .leading, spacing: 14) {
              PickerSettingRow(
                title: "Controller Driver",
                stacked: true,
                content: {
                  Picker("", selection: $settingsModel.selectedControllerDriver) {
                    ForEach(SettingsModel.controllerDrivers, id: \.self) { mode in
                      Text(languageManager.localize(mode))
                    }
                  }
                  .labelsHidden()
                })

              Divider()

              ToggleCell(
                title: "Swap A/B and X/Y Buttons",
                boolBinding: $settingsModel.swapButtons
              )

              Divider()

              ToggleCell(
                title: "Emulate Guide Button",
                boolBinding: $settingsModel.emulateGuide
              )

              Divider()

              ToggleCell(
                title: "Gamepad Mouse Emulation",
                hintKey: "Gamepad Mouse Hint",
                boolBinding: $settingsModel.gamepadMouseMode
              )
            }
          }
        },
        label: {
          SettingsDisclosureLabel(title: "Advanced Controller Settings")
        }
      )
    }
  }

  private var clipboardSyncRow: some View {
    PickerSettingRow(
      title: "Clipboard Sync",
      detailKey: clipboardSyncDetailKey,
      content: {
        Picker("", selection: $settingsModel.selectedClipboardSyncMode) {
          ForEach(SettingsModel.clipboardSyncModes, id: \.self) { mode in
            Text(languageManager.localize(mode))
          }
        }
        .labelsHidden()
      })
  }
}

@MainActor
private final class ControllerTestMonitor: ObservableObject {
  struct Device: Identifiable {
    let id: ObjectIdentifier
    let name: String
    let layout: String
  }

  @Published private(set) var devices: [Device] = []
  @Published private(set) var lastInput = "Waiting for a button press"
  @Published private(set) var receivedInputCount = 0

  private var connectObserver: NSObjectProtocol?
  private var disconnectObserver: NSObjectProtocol?
  private var installedControllerIDs = Set<ObjectIdentifier>()

  init() {
    connectObserver = NotificationCenter.default.addObserver(
      forName: .GCControllerDidConnect, object: nil, queue: .main
    ) { [weak self] _ in
      self?.refresh()
    }
    disconnectObserver = NotificationCenter.default.addObserver(
      forName: .GCControllerDidDisconnect, object: nil, queue: .main
    ) { [weak self] _ in
      self?.refresh()
    }
    refresh()
  }

  deinit {
    if let connectObserver { NotificationCenter.default.removeObserver(connectObserver) }
    if let disconnectObserver { NotificationCenter.default.removeObserver(disconnectObserver) }
  }

  func refresh() {
    let controllers = GCController.controllers()
    devices = controllers.compactMap { controller in
      guard controller.extendedGamepad != nil || controller.gamepad != nil else { return nil }
      installButtonObservers(on: controller)
      return Device(
        id: ObjectIdentifier(controller),
        name: controller.vendorName ?? "Game Controller",
        layout: controller.extendedGamepad != nil ? "Extended gamepad" : "Standard gamepad"
      )
    }

    if devices.isEmpty {
      lastInput = "No compatible controller detected"
    }
  }

  private func installButtonObservers(on controller: GCController) {
    let identifier = ObjectIdentifier(controller)
    guard installedControllerIDs.insert(identifier).inserted else { return }

    guard let gamepad = controller.extendedGamepad else { return }
    observe(gamepad.buttonA, name: "A / Cross")
    observe(gamepad.buttonB, name: "B / Circle")
    observe(gamepad.buttonX, name: "X / Square")
    observe(gamepad.buttonY, name: "Y / Triangle")
    observe(gamepad.leftShoulder, name: "L1")
    observe(gamepad.rightShoulder, name: "R1")
    observe(gamepad.buttonMenu, name: "Menu / Options")
    if let buttonOptions = gamepad.buttonOptions {
      observe(buttonOptions, name: "Options / Share")
    }
    if let buttonHome = gamepad.buttonHome {
      observe(buttonHome, name: "PS / Home")
    }
  }

  private func observe(_ button: GCControllerButtonInput, name: String) {
    button.pressedChangedHandler = { [weak self] _, _, pressed in
      guard pressed else { return }
      DispatchQueue.main.async {
        self?.lastInput = "Received: \(name)"
        self?.receivedInputCount += 1
      }
    }
  }
}

private struct ControllerTestCard: View {
  @ObservedObject var monitor: ControllerTestMonitor

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Label("Controller Test", systemImage: "gamecontroller.fill")
          .font(.subheadline.weight(.semibold))
        Spacer()
        Button("Refresh") { monitor.refresh() }
          .buttonStyle(.borderless)
      }

      if monitor.devices.isEmpty {
        Label("No compatible controller detected. Connect or wake your controller, then choose Refresh.", systemImage: "exclamationmark.triangle")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        ForEach(monitor.devices) { device in
          VStack(alignment: .leading, spacing: 2) {
            Text(device.name)
              .font(.subheadline.weight(.medium))
            Text(device.layout)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        HStack(spacing: 8) {
          Circle()
            .fill(monitor.receivedInputCount > 0 ? Color.green : Color.orange)
            .frame(width: 8, height: 8)
          Text(monitor.lastInput)
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          Text("\(monitor.receivedInputCount) events")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

        Text("This only verifies macOS input. Start a stream afterward to verify forwarding to Sunshine.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 2)
  }
}

private struct SettingsDisclosureLabel: View {
  let title: String
  @ObservedObject var languageManager = LanguageManager.shared

  var body: some View {
    HStack(spacing: 8) {
      Text(languageManager.localize(title))
        .font(.subheadline.weight(.medium))
      Spacer(minLength: 12)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

private struct PickerSettingRow<Content: View>: View {
  let title: String
  let hintKey: String?
  let detailKey: String?
  let stacked: Bool
  let content: Content
  @ObservedObject var languageManager = LanguageManager.shared

  init(
    title: String,
    hintKey: String? = nil,
    detailKey: String? = nil,
    stacked: Bool = false,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.hintKey = hintKey
    self.detailKey = detailKey
    self.stacked = stacked
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if stacked {
        HStack(spacing: 6) {
          Text(languageManager.localize(title))
          if let hintKey {
            InfoHintButton(hintKey: hintKey)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        content
          .frame(maxWidth: .infinity, alignment: .trailing)
      } else {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          HStack(spacing: 6) {
            Text(languageManager.localize(title))
            if let hintKey {
              InfoHintButton(hintKey: hintKey)
            }
          }
          Spacer(minLength: 12)
          content
            .fixedSize(horizontal: true, vertical: false)
        }
      }

      if let detailKey {
        SettingDescriptionRow(textKey: detailKey)
      }
    }
  }
}

private struct MouseTuningSliderRow: View {
  let title: String
  let hintKey: String? = nil
  let detailKey: String? = nil
  @Binding var value: CGFloat
  let range: ClosedRange<CGFloat>
  let step: CGFloat
  let minLabel: String
  let maxLabel: String
  var valueFormatter: ((CGFloat) -> String)? = nil
  @ObservedObject var languageManager = LanguageManager.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        HStack(spacing: 6) {
          Text(languageManager.localize(title))
          if let hintKey {
            InfoHintButton(hintKey: hintKey)
          }
        }
        Spacer()
        Text(displayValue)
          .availableMonospacedDigit()
          .foregroundColor(.secondary)
      }

      Slider(value: $value, in: range, step: step) {
        EmptyView()
      } minimumValueLabel: {
        Text(minLabel)
          .font(.caption)
          .availableMonospacedDigit()
      } maximumValueLabel: {
        Text(maxLabel)
          .font(.caption)
          .availableMonospacedDigit()
      } onEditingChanged: { _ in

      }
      if let detailKey {
        SettingDescriptionRow(textKey: detailKey)
      }
    }
  }

  private var displayValue: String {
    if let valueFormatter {
      return valueFormatter(value)
    }
    return SettingsModel.percentageLabel(for: value)
  }
}

private struct CoreHIDPermissionRow: View {
  @ObservedObject var permissionManager: InputMonitoringPermissionManager
  @ObservedObject var languageManager = LanguageManager.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(languageManager.localize("Input Monitoring"))
        Spacer()
        trailingContent
      }

      SettingDescriptionRow(textKey: "Input Monitoring detail")

      if let supplementalMessageKey = permissionManager.supplementalStatusMessageKey {
        Text(languageManager.localize(supplementalMessageKey))
          .font(.footnote)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      } else if let failureMessage = permissionManager.rawFailureMessageForDisplay {
        Text(failureMessage)
          .font(.footnote)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  @ViewBuilder
  private var trailingContent: some View {
    if permissionManager.isRequestingAuthorization {
      ProgressView()
        .controlSize(.small)
    } else {
      switch permissionManager.displayStatusLabelKey {
      case "Granted":
        Label(languageManager.localize("Granted"), systemImage: "checkmark.circle.fill")
          .foregroundColor(.green)
          .font(.callout)
      case "Granted Pending Reentry":
        Label(languageManager.localize("Granted Pending Reentry"), systemImage: "arrow.triangle.2.circlepath.circle.fill")
          .foregroundColor(.green)
          .font(.callout)
      case "Checking":
        HStack(spacing: 8) {
          Text(languageManager.localize("Checking"))
            .foregroundColor(.secondary)
            .font(.callout)
          Button(languageManager.localize("Open Settings")) {
            permissionManager.openSystemPreferences()
          }
          .controlSize(.small)
        }
      case "Check Settings", "Denied":
        HStack(spacing: 8) {
          Text(languageManager.localize(permissionManager.displayStatusLabelKey))
            .foregroundColor(.secondary)
            .font(.callout)
          Button(languageManager.localize("Open Settings")) {
            permissionManager.openSystemPreferences()
          }
          .controlSize(.small)
        }
      case "Not Granted":
        HStack(spacing: 8) {
          Text(languageManager.localize("Not Granted"))
            .foregroundColor(.secondary)
            .font(.callout)
          Button(languageManager.localize("Request")) {
            permissionManager.requestAuthorization()
          }
          .controlSize(.small)
        }
      case "Unavailable":
        Text(languageManager.localize("Unavailable"))
          .foregroundColor(.secondary)
          .font(.callout)
      default:
        Text(languageManager.localize("Not Granted"))
          .foregroundColor(.secondary)
          .font(.callout)
      }
    }
  }
}

private struct AdvancedSettingsCard<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(.top, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
