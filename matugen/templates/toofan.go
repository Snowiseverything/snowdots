package theme

import "github.com/charmbracelet/lipgloss"

var Matugen = Palette{
	Name:       "matugen",
	Background: lipgloss.Color("{{colors.surface.default.hex}}"),
	Foreground: lipgloss.Color("{{colors.on_surface_variant.default.hex}}"),
	Typed:      lipgloss.Color("{{colors.on_surface.default.hex}}"),
	Error:      lipgloss.Color("{{colors.error.default.hex}}"),
	Cursor:     lipgloss.Color("{{colors.primary.default.hex}}"),
	Accent:     lipgloss.Color("{{colors.primary.default.hex}}"),
	Success:    lipgloss.Color("{{colors.tertiary.default.hex}}"),
}
