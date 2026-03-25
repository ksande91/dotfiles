package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type step int

const (
	stepSystemUpdate step = iota
	stepDotfilesUpdate
	stepDone
)

// Pywal colors loaded at startup
var walColors [16]string

func loadWalColors() {
	home := os.Getenv("HOME")
	f, err := os.Open(home + "/.cache/wal/colors")
	if err != nil {
		// Fallback colors if pywal not available
		walColors = [16]string{
			"#1a1a2e", "#bf616a", "#a3be8c", "#ebcb8b",
			"#5e81ac", "#b48ead", "#88c0d0", "#eceff4",
			"#4c566a", "#bf616a", "#a3be8c", "#ebcb8b",
			"#5e81ac", "#b48ead", "#88c0d0", "#eceff4",
		}
		return
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	i := 0
	for scanner.Scan() && i < 16 {
		walColors[i] = strings.TrimSpace(scanner.Text())
		i++
	}
}

// Color aliases from pywal
func bg() lipgloss.Color      { return lipgloss.Color(walColors[0]) }
func red() lipgloss.Color     { return lipgloss.Color(walColors[1]) }
func green() lipgloss.Color   { return lipgloss.Color(walColors[2]) }
func yellow() lipgloss.Color  { return lipgloss.Color(walColors[3]) }
func blue() lipgloss.Color    { return lipgloss.Color(walColors[4]) }
func magenta() lipgloss.Color { return lipgloss.Color(walColors[5]) }
func cyan() lipgloss.Color    { return lipgloss.Color(walColors[6]) }
func fg() lipgloss.Color      { return lipgloss.Color(walColors[7]) }
func grey() lipgloss.Color    { return lipgloss.Color(walColors[8]) }

type model struct {
	quitting        bool
	spinner         spinner.Model
	currentStep     step
	runUpdate       bool
	runDotfiles     bool
	dotfilesAvail   bool
	dotfilesChanges string
	width           int
}

func checkDotfilesUpdates() (bool, string) {
	dotfiles := os.Getenv("HOME") + "/dotfiles"

	fetch := exec.Command("git", "-C", dotfiles, "fetch", "origin", "main")
	fetch.Stderr = nil
	fetch.Stdout = nil
	if err := fetch.Run(); err != nil {
		return false, ""
	}

	local, err := exec.Command("git", "-C", dotfiles, "rev-parse", "HEAD").Output()
	if err != nil {
		return false, ""
	}
	remote, err := exec.Command("git", "-C", dotfiles, "rev-parse", "origin/main").Output()
	if err != nil {
		return false, ""
	}

	if strings.TrimSpace(string(local)) == strings.TrimSpace(string(remote)) {
		return false, ""
	}

	changes, _ := exec.Command("git", "-C", dotfiles, "log", "--oneline", "HEAD..origin/main").Output()
	return true, strings.TrimSpace(string(changes))
}

func initialModel() model {
	sp := spinner.New()
	sp.Spinner = spinner.Dot
	sp.Style = lipgloss.NewStyle().Foreground(magenta())

	avail, changes := checkDotfilesUpdates()

	return model{
		spinner:         sp,
		currentStep:     stepSystemUpdate,
		dotfilesAvail:   avail,
		dotfilesChanges: changes,
	}
}

func (m model) Init() tea.Cmd {
	return m.spinner.Tick
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "y", "Y":
			if m.currentStep == stepSystemUpdate {
				m.runUpdate = true
				if m.dotfilesAvail {
					m.currentStep = stepDotfilesUpdate
				} else {
					m.quitting = true
					return m, tea.Quit
				}
			} else if m.currentStep == stepDotfilesUpdate {
				m.runDotfiles = true
				m.quitting = true
				return m, tea.Quit
			}

		case "n", "N":
			if m.currentStep == stepSystemUpdate {
				if m.dotfilesAvail {
					m.currentStep = stepDotfilesUpdate
				} else {
					m.quitting = true
					return m, tea.Quit
				}
			} else if m.currentStep == stepDotfilesUpdate {
				m.quitting = true
				return m, tea.Quit
			}

		case "ctrl+c", "q":
			m.quitting = true
			return m, tea.Quit
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width

	default:
		m.spinner, cmd = m.spinner.Update(msg)
	}

	return m, cmd
}

func renderSteps(current step, dotfilesAvail bool) string {
	sys := lipgloss.NewStyle().Foreground(grey()).Render("○ System")
	dot := lipgloss.NewStyle().Foreground(grey()).Render("○ Dotfiles")

	if current == stepSystemUpdate {
		sys = lipgloss.NewStyle().Foreground(cyan()).Bold(true).Render("● System")
	} else if current == stepDotfilesUpdate {
		sys = lipgloss.NewStyle().Foreground(green()).Render("✓ System")
		dot = lipgloss.NewStyle().Foreground(cyan()).Bold(true).Render("● Dotfiles")
	}

	steps := "  " + sys
	if dotfilesAvail {
		steps += lipgloss.NewStyle().Foreground(grey()).Render("  ─  ") + dot
	}
	return steps
}

func (m model) View() string {
	if m.quitting {
		var lines []string
		if m.runUpdate {
			lines = append(lines, lipgloss.NewStyle().Foreground(green()).Bold(true).Render("  ✓ System update"))
		}
		if m.runDotfiles {
			lines = append(lines, lipgloss.NewStyle().Foreground(green()).Bold(true).Render("  ✓ Dotfiles update"))
		}
		if len(lines) == 0 {
			return "\n" + lipgloss.NewStyle().Foreground(grey()).Render("  No updates selected.") + "\n"
		}
		return "\n" + strings.Join(lines, "\n") + "\n"
	}

	logo := lipgloss.NewStyle().Foreground(magenta()).Bold(true).Render(
		"  ┌─────────────────────┐\n" +
			"  │  System  Manager    │\n" +
			"  └─────────────────────┘")

	steps := renderSteps(m.currentStep, m.dotfilesAvail)
	spin := m.spinner.View()

	cardBorder := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(blue()).
		Padding(1, 3)

	keys := lipgloss.NewStyle().Foreground(magenta()).Bold(true).Render("Y") +
		lipgloss.NewStyle().Foreground(fg()).Render(" yes  ") +
		lipgloss.NewStyle().Foreground(magenta()).Bold(true).Render("N") +
		lipgloss.NewStyle().Foreground(fg()).Render(" no  ") +
		lipgloss.NewStyle().Foreground(magenta()).Bold(true).Render("Q") +
		lipgloss.NewStyle().Foreground(fg()).Render(" quit")

	var content string

	switch m.currentStep {
	case stepSystemUpdate:
		content = lipgloss.NewStyle().Foreground(fg()).Bold(true).Render("Update system packages?") + "\n\n" +
			lipgloss.NewStyle().Foreground(cyan()).Render("  Runs yay -Syu to update all packages") + "\n\n" +
			keys

	case stepDotfilesUpdate:
		changeLines := strings.Split(m.dotfilesChanges, "\n")
		var formatted []string
		for _, line := range changeLines {
			formatted = append(formatted, lipgloss.NewStyle().Foreground(yellow()).PaddingLeft(2).Render("› "+line))
		}

		content = lipgloss.NewStyle().Foreground(fg()).Bold(true).Render("Apply dotfiles updates?") + "\n\n" +
			lipgloss.NewStyle().Foreground(cyan()).Render("  New commits:") + "\n" +
			strings.Join(formatted, "\n") + "\n\n" +
			keys
	}

	card := cardBorder.Render(content)

	return fmt.Sprintf("\n%s\n\n%s  %s\n\n%s\n", logo, steps, spin, card)
}

func main() {
	loadWalColors()

	m := initialModel()
	p := tea.NewProgram(m)

	finalModel, err := p.Run()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	fm := finalModel.(model)

	if fm.runUpdate {
		runSystemUpdate()
	}

	if fm.runDotfiles {
		runDotfilesUpdate()
	}

	if !fm.runUpdate && !fm.runDotfiles {
		fmt.Println("No updates were performed.")
	}

	fmt.Println("\nPress Enter to exit...")
	fmt.Scanln()
	os.Exit(0)
}

func runSystemUpdate() {
	fmt.Println()
	fmt.Println(lipgloss.NewStyle().Foreground(green()).Bold(true).Render("  Starting system update..."))
	fmt.Println()

	cmd := exec.Command("yay", "-Syu")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Printf("\n%s\n", lipgloss.NewStyle().Foreground(red()).Render("  Error: "+err.Error()))
	} else {
		fmt.Printf("\n%s\n", lipgloss.NewStyle().Foreground(green()).Bold(true).Render("  System update completed!"))
	}
}

func runDotfilesUpdate() {
	fmt.Println()
	fmt.Println(lipgloss.NewStyle().Foreground(green()).Bold(true).Render("  Updating dotfiles..."))
	fmt.Println()

	dotfiles := os.Getenv("HOME") + "/dotfiles"
	cmd := exec.Command(dotfiles + "/update.sh")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Printf("\n%s\n", lipgloss.NewStyle().Foreground(red()).Render("  Error: "+err.Error()))
	} else {
		fmt.Printf("\n%s\n", lipgloss.NewStyle().Foreground(green()).Bold(true).Render("  Dotfiles update completed!"))
	}
}
