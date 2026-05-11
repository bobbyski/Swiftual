import XCTest
@testable import Swiftual

final class TCSSCascadeTests: XCTestCase {
    func testMultipleStylesheetSourcesUseDeterministicSourceOrder() {
        let model = TCSSStyleModelBuilder().parse([
            TCSSStylesheetSource(name: "base.tcss", source: """
            Button { background: blue; color: white; }
            """),
            TCSSStylesheetSource(name: "theme.tcss", source: """
            Button { background: green; }
            """),
            TCSSStylesheetSource(name: "target.tcss", source: """
            Button { color: yellow; }
            """)
        ])

        let style = TCSSCascade(model: model).style(for: TCSSStyleContext(typeName: "Button"))

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(style.terminalStyle.background, .green)
        XCTAssertEqual(style.terminalStyle.foreground, .yellow)
        XCTAssertEqual(model.rules.map(\.sourceName), ["base.tcss", "theme.tcss", "target.tcss"])
        XCTAssertEqual(model.rules.map(\.sourceIndex), [0, 1, 2])
    }

    func testStyleResolverOwnsModelDiagnosticsAndCascadeLookup() {
        let resolver = TCSSStyleResolver(sources: [
            TCSSStylesheetSource(name: "base.tcss", source: """
            Button { background: blue; }
            """),
            TCSSStylesheetSource(name: "override.tcss", source: """
            Button.primary { background: green; color: yellow; }
            """)
        ])

        let style = resolver.style(
            for: TCSSStyleContext(typeName: "Button", classNames: ["primary"])
        )

        XCTAssertTrue(resolver.diagnostics.isEmpty)
        XCTAssertEqual(resolver.model.rules.count, 2)
        XCTAssertEqual(style.terminalStyle.background, .green)
        XCTAssertEqual(style.terminalStyle.foreground, .yellow)
    }

    func testButtonApplicatorPatchesButtonStylesAndLayout() {
        var button = Button("Run", frame: Rect(x: 0, y: 0, width: 6, height: 1))
        let style = TCSSStyle(
            terminalStyle: TCSSTerminalStylePatch(background: .green),
            layout: TCSSLayoutStyle(width: 12)
        )
        let focus = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .yellow))
        let disabled = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack))

        TCSSButtonApplicator(focusedStyle: focus, disabledStyle: disabled).apply(style, to: &button)

        XCTAssertEqual(button.style.background, .green)
        XCTAssertEqual(button.focusedStyle.foreground, .yellow)
        XCTAssertEqual(button.disabledStyle.background, .brightBlack)
        XCTAssertEqual(button.frame.width, 12)
    }

    func testLabelApplicatorPatchesAlignmentStyleAndLayout() {
        var label = Label("Name", frame: Rect(x: 0, y: 0, width: 8, height: 1))
        let style = TCSSStyle(
            terminalStyle: TCSSTerminalStylePatch(foreground: .cyan),
            layout: TCSSLayoutStyle(width: 14, textAlign: .right)
        )

        TCSSLabelApplicator().apply(style, to: &label)

        XCTAssertEqual(label.style.foreground, .cyan)
        XCTAssertEqual(label.alignment, .right)
        XCTAssertEqual(label.frame.width, 14)
    }

    func testProgressBarApplicatorPatchesAllProgressStyles() {
        var progress = ProgressBar(frame: Rect(x: 0, y: 0, width: 10, height: 1))
        let base = TCSSStyle(
            terminalStyle: TCSSTerminalStylePatch(background: .brightBlack),
            layout: TCSSLayoutStyle(width: 20)
        )
        let complete = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .green))
        let pulse = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .cyan))
        let text = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .yellow))

        TCSSProgressBarApplicator(completeStyle: complete, pulseStyle: pulse, textStyle: text).apply(base, to: &progress)

        XCTAssertEqual(progress.trackStyle.background, .brightBlack)
        XCTAssertEqual(progress.completedStyle.background, .green)
        XCTAssertEqual(progress.pulseStyle.background, .cyan)
        XCTAssertEqual(progress.textStyle.foreground, .yellow)
        XCTAssertEqual(progress.frame.width, 20)
    }

    func testTextInputApplicatorPatchesInputStylesAndLayout() {
        var input = TextInput(text: "Swift", placeholder: "Name", frame: Rect(x: 0, y: 0, width: 8, height: 1))
        let base = TCSSStyle(
            terminalStyle: TCSSTerminalStylePatch(background: .black),
            layout: TCSSLayoutStyle(width: 18)
        )
        let focus = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .blue))
        let placeholder = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .brightBlack))
        let cursor = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightWhite, bold: true))

        TCSSTextInputApplicator(focusedStyle: focus, placeholderStyle: placeholder, cursorStyle: cursor).apply(base, to: &input)

        XCTAssertEqual(input.style.background, .black)
        XCTAssertEqual(input.focusedStyle.background, .blue)
        XCTAssertEqual(input.placeholderStyle.foreground, .brightBlack)
        XCTAssertEqual(input.cursorStyle.background, .brightWhite)
        XCTAssertEqual(input.cursorStyle.bold, true)
        XCTAssertEqual(input.frame.width, 18)
    }

    func testCheckboxApplicatorComposesFocusedCheckedStyle() {
        var checkbox = Checkbox("Enabled", frame: Rect(x: 0, y: 0, width: 10, height: 1))
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(width: 16))
        let focus = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .yellow))
        let checked = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .green))
        let disabled = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack))

        TCSSCheckboxApplicator(focusedStyle: focus, checkedStyle: checked, disabledStyle: disabled).apply(base, to: &checkbox)

        XCTAssertEqual(checkbox.style.background, .black)
        XCTAssertEqual(checkbox.checkedStyle.background, .green)
        XCTAssertEqual(checkbox.focusedStyle.foreground, .yellow)
        XCTAssertEqual(checkbox.focusedCheckedStyle.background, .green)
        XCTAssertEqual(checkbox.focusedCheckedStyle.foreground, .yellow)
        XCTAssertEqual(checkbox.disabledStyle.background, .brightBlack)
        XCTAssertEqual(checkbox.frame.width, 16)
    }

    func testSwitchApplicatorPreservesOnStyleForFocusedOnState() {
        var power = Switch("Power", frame: Rect(x: 0, y: 0, width: 10, height: 1))
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(width: 14))
        let on = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .black, background: .green))
        let focus = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .blue))
        let disabled = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack))

        TCSSSwitchApplicator(onStyle: on, focusedStyle: focus, disabledStyle: disabled).apply(base, to: &power)

        XCTAssertEqual(power.offStyle.background, .black)
        XCTAssertEqual(power.onStyle.background, .green)
        XCTAssertEqual(power.focusedOffStyle.background, .blue)
        XCTAssertEqual(power.focusedOnStyle.background, .green)
        XCTAssertEqual(power.focusedOnStyle.foreground, .black)
        XCTAssertEqual(power.disabledStyle.background, .brightBlack)
        XCTAssertEqual(power.frame.width, 14)
    }

    func testSelectApplicatorPatchesChoiceStylesAndLayout() {
        var select = Select(frame: Rect(x: 0, y: 0, width: 10, height: 1), options: [SelectOption("One")])
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(width: 12))
        let focus = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .blue))
        let open = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightWhite))
        let option = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .cyan))
        let selected = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .yellow))
        let disabled = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack))

        TCSSSelectApplicator(
            focusedStyle: focus,
            openStyle: open,
            optionStyle: option,
            selectedOptionStyle: selected,
            disabledStyle: disabled
        ).apply(base, to: &select)

        XCTAssertEqual(select.style.background, .black)
        XCTAssertEqual(select.focusedStyle.background, .blue)
        XCTAssertEqual(select.openStyle.background, .brightWhite)
        XCTAssertEqual(select.optionStyle.foreground, .cyan)
        XCTAssertEqual(select.highlightedStyle.foreground, .yellow)
        XCTAssertEqual(select.disabledStyle.background, .brightBlack)
        XCTAssertEqual(select.frame.width, 12)
    }

    func testScrollViewApplicatorPatchesContentScrollbarAndLayout() {
        var scroll = ScrollView(frame: Rect(x: 0, y: 0, width: 20, height: 4), content: ["a", "b", "c", "d", "e"])
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(width: 30))
        let content = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .cyan))
        let scrollbar = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack), layout: TCSSLayoutStyle(width: 3))
        let thumb = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .blue))

        TCSSScrollViewApplicator(contentStyle: content, scrollbarStyle: scrollbar, thumbStyle: thumb).apply(base, to: &scroll)

        XCTAssertEqual(scroll.fillStyle.background, .black)
        XCTAssertEqual(scroll.contentStyle.foreground, .cyan)
        XCTAssertEqual(scroll.scrollbarStyle.background, .brightBlack)
        XCTAssertEqual(scroll.thumbStyle.background, .blue)
        XCTAssertEqual(scroll.scrollbarWidth, 3)
        XCTAssertEqual(scroll.frame.width, 30)
    }

    func testRichLogApplicatorPatchesTitleAndLayout() {
        var log = RichLog(frame: Rect(x: 0, y: 0, width: 20, height: 4))
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(height: 8))
        let title = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .yellow, background: .blue))

        TCSSRichLogApplicator(titleStyle: title).apply(base, to: &log)

        XCTAssertEqual(log.fillStyle.background, .black)
        XCTAssertEqual(log.titleStyle.foreground, .yellow)
        XCTAssertEqual(log.titleStyle.background, .blue)
        XCTAssertEqual(log.frame.height, 8)
    }

    func testDataTableApplicatorPatchesRowStylesAndLayout() {
        var table = DataTable(
            frame: Rect(x: 0, y: 0, width: 20, height: 5),
            columns: [DataTableColumn("Name", width: 8)],
            rows: [["Swift"]]
        )
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(width: 28))
        let header = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .cyan))
        let row = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .white))
        let alternate = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack))
        let selected = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .blue))
        let focusedSelected = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(bold: true))

        TCSSDataTableApplicator(
            headerStyle: header,
            rowStyle: row,
            alternateRowStyle: alternate,
            selectedRowStyle: selected,
            focusedSelectedRowStyle: focusedSelected
        ).apply(base, to: &table)

        XCTAssertEqual(table.rowStyle.background, .black)
        XCTAssertEqual(table.rowStyle.foreground, .white)
        XCTAssertEqual(table.headerStyle.background, .cyan)
        XCTAssertEqual(table.alternateRowStyle.background, .brightBlack)
        XCTAssertEqual(table.selectedRowStyle.background, .blue)
        XCTAssertEqual(table.focusedSelectedRowStyle.bold, true)
        XCTAssertEqual(table.frame.width, 28)
    }

    func testTreeApplicatorPatchesSelectionScrollbarAndLayout() {
        var tree = Tree(frame: Rect(x: 0, y: 0, width: 20, height: 4), roots: [TreeNode("Root")])
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(width: 24))
        let selected = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .blue))
        let focusedSelected = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(bold: true))
        let branch = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .cyan))
        let scrollbar = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack), layout: TCSSLayoutStyle(width: 4))
        let thumb = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .green))

        TCSSTreeApplicator(
            selectedStyle: selected,
            focusedSelectedStyle: focusedSelected,
            branchStyle: branch,
            scrollbarStyle: scrollbar,
            thumbStyle: thumb
        ).apply(base, to: &tree)

        XCTAssertEqual(tree.fillStyle.background, .black)
        XCTAssertEqual(tree.rowStyle.background, .black)
        XCTAssertEqual(tree.selectedStyle.background, .blue)
        XCTAssertEqual(tree.focusedSelectedStyle.bold, true)
        XCTAssertEqual(tree.branchStyle.foreground, .cyan)
        XCTAssertEqual(tree.scrollbarStyle.background, .brightBlack)
        XCTAssertEqual(tree.thumbStyle.background, .green)
        XCTAssertEqual(tree.scrollbarWidth, 4)
        XCTAssertEqual(tree.frame.width, 24)
    }

    func testModalApplicatorPatchesOverlayButtonsAndLayout() {
        var modal = Modal(
            frame: Rect(x: 0, y: 0, width: 20, height: 6),
            title: "Confirm",
            message: "Continue?",
            buttons: [ModalButton("OK"), ModalButton("Cancel")]
        )
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(width: 32))
        let overlay = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack))
        let title = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .yellow, background: .blue))
        let button = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .cyan))
        let focusedButton = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .green, bold: true))
        let disabledButton = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack))

        TCSSModalApplicator(
            overlayStyle: overlay,
            titleStyle: title,
            buttonStyle: button,
            focusedButtonStyle: focusedButton,
            disabledButtonStyle: disabledButton
        ).apply(base, to: &modal)

        XCTAssertEqual(modal.panelStyle.background, .black)
        XCTAssertEqual(modal.overlayStyle.background, .brightBlack)
        XCTAssertEqual(modal.titleStyle.foreground, .yellow)
        XCTAssertEqual(modal.titleStyle.background, .blue)
        XCTAssertEqual(modal.buttonStyle.foreground, .cyan)
        XCTAssertEqual(modal.focusedButtonStyle.background, .green)
        XCTAssertEqual(modal.focusedButtonStyle.bold, true)
        XCTAssertEqual(modal.disabledButtonStyle.background, .brightBlack)
        XCTAssertEqual(modal.frame.width, 32)
    }

    func testCommandPaletteApplicatorPatchesItemsAndLayout() {
        var palette = CommandPalette(
            frame: Rect(x: 0, y: 0, width: 24, height: 8),
            items: [CommandPaletteItem("Open"), CommandPaletteItem("Disabled", isEnabled: false)]
        )
        let base = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .black), layout: TCSSLayoutStyle(height: 12))
        let title = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .yellow, background: .blue))
        let input = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .brightBlack))
        let item = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .cyan))
        let highlighted = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(background: .green, bold: true))
        let disabled = TCSSStyle(terminalStyle: TCSSTerminalStylePatch(foreground: .white, background: .brightBlack))

        TCSSCommandPaletteApplicator(
            titleStyle: title,
            inputStyle: input,
            itemStyle: item,
            highlightedStyle: highlighted,
            disabledStyle: disabled
        ).apply(base, to: &palette)

        XCTAssertEqual(palette.panelStyle.background, .black)
        XCTAssertEqual(palette.titleStyle.foreground, .yellow)
        XCTAssertEqual(palette.titleStyle.background, .blue)
        XCTAssertEqual(palette.inputStyle.background, .brightBlack)
        XCTAssertEqual(palette.itemStyle.foreground, .cyan)
        XCTAssertEqual(palette.highlightedStyle.background, .green)
        XCTAssertEqual(palette.highlightedStyle.bold, true)
        XCTAssertEqual(palette.disabledStyle.foreground, .white)
        XCTAssertEqual(palette.disabledStyle.background, .brightBlack)
        XCTAssertEqual(palette.frame.height, 12)
    }

    func testFlowContainerApplicatorPatchesFillSpacingPaddingAndLayout() {
        var container = FlowContainer(
            frame: Rect(x: 0, y: 0, width: 20, height: 8),
            axis: .vertical,
            spacing: FlowSpacing(main: 1),
            padding: BoxEdges(0),
            children: []
        )
        let style = TCSSStyle(
            terminalStyle: TCSSTerminalStylePatch(background: .black),
            layout: TCSSLayoutStyle(width: 32, padding: TCSSBoxEdges(top: 1, right: 2, bottom: 3, left: 4), spacing: 5)
        )

        TCSSFlowContainerApplicator().apply(style, to: &container)

        XCTAssertEqual(container.fillStyle?.background, .black)
        XCTAssertEqual(container.spacing, FlowSpacing(main: 5))
        XCTAssertEqual(container.padding, BoxEdges(top: 1, right: 2, bottom: 3, left: 4))
        XCTAssertEqual(container.frame.width, 32)
    }

    func testVerticalAndHorizontalApplicatorsPatchFillSpacingAndLayout() {
        var vertical = Vertical(frame: Rect(x: 0, y: 0, width: 10, height: 4), spacing: 1, children: [])
        var horizontal = Horizontal(frame: Rect(x: 0, y: 0, width: 10, height: 4), spacing: 1, children: [])
        let style = TCSSStyle(
            terminalStyle: TCSSTerminalStylePatch(foreground: .cyan, background: .black),
            layout: TCSSLayoutStyle(height: 9, spacing: 3)
        )

        TCSSVerticalApplicator().apply(style, to: &vertical)
        TCSSHorizontalApplicator().apply(style, to: &horizontal)

        XCTAssertEqual(vertical.fillStyle?.foreground, .cyan)
        XCTAssertEqual(vertical.fillStyle?.background, .black)
        XCTAssertEqual(vertical.spacing, 3)
        XCTAssertEqual(vertical.frame.height, 9)
        XCTAssertEqual(horizontal.fillStyle?.foreground, .cyan)
        XCTAssertEqual(horizontal.fillStyle?.background, .black)
        XCTAssertEqual(horizontal.spacing, 3)
        XCTAssertEqual(horizontal.frame.height, 9)
    }

    func testHigherSpecificityStillWinsAcrossMultipleSources() {
        let model = TCSSStyleModelBuilder().parse([
            TCSSStylesheetSource(name: "base.tcss", source: """
            Button.primary { background: blue; }
            """),
            TCSSStylesheetSource(name: "theme.tcss", source: """
            Button { background: green; }
            """)
        ])

        let style = TCSSCascade(model: model).style(
            for: TCSSStyleContext(typeName: "Button", classNames: ["primary"])
        )

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(style.terminalStyle.background, .blue)
    }

    func testMultiClassSelectorRequiresAllClasses() {
        let model = TCSSStyleModelBuilder().parse("""
        Button.primary.danger { background: red; color: bright-white; }
        Button.primary { background: blue; }
        """)
        let cascade = TCSSCascade(model: model)

        let primary = cascade.style(for: TCSSStyleContext(typeName: "Button", classNames: ["primary"]))
        let danger = cascade.style(for: TCSSStyleContext(typeName: "Button", classNames: ["primary", "danger"]))

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(primary.terminalStyle.background, .blue)
        XCTAssertNil(primary.terminalStyle.foreground)
        XCTAssertEqual(danger.terminalStyle.background, .red)
        XCTAssertEqual(danger.terminalStyle.foreground, .brightWhite)
    }

    func testTypeClassAndPseudoSpecificityCombine() {
        let model = TCSSStyleModelBuilder().parse("""
        Button.primary { background: blue; }
        Button.primary:focus { background: green; text-style: bold; }
        Button:focus { background: yellow; }
        """)

        let style = TCSSCascade(model: model).style(
            for: TCSSStyleContext(typeName: "Button", classNames: ["primary"], pseudoStates: ["focus"])
        )

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(style.terminalStyle.background, .green)
        XCTAssertEqual(style.terminalStyle.bold, true)
    }
}
