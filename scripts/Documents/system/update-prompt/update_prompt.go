package main

import (
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

type model struct {
	quitting        bool
	message         string
	spinner         spinner.Model
	currentStep     step
	runUpdate       bool
	runDotfiles     bool
	dotfilesAvail   bool
	dotfilesChanges string
	width           int
}

var (
	purple    = lipgloss.Color("#7D56F4")
	cyan      = lipgloss.Color("#00FFCC")
	red       = lipgloss.Color("#FF5555")
	green     = lipgloss.Color("#00FF88")
	dim       = lipgloss.Color("#666666")
	white     = lipgloss.Color("#FFFFFF")
	darkBg    = lipgloss.Color("#1A1A2E")
	cardBg    = lipgloss.Color("#16213E")
	accent    = lipgloss.Color("#0F3460")

	logoStyle = lipgloss.NewStyle().
			Foreground(purple).
			Bold(true)

	titleStyle = lipgloss.NewStyle().
			Foreground(white).
			Background(purple).
			Padding(0, 2).
			Bold(true)

	cardStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(purple).
			Padding(1, 3)

	questionStyle = lipgloss.NewStyle().
			Foreground(cyan).
			Bold(true)

	keyStyle = lipgloss.NewStyle().
			Foreground(purple).
			Background(accent).
			Padding(0, 1).
			Bold(true)

	messageStyle = lipgloss.NewStyle().
			Foreground(red)

	successStyle = lipgloss.NewStyle().
			Foreground(green).
			Bold(true)

	dimStyle = lipgloss.NewStyle().
			Foreground(dim)

	changeStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#E2B714")).
			PaddingLeft(2)

	statusDot = lipgloss.NewStyle().
			Foreground(green).
			Bold(true)

	statusDotOff = lipgloss.NewStyle().
			Foreground(dim)
)

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
	sp.Style = lipgloss.NewStyle().Foreground(purple)

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
	sys := statusDotOff.Render("○")
	dot := statusDotOff.Render("○")

	if current == stepSystemUpdate {
		sys = statusDot.Render("●")
	} else if current == stepDotfilesUpdate {
		sys = dimStyle.Render("✓")
		dot = statusDot.Render("●")
	}

	steps := sys + dimStyle.Render(" System")
	if dotfilesAvail {
		steps += dimStyle.Render("  →  ") + dot + dimStyle.Render(" Dotfiles")
	}
	return steps
}

func (m model) View() string {
	if m.quitting {
		var lines []string
		if m.runUpdate {
			lines = append(lines, successStyle.Render("  System update"))
		}
		if m.runDotfiles {
			lines = append(lines, successStyle.Render("  Dotfiles update"))
		}
		if len(lines) == 0 {
			return "\n" + dimStyle.Render("  No updates selected.") + "\n"
		}
		return "\n" + strings.Join(lines, "\n") + "\n"
	}

	logo := logoStyle.Render(
		"  ╭─────────────────────╮\n" +
		"  │  System  Manager    │\n" +
		"  ╰─────────────────────╯")

	steps := renderSteps(m.currentStep, m.dotfilesAvail)

	var content string

	switch m.currentStep {
	case stepSystemUpdate:
		content = questionStyle.Render("Update system packages?") + "\n\n" +
			dimStyle.Render("  Runs ") + lipgloss.NewStyle().Foreground(white).Render("yay -Syu") +
			dimStyle.Render(" to update all packages") + "\n\n" +
			keyStyle.Render("Y") + dimStyle.Render(" yes  ") +
			keyStyle.Render("N") + dimStyle.Render(" no  ") +
			keyStyle.Render("Q") + dimStyle.Render(" quit")

	case stepDotfilesUpdate:
		changeLines := strings.Split(m.dotfilesChanges, "\n")
		var formatted []string
		for _, line := range changeLines {
			formatted = append(formatted, changeStyle.Render("  "+line))
		}

		content = questionStyle.Render("Dotfiles updates available") + "\n\n" +
			dimStyle.Render("  New commits:") + "\n" +
			strings.Join(formatted, "\n") + "\n\n" +
			keyStyle.Render("Y") + dimStyle.Render(" apply  ") +
			keyStyle.Render("N") + dimStyle.Render(" skip  ") +
			keyStyle.Render("Q") + dimStyle.Render(" quit")
	}

	card := cardStyle.Render(content)
	spinner := m.spinner.View()

	return fmt.Sprintf("\n%s\n\n  %s  %s\n\n%s\n", logo, steps, spinner, card)
}

func main() {
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
	fmt.Println(successStyle.Render("  Starting system update..."))
	fmt.Println()

	cmd := exec.Command("yay", "-Syu")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Printf("\n%s\n", messageStyle.Render("  Error updating system: "+err.Error()))
	} else {
		fmt.Printf("\n%s\n", successStyle.Render("  System update completed!"))
	}
}

func runDotfilesUpdate() {
	fmt.Println()
	fmt.Println(successStyle.Render("  Updating dotfiles..."))
	fmt.Println()

	dotfiles := os.Getenv("HOME") + "/dotfiles"
	cmd := exec.Command(dotfiles + "/update.sh")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Printf("\n%s\n", messageStyle.Render("  Error updating dotfiles: "+err.Error()))
	} else {
		fmt.Printf("\n%s\n", successStyle.Render("  Dotfiles update completed!"))
	}
}
