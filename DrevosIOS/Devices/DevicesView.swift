import SwiftUI

struct DevicesView: View {
    @StateObject private var model = DevicesViewModel()
    @ObservedObject private var active = ActiveSmokerStore.shared
    @State private var showAdd = false
    @State private var renameTarget: DeviceItem?
    @State private var removeTarget: DeviceItem?

    var body: some View {
        ZStack {
            DrevosTheme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Devices").font(.system(size: 28, weight: .semibold)).foregroundStyle(DrevosTheme.text)
                        Text("Tap a smoker to choose which one to control").font(.system(size: 13)).foregroundStyle(DrevosTheme.muted)
                    }
                    Spacer()
                    Button("+ Add") { showAdd = true }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 86, height: 44)
                        .background(DrevosTheme.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let error = model.errorMessage { StatusBanner(text: error, color: DrevosTheme.danger, dismiss: model.clearMessage) }
                if let info = model.infoMessage { StatusBanner(text: info, color: DrevosTheme.orange, dismiss: model.clearMessage) }

                if model.isLoading {
                    Spacer(); ProgressView().tint(DrevosTheme.orange); Spacer()
                } else if model.devices.isEmpty {
                    EmptyDevicesView { showAdd = true }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(model.devices) { device in
                                DeviceCard(
                                    device: device,
                                    selected: active.smokerId == device.id,
                                    select: { model.select(device.id) },
                                    rename: { renameTarget = device },
                                    remove: { removeTarget = device }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
        .sheet(isPresented: $showAdd) { AddDeviceSheet(model: model) }
        .sheet(item: $renameTarget) { device in RenameDeviceSheet(model: model, device: device) }
        .confirmationDialog("Remove smoker?", isPresented: Binding(get: { removeTarget != nil }, set: { if !$0 { removeTarget = nil } })) {
            Button("Remove", role: .destructive) {
                guard let device = removeTarget else { return }
                Task { _ = await model.remove(device); removeTarget = nil }
            }
            Button("Cancel", role: .cancel) { removeTarget = nil }
        } message: {
            Text("This only removes the smoker from your account. Other linked users are unaffected.")
        }
    }
}

private struct DeviceCard: View {
    let device: DeviceItem
    let selected: Bool
    let select: () -> Void
    let rename: () -> Void
    let remove: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("D")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DrevosTheme.orange)
                    .frame(width: 46, height: 46)
                    .background(Color(hex: 0x252525))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(device.name).font(.system(size: 18, weight: .semibold)).foregroundStyle(DrevosTheme.text)
                    Text("ID: \(device.id)").font(.system(size: 12)).foregroundStyle(DrevosTheme.muted)
                }
                Spacer()
                if selected {
                    Text("CONTROLLING")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DrevosTheme.orange)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(DrevosTheme.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            HStack(spacing: 10) {
                ActionOutlineButton(title: "Edit name", color: DrevosTheme.text, action: rename)
                ActionOutlineButton(title: "Remove", color: DrevosTheme.danger, action: remove)
            }
        }
        .padding(16)
        .background(selected ? DrevosTheme.selected : DrevosTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? DrevosTheme.orange : DrevosTheme.border, lineWidth: selected ? 1.5 : 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
    }
}

private struct ActionOutlineButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(title, action: action)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity).frame(height: 40)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.55)))
    }
}

private struct EmptyDevicesView: View {
    let add: () -> Void
    var body: some View {
        VStack(spacing: 9) {
            Text("No smokers connected").font(.system(size: 18, weight: .semibold)).foregroundStyle(DrevosTheme.text)
            Text("Add a smoker with its ID.").font(.system(size: 13)).foregroundStyle(DrevosTheme.muted)
            Button("Add a smoker", action: add)
                .fontWeight(.semibold).foregroundStyle(.white)
                .padding(.horizontal, 20).frame(height: 44)
                .background(DrevosTheme.orange).clipShape(RoundedRectangle(cornerRadius: 11))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity).padding(22)
        .background(DrevosTheme.panel).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DrevosTheme.border))
    }
}

private struct StatusBanner: View {
    let text: String
    let color: Color
    let dismiss: () -> Void
    var body: some View {
        HStack {
            Text(text).font(.caption).foregroundStyle(DrevosTheme.text)
            Spacer()
            Button("OK", action: dismiss).foregroundStyle(color)
        }
        .padding(12).background(DrevosTheme.panel).clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(color.opacity(0.6)))
    }
}

private struct AddDeviceSheet: View {
    @ObservedObject var model: DevicesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var smokerId = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Smoker") {
                    TextField("smoker_1", text: $smokerId).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Text("Only the smoker ID is required. A smoker can be linked to multiple user accounts.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add a smoker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task { if await model.add(smokerId) { dismiss() } }
                    }.disabled(smokerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isWorking)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct RenameDeviceSheet: View {
    @ObservedObject var model: DevicesViewModel
    let device: DeviceItem
    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(model: DevicesViewModel, device: DeviceItem) {
        self.model = model
        self.device = device
        _name = State(initialValue: device.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Text("ID: \(device.id)").font(.caption).foregroundStyle(.secondary)
                TextField("Device name", text: $name)
            }
            .navigationTitle("Edit smoker name")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { if await model.rename(device, to: name) { dismiss() } } }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isWorking)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
