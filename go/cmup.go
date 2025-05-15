package main

import (
	"fmt"
	"os"
	"path"
	"path/filepath"
	"strings"
)

type Playlist struct {
	name         string
	content      []string
	subPlaylists []Playlist
}

func (playlist Playlist) Print() {
	fmt.Printf("Playlist: %s (Files: %d, Sub-playlists: %d)\n",
		playlist.name, len(playlist.content), len(playlist.subPlaylists))

	for _, file := range playlist.content {
		fmt.Printf("  - File: %s\n", filepath.Base(file))
	}

	for _, sub := range playlist.subPlaylists {
		fmt.Printf("  - Sub-playlist: %s\n", sub.name)
	}
}

func endsWithDollar(str string) bool {
	return strings.HasSuffix(str, "$")
}

func readSubPlaylist(parent string, result *[]Playlist, entry os.DirEntry, entryPath string) {
	name := entry.Name()

	subPlaylist, err := readPlaylist(entry, entryPath)

	if err != nil {
		fmt.Printf("Warning: %v\n", err)
	}

	if endsWithDollar(name) {
		subPlaylist.name = parent + "-" + subPlaylist.name
	}

	*result = append(*result, subPlaylist)
}

func readPlaylist(dir os.DirEntry, dirPath string) (Playlist, error) {
	dirName := dir.Name()

	if !dir.IsDir() {
		return Playlist{}, fmt.Errorf("cannot read playlist from '%s': not a directory", dirName)
	}

	content, err := os.ReadDir(dirPath)

	if err != nil {
		return Playlist{}, fmt.Errorf("failed to read directory '%s': %w", dirPath, err)
	}

	result := make([]string, 0)
	nested := make([]Playlist, 0)

	for _, entry := range content {
		entryPath := path.Join(dirPath, entry.Name())

		if !entry.IsDir() {
			result = append(result, entryPath)
			continue
		}

		readSubPlaylist(dirName, &nested, entry, entryPath)
	}

	return Playlist{dir.Name(), result, nested}, nil
}

func writePlaylist(playlist Playlist, output string) {
	file, err := os.OpenFile(path.Join(output, playlist.name), os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	defer file.Close()

	if err == nil {
		for _, value := range playlist.content {
			_, writeErr := file.WriteString(value + "\n")

			if writeErr != nil {
				fmt.Printf("Warning: %v\n", writeErr)
			}
		}

		for _, value := range playlist.subPlaylists {
			writePlaylist(value, output)
		}
	} else {
		fmt.Printf("Warning: %v\n", err)
	}
}

func cmup(homePath string) ([]Playlist, error) {
	musicDir := path.Join(homePath, "Music")
	dir, err := os.ReadDir(musicDir)

	output := path.Join(homePath, ".config", "cmus", "playlists")

	if err != nil {
		return nil, fmt.Errorf("failed to read Music directory: %w", err)
	}

	result := make([]Playlist, 0)

	for _, entry := range dir {
		if !entry.IsDir() {
			continue
		}

		playlistPath := path.Join(musicDir, entry.Name())
		playlist, err := readPlaylist(entry, playlistPath)

		if err != nil {
			fmt.Printf("Warning: %v\n", err)
			continue
		}

		writePlaylist(playlist, output)

		result = append(result, playlist)
	}

	return result, nil
}

func main() {
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Error getting user home directory: %v\n", err)
		os.Exit(1)
	}

	playlists, err := cmup(home)

	if err != nil {
		fmt.Printf("Error reading music playlists: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Found %d playlists\n", len(playlists))

	for _, playlist := range playlists {
		playlist.Print()
	}
}
