pragma Singleton
import QtQuick

QtObject {
    readonly property string fontFamily: "Fira Sans"
    property color primary: "{{colors.primary.default.hex}}"
    property color on_primary: "{{colors.on_primary.default.hex}}"
    property color primaryContainer: "{{colors.primary_container.default.hex}}"
    property color on_primaryContainer: "{{colors.on_primary_container.default.hex}}"
    property color secondary: "{{colors.secondary.default.hex}}"
    property color on_secondary: "{{colors.on_secondary.default.hex}}"
    property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
    property color on_secondaryContainer: "{{colors.on_secondary_container.default.hex}}"
    property color background: "{{colors.background.default.hex}}"
    property color on_background: "{{colors.on_background.default.hex}}"
    property color surface: "{{colors.surface.default.hex}}"
    property color on_surface: "{{colors.on_surface.default.hex}}"
    property color surfaceVariant: "{{colors.surface_variant.default.hex}}"
    property color on_surfaceVariant: "{{colors.on_surface_variant.default.hex}}"
    property color outline: "{{colors.outline.default.hex}}"
    property color outlineVariant: "{{colors.outline_variant.default.hex}}"
    property color shadow: "#000000"
    property color error: "{{colors.error.default.hex}}"
    property color on_error: "{{colors.on_error.default.hex}}"
}
