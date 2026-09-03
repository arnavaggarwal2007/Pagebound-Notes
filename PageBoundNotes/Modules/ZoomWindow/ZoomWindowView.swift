import SwiftUI

struct ZoomWindowView: View {
    @ObservedObject var zoomViewModel: ZoomWindowViewModel
    @ObservedObject var pageViewModel: PageViewModel
    @ObservedObject var toolSession: ToolSessionState

    let onClose: () -> Void
    let onAutoAdvanceChanged: (Bool) -> Void

    @State private var stripSize: CGSize = .zero

    private let stripHeight: CGFloat = 160

    var body: some View {
        VStack(spacing: 10) {
            if zoomViewModel.showInlineTip {
                inlineTipBanner
            }

            MiniPagePreviewView(
                pageSize: pageViewModel.pageDimensions,
                viewportRect: zoomViewModel.viewportRect,
                onReposition: { zoomViewModel.repositionViewport(to: $0) }
            )
            .padding(.horizontal, 4)

            zoomStrip
                .frame(height: stripHeight)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear { stripSize = geometry.size }
                            .onChange(of: geometry.size) { _, newSize in
                                stripSize = newSize
                            }
                    }
                )

            zoomControls
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Zoom window"))
    }

    private var inlineTipBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text(String(localized: "Write near the right edge to auto-advance. Turn off auto-advance anytime below."))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Button {
                zoomViewModel.dismissInlineTip()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Dismiss tip"))
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var zoomStrip: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let scale = ZoomViewportMath.contentScale(
                viewportRect: zoomViewModel.viewportRect,
                stripSize: size,
                magnification: zoomViewModel.magnification
            )
            let offset = ZoomViewportMath.contentOffset(
                viewportRect: zoomViewModel.viewportRect,
                scale: scale
            )

            ZStack(alignment: .topLeading) {
                ZoomPageBackdropView(
                    pageViewModel: pageViewModel,
                    pageSize: pageViewModel.pageDimensions
                )

                CanvasView(
                    pageId: pageViewModel.page.id,
                    drawing: pageViewModel.drawing,
                    toolState: pageViewModel.zoomCanvasToolState(),
                    allowsFingerObjectTap: false,
                    onDrawingChanged: { drawing in
                        pageViewModel.drawingDidChange(drawing)
                        zoomViewModel.handleDrawingChanged(drawing)
                    },
                    onPencilSwitchEraser: { toolSession.swapPencilDoubleTap() },
                    onPencilSwitchPrevious: { toolSession.swapPreviousTool() },
                    onFingerObjectTap: nil
                )
                .frame(
                    width: pageViewModel.pageDimensions.width,
                    height: pageViewModel.pageDimensions.height
                )

                if zoomViewModel.autoAdvanceEnabled {
                    advanceZoneOverlay(scale: scale)
                }
            }
            .scaleEffect(scale, anchor: .topLeading)
            .offset(x: offset.width, y: offset.height)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
            }
        }
    }

    private func advanceZoneOverlay(scale: CGFloat) -> some View {
        let zone = ZoomViewportMath.advanceZone(in: zoomViewModel.viewportRect)
        return Rectangle()
            .fill(Color.blue.opacity(zoomViewModel.isAdvanceZoneActive ? 0.28 : 0.14))
            .frame(width: zone.width, height: zone.height)
            .offset(x: zone.origin.x, y: zone.origin.y)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .overlay(alignment: .trailing) {
                if zoomViewModel.isAdvanceZoneActive {
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.trailing, 6)
                        .accessibilityLabel(String(localized: "Auto-advance zone active"))
                }
            }
    }

    private var zoomControls: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Label(String(localized: "Close"), systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .accessibilityLabel(String(localized: "Close zoom window"))

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Zoom"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { zoomViewModel.magnification },
                        set: { zoomViewModel.setMagnification($0) }
                    ),
                    in: ZoomState.magnificationRange
                )
                .accessibilityValue(Text("\(zoomViewModel.magnification, format: .number.precision(.fractionLength(1)))x"))
            }

            Toggle(isOn: Binding(
                get: { zoomViewModel.autoAdvanceEnabled },
                set: { newValue in
                    zoomViewModel.setAutoAdvanceEnabled(newValue)
                    onAutoAdvanceChanged(newValue)
                }
            )) {
                Text(String(localized: "Auto-advance"))
                    .font(.caption)
            }
            .toggleStyle(.switch)
            .labelsHidden()
            .accessibilityLabel(String(localized: "Auto-advance"))
            .accessibilityValue(
                zoomViewModel.autoAdvanceEnabled
                    ? String(localized: "On")
                    : String(localized: "Off")
            )
        }
    }
}
